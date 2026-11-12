#include <napi/native_api.h>
#include <multimedia/native_audio_channel_layout.h>
#include <multimedia/player_framework/native_avbuffer.h>
#include <multimedia/player_framework/native_avcapability.h>
#include <multimedia/player_framework/native_avcodec_audiocodec.h>
#include <multimedia/player_framework/native_avcodec_base.h>
#include <multimedia/player_framework/native_averrors.h>
#include <multimedia/player_framework/native_avformat.h>

#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

namespace {

constexpr int32_t kSampleRate = 16000;
constexpr int32_t kChannelCount = 1;
constexpr int64_t kFrameDurationUs = 20000;
constexpr int32_t kInputWaitMs = 10;
constexpr int32_t kEncodeOutputWaitMs = 10;
constexpr int32_t kDecodeOutputWaitMs = 30;
constexpr int32_t kMaxInputSize = 4000;

using Bytes = std::vector<uint8_t>;

struct CodecBuffer {
    uint32_t index;
    OH_AVBuffer *buffer;
};

enum class JobType { Encode, Decode, Reset };

struct Job {
    JobType type = JobType::Encode;
    std::vector<Bytes> payloads;
    bool finished = false;
    double tag = 0;
};

struct Delivery {
    bool isEncoder = false;
    std::vector<Bytes> packets;
    std::vector<int16_t> pcm;
    bool finished = false;
    double tag = 0;
};

std::vector<int16_t> ResampleTo16k(const std::vector<int16_t> &pcm, int32_t srcRate)
{
    if (srcRate == kSampleRate || srcRate <= 0 || pcm.empty()) {
        return pcm;
    }
    if (srcRate % kSampleRate == 0) {
        size_t step = static_cast<size_t>(srcRate / kSampleRate);
        size_t outLen = pcm.size() / step;
        if (outLen == 0) {
            return pcm;
        }
        std::vector<int16_t> out(outLen);
        size_t source = 0;
        for (size_t i = 0; i < outLen; ++i) {
            int32_t acc = 0;
            for (size_t k = 0; k < step; ++k) {
                acc += pcm[source++];
            }
            out[i] = static_cast<int16_t>(acc / static_cast<int32_t>(step));
        }
        return out;
    }
    size_t outLen = static_cast<size_t>(static_cast<int64_t>(pcm.size()) * kSampleRate / srcRate);
    if (outLen == 0) {
        return pcm;
    }
    std::vector<int16_t> out(outLen);
    double ratio = static_cast<double>(srcRate) / kSampleRate;
    size_t last = pcm.size() - 1;
    for (size_t i = 0; i < outLen; ++i) {
        double src = static_cast<double>(i) * ratio;
        size_t index = std::min(static_cast<size_t>(src), last);
        size_t next = std::min(index + 1, last);
        double frac = src - static_cast<double>(index);
        out[i] = static_cast<int16_t>((1 - frac) * pcm[index] + frac * pcm[next]);
    }
    return out;
}

class OpusSession {
public:
    explicit OpusSession(bool isEncoder) : isEncoder_(isEncoder) {}

    ~OpusSession()
    {
        Shutdown();
    }

    bool Open(int64_t bitRate, napi_threadsafe_function tsfn)
    {
        tsfn_ = tsfn;
        codec_ = OH_AudioCodec_CreateByMime(OH_AVCODEC_MIMETYPE_AUDIO_OPUS, isEncoder_);
        if (codec_ == nullptr) {
            return false;
        }
        OH_AVCodecCallback callback = {&OnError, &OnStreamChanged, &OnNeedInput, &OnNewOutput};
        if (OH_AudioCodec_RegisterCallback(codec_, callback, this) != AV_ERR_OK) {
            return false;
        }
        OH_AVFormat *format = OH_AVFormat_Create();
        if (format == nullptr) {
            return false;
        }
        OH_AVFormat_SetIntValue(format, OH_MD_KEY_AUD_SAMPLE_RATE, kSampleRate);
        OH_AVFormat_SetIntValue(format, OH_MD_KEY_AUD_CHANNEL_COUNT, kChannelCount);
        OH_AVFormat_SetIntValue(format, OH_MD_KEY_AUDIO_SAMPLE_FORMAT, SAMPLE_S16LE);
        if (isEncoder_) {
            OH_AVFormat_SetLongValue(format, OH_MD_KEY_BITRATE, bitRate);
            OH_AVFormat_SetLongValue(format, OH_MD_KEY_CHANNEL_LAYOUT, CH_LAYOUT_MONO);
        } else {
            OH_AVFormat_SetIntValue(format, OH_MD_KEY_MAX_INPUT_SIZE, kMaxInputSize);
        }
        bool ok = OH_AudioCodec_Configure(codec_, format) == AV_ERR_OK &&
                  OH_AudioCodec_Prepare(codec_) == AV_ERR_OK &&
                  OH_AudioCodec_Start(codec_) == AV_ERR_OK;
        OH_AVFormat_Destroy(format);
        if (!ok) {
            return false;
        }
        RefreshOutputSampleRate();
        worker_ = std::thread(&OpusSession::Loop, this);
        return true;
    }

    void Post(Job &&job)
    {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (stopping_) {
                return;
            }
            jobs_.push_back(std::move(job));
        }
        cv_.notify_all();
    }

    void Shutdown()
    {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (shutdown_) {
                return;
            }
            shutdown_ = true;
            stopping_ = true;
            jobs_.clear();
        }
        cv_.notify_all();
        if (worker_.joinable()) {
            worker_.join();
        }
        if (codec_ != nullptr) {
            OH_AudioCodec_Stop(codec_);
            OH_AudioCodec_Destroy(codec_);
            codec_ = nullptr;
        }
        if (tsfn_ != nullptr) {
            napi_release_threadsafe_function(tsfn_, napi_tsfn_abort);
            tsfn_ = nullptr;
        }
    }

private:
    static void OnError(OH_AVCodec *, int32_t, void *) {}

    static void OnStreamChanged(OH_AVCodec *, OH_AVFormat *format, void *userData)
    {
        auto *self = static_cast<OpusSession *>(userData);
        int32_t rate = 0;
        if (format != nullptr && OH_AVFormat_GetIntValue(format, OH_MD_KEY_AUD_SAMPLE_RATE, &rate) && rate > 0) {
            std::lock_guard<std::mutex> lock(self->mutex_);
            self->outputSampleRate_ = rate;
        }
    }

    static void OnNeedInput(OH_AVCodec *, uint32_t index, OH_AVBuffer *buffer, void *userData)
    {
        auto *self = static_cast<OpusSession *>(userData);
        {
            std::lock_guard<std::mutex> lock(self->mutex_);
            self->inputs_.push_back({index, buffer});
        }
        self->cv_.notify_all();
    }

    static void OnNewOutput(OH_AVCodec *, uint32_t index, OH_AVBuffer *buffer, void *userData)
    {
        auto *self = static_cast<OpusSession *>(userData);
        {
            std::lock_guard<std::mutex> lock(self->mutex_);
            self->outputs_.push_back({index, buffer});
        }
        self->cv_.notify_all();
    }

    void RefreshOutputSampleRate()
    {
        OH_AVFormat *description = OH_AudioCodec_GetOutputDescription(codec_);
        if (description == nullptr) {
            return;
        }
        int32_t rate = 0;
        if (OH_AVFormat_GetIntValue(description, OH_MD_KEY_AUD_SAMPLE_RATE, &rate) && rate > 0) {
            std::lock_guard<std::mutex> lock(mutex_);
            outputSampleRate_ = rate;
        }
        OH_AVFormat_Destroy(description);
    }

    void Loop()
    {
        while (true) {
            Job job;
            {
                std::unique_lock<std::mutex> lock(mutex_);
                cv_.wait(lock, [this] { return stopping_ || !jobs_.empty(); });
                if (stopping_) {
                    return;
                }
                job = std::move(jobs_.front());
                jobs_.pop_front();
            }
            switch (job.type) {
                case JobType::Encode:
                    HandleEncode(job);
                    break;
                case JobType::Decode:
                    HandleDecode(job);
                    break;
                case JobType::Reset:
                    HandleReset();
                    break;
            }
        }
    }

    bool PushInput(const Bytes &data)
    {
        std::unique_lock<std::mutex> lock(mutex_);
        auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(kInputWaitMs);
        while (!stopping_) {
            if (inputs_.empty()) {
                bool ready = cv_.wait_until(lock, deadline, [this] { return stopping_ || !inputs_.empty(); });
                if (!ready || stopping_) {
                    return false;
                }
                continue;
            }
            CodecBuffer input = inputs_.front();
            int32_t capacity = OH_AVBuffer_GetCapacity(input.buffer);
            if (capacity < static_cast<int32_t>(data.size())) {
                return false;
            }
            inputs_.pop_front();
            lock.unlock();
            bool pushed = FillAndPush(input, data);
            lock.lock();
            if (pushed) {
                return true;
            }
        }
        return false;
    }

    bool FillAndPush(const CodecBuffer &input, const Bytes &data)
    {
        uint8_t *addr = OH_AVBuffer_GetAddr(input.buffer);
        if (addr == nullptr) {
            return false;
        }
        std::memcpy(addr, data.data(), data.size());
        OH_AVCodecBufferAttr attr;
        attr.pts = pts_;
        attr.size = static_cast<int32_t>(data.size());
        attr.offset = 0;
        attr.flags = AVCODEC_BUFFER_FLAGS_NONE;
        if (OH_AVBuffer_SetBufferAttr(input.buffer, &attr) != AV_ERR_OK) {
            return false;
        }
        if (OH_AudioCodec_PushInputBuffer(codec_, input.index) != AV_ERR_OK) {
            return false;
        }
        pts_ += kFrameDurationUs;
        return true;
    }

    std::vector<Bytes> DrainOutputs(int32_t firstWaitMs)
    {
        std::vector<CodecBuffer> ready;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            if (outputs_.empty() && firstWaitMs > 0) {
                cv_.wait_for(lock, std::chrono::milliseconds(firstWaitMs),
                             [this] { return stopping_ || !outputs_.empty(); });
            }
            ready.assign(outputs_.begin(), outputs_.end());
            outputs_.clear();
        }
        std::vector<Bytes> result;
        for (const CodecBuffer &output : ready) {
            OH_AVCodecBufferAttr attr;
            std::memset(&attr, 0, sizeof(attr));
            if (OH_AVBuffer_GetBufferAttr(output.buffer, &attr) == AV_ERR_OK && attr.size > 0 &&
                (attr.flags & AVCODEC_BUFFER_FLAGS_CODEC_DATA) == 0 && (attr.flags & AVCODEC_BUFFER_FLAGS_EOS) == 0) {
                uint8_t *addr = OH_AVBuffer_GetAddr(output.buffer);
                if (addr != nullptr) {
                    result.emplace_back(addr + attr.offset, addr + attr.offset + attr.size);
                }
            }
            OH_AudioCodec_FreeOutputBuffer(codec_, output.index);
        }
        return result;
    }

    void HandleEncode(const Job &job)
    {
        for (const Bytes &frame : job.payloads) {
            PushInput(frame);
        }
        std::vector<Bytes> packets = DrainOutputs(kEncodeOutputWaitMs);
        if (packets.empty()) {
            return;
        }
        auto *delivery = new Delivery();
        delivery->isEncoder = true;
        delivery->packets = std::move(packets);
        Deliver(delivery);
    }

    void HandleDecode(const Job &job)
    {
        std::vector<int16_t> pcm;
        for (const Bytes &packet : job.payloads) {
            if (packet.empty() || !PushInput(packet)) {
                continue;
            }
            std::vector<Bytes> frames = DrainOutputs(kDecodeOutputWaitMs);
            for (const Bytes &frame : frames) {
                size_t samples = frame.size() / sizeof(int16_t);
                size_t offset = pcm.size();
                pcm.resize(offset + samples);
                std::memcpy(pcm.data() + offset, frame.data(), samples * sizeof(int16_t));
            }
        }
        int32_t rate;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            rate = outputSampleRate_;
        }
        auto *delivery = new Delivery();
        delivery->isEncoder = false;
        delivery->pcm = ResampleTo16k(pcm, rate);
        delivery->finished = job.finished;
        delivery->tag = job.tag;
        Deliver(delivery);
    }

    void HandleReset()
    {
        OH_AudioCodec_Flush(codec_);
        {
            std::lock_guard<std::mutex> lock(mutex_);
            inputs_.clear();
            outputs_.clear();
        }
        OH_AudioCodec_Start(codec_);
        pts_ = 0;
    }

    void Deliver(Delivery *delivery)
    {
        if (tsfn_ == nullptr || napi_call_threadsafe_function(tsfn_, delivery, napi_tsfn_nonblocking) != napi_ok) {
            delete delivery;
        }
    }

    bool isEncoder_;
    OH_AVCodec *codec_ = nullptr;
    napi_threadsafe_function tsfn_ = nullptr;
    std::mutex mutex_;
    std::condition_variable cv_;
    std::deque<CodecBuffer> inputs_;
    std::deque<CodecBuffer> outputs_;
    std::deque<Job> jobs_;
    bool stopping_ = false;
    bool shutdown_ = false;
    int32_t outputSampleRate_ = kSampleRate;
    int64_t pts_ = 0;
    std::thread worker_;
};

std::mutex g_sessionsMutex;
std::map<int32_t, std::shared_ptr<OpusSession>> g_sessions;
int32_t g_nextHandle = 1;

std::shared_ptr<OpusSession> FindSession(int32_t handle)
{
    std::lock_guard<std::mutex> lock(g_sessionsMutex);
    auto it = g_sessions.find(handle);
    if (it == g_sessions.end()) {
        return nullptr;
    }
    return it->second;
}

napi_value MakeUndefined(napi_env env)
{
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value MakeNumber(napi_env env, int32_t value)
{
    napi_value result;
    napi_create_int32(env, value, &result);
    return result;
}

napi_value MakeArrayBuffer(napi_env env, const void *data, size_t length)
{
    void *buffer = nullptr;
    napi_value result;
    if (napi_create_arraybuffer(env, length, &buffer, &result) != napi_ok) {
        return MakeUndefined(env);
    }
    if (length > 0 && buffer != nullptr) {
        std::memcpy(buffer, data, length);
    }
    return result;
}

bool ReadArrayBuffer(napi_env env, napi_value value, Bytes &out)
{
    bool isArrayBuffer = false;
    if (napi_is_arraybuffer(env, value, &isArrayBuffer) != napi_ok || !isArrayBuffer) {
        return false;
    }
    void *data = nullptr;
    size_t length = 0;
    if (napi_get_arraybuffer_info(env, value, &data, &length) != napi_ok) {
        return false;
    }
    if (data == nullptr || length == 0) {
        out.clear();
        return true;
    }
    const auto *bytes = static_cast<const uint8_t *>(data);
    out.assign(bytes, bytes + length);
    return true;
}

bool ReadInt32(napi_env env, napi_value value, int32_t &out)
{
    return napi_get_value_int32(env, value, &out) == napi_ok;
}

void CallJs(napi_env env, napi_value jsCallback, void *, void *data)
{
    auto *delivery = static_cast<Delivery *>(data);
    if (env == nullptr || jsCallback == nullptr) {
        delete delivery;
        return;
    }
    napi_value undefined = MakeUndefined(env);
    if (delivery->isEncoder) {
        napi_value array;
        napi_create_array_with_length(env, delivery->packets.size(), &array);
        for (size_t i = 0; i < delivery->packets.size(); ++i) {
            const Bytes &packet = delivery->packets[i];
            napi_set_element(env, array, static_cast<uint32_t>(i), MakeArrayBuffer(env, packet.data(), packet.size()));
        }
        napi_call_function(env, undefined, jsCallback, 1, &array, nullptr);
    } else {
        napi_value args[3];
        napi_create_double(env, delivery->tag, &args[0]);
        args[1] = MakeArrayBuffer(env, delivery->pcm.data(), delivery->pcm.size() * sizeof(int16_t));
        napi_get_boolean(env, delivery->finished, &args[2]);
        napi_call_function(env, undefined, jsCallback, 3, args, nullptr);
    }
    delete delivery;
}

napi_value CreateSession(napi_env env, bool isEncoder, int64_t bitRate, napi_value callback)
{
    napi_valuetype type = napi_undefined;
    if (napi_typeof(env, callback, &type) != napi_ok || type != napi_function) {
        return MakeNumber(env, 0);
    }
    napi_value resourceName;
    napi_create_string_utf8(env, "AIOpusCodec", NAPI_AUTO_LENGTH, &resourceName);
    napi_threadsafe_function tsfn = nullptr;
    if (napi_create_threadsafe_function(env, callback, nullptr, resourceName, 0, 1, nullptr, nullptr, nullptr, CallJs,
                                        &tsfn) != napi_ok) {
        return MakeNumber(env, 0);
    }
    auto session = std::make_shared<OpusSession>(isEncoder);
    if (!session->Open(bitRate, tsfn)) {
        session->Shutdown();
        return MakeNumber(env, 0);
    }
    int32_t handle;
    {
        std::lock_guard<std::mutex> lock(g_sessionsMutex);
        handle = g_nextHandle++;
        g_sessions[handle] = session;
    }
    return MakeNumber(env, handle);
}

napi_value IsEncoderSupported(napi_env env, napi_callback_info)
{
    napi_value result;
    napi_get_boolean(env, OH_AVCodec_GetCapability(OH_AVCODEC_MIMETYPE_AUDIO_OPUS, true) != nullptr, &result);
    return result;
}

napi_value IsDecoderSupported(napi_env env, napi_callback_info)
{
    napi_value result;
    napi_get_boolean(env, OH_AVCodec_GetCapability(OH_AVCODEC_MIMETYPE_AUDIO_OPUS, false) != nullptr, &result);
    return result;
}

napi_value CreateEncoder(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc < 2) {
        return MakeNumber(env, 0);
    }
    int32_t bitRate = 0;
    if (!ReadInt32(env, args[0], bitRate) || bitRate <= 0) {
        return MakeNumber(env, 0);
    }
    return CreateSession(env, true, bitRate, args[1]);
}

napi_value CreateDecoder(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc < 1) {
        return MakeNumber(env, 0);
    }
    return CreateSession(env, false, 0, args[0]);
}

napi_value Encode(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    int32_t handle = 0;
    if (argc < 2 || !ReadInt32(env, args[0], handle)) {
        return MakeUndefined(env);
    }
    std::shared_ptr<OpusSession> session = FindSession(handle);
    Bytes frame;
    if (session == nullptr || !ReadArrayBuffer(env, args[1], frame) || frame.empty()) {
        return MakeUndefined(env);
    }
    Job job;
    job.type = JobType::Encode;
    job.payloads.push_back(std::move(frame));
    session->Post(std::move(job));
    return MakeUndefined(env);
}

napi_value Decode(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value args[4];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    int32_t handle = 0;
    if (argc < 4 || !ReadInt32(env, args[0], handle)) {
        return MakeUndefined(env);
    }
    std::shared_ptr<OpusSession> session = FindSession(handle);
    if (session == nullptr) {
        return MakeUndefined(env);
    }
    Job job;
    job.type = JobType::Decode;
    bool isArray = false;
    if (napi_is_array(env, args[1], &isArray) == napi_ok && isArray) {
        uint32_t length = 0;
        napi_get_array_length(env, args[1], &length);
        for (uint32_t i = 0; i < length; ++i) {
            napi_value element;
            if (napi_get_element(env, args[1], i, &element) != napi_ok) {
                continue;
            }
            Bytes packet;
            if (ReadArrayBuffer(env, element, packet) && !packet.empty()) {
                job.payloads.push_back(std::move(packet));
            }
        }
    }
    napi_get_value_bool(env, args[2], &job.finished);
    napi_get_value_double(env, args[3], &job.tag);
    session->Post(std::move(job));
    return MakeUndefined(env);
}

napi_value Reset(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    int32_t handle = 0;
    if (argc < 1 || !ReadInt32(env, args[0], handle)) {
        return MakeUndefined(env);
    }
    std::shared_ptr<OpusSession> session = FindSession(handle);
    if (session != nullptr) {
        Job job;
        job.type = JobType::Reset;
        session->Post(std::move(job));
    }
    return MakeUndefined(env);
}

napi_value Release(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    int32_t handle = 0;
    if (argc < 1 || !ReadInt32(env, args[0], handle)) {
        return MakeUndefined(env);
    }
    std::shared_ptr<OpusSession> session;
    {
        std::lock_guard<std::mutex> lock(g_sessionsMutex);
        auto it = g_sessions.find(handle);
        if (it != g_sessions.end()) {
            session = it->second;
            g_sessions.erase(it);
        }
    }
    if (session != nullptr) {
        session->Shutdown();
    }
    return MakeUndefined(env);
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor descriptors[] = {
        {"isEncoderSupported", nullptr, IsEncoderSupported, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isDecoderSupported", nullptr, IsDecoderSupported, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"createEncoder", nullptr, CreateEncoder, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"createDecoder", nullptr, CreateDecoder, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"encode", nullptr, Encode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"decode", nullptr, Decode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"reset", nullptr, Reset, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"release", nullptr, Release, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    return exports;
}

napi_module g_module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "aiaudiocodec",
    .nm_priv = nullptr,
    .reserved = {0},
};

}

extern "C" __attribute__((constructor)) void RegisterAIAudioCodecModule(void)
{
    napi_module_register(&g_module);
}
