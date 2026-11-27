/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module：   TMGAudioCtrl@GMESDK
 * Function： 腾讯云 GME 音频控制相关功能接口。
 */
import { a2, b2, c2 } from "./z";
export interface q1 {
    /**
     * 开启或关闭麦克风。
     *
     * 此接口用来开启/关闭麦克风，并推送音频流到房间，需要在**接收到进房成功事件后**调用，加入房间默认不会打开麦克风。
     * {@link EnableMic}(boolean) = {@link EnableAudioCaptureDevice}(boolean) + {@link EnableAudioSend}(boolean)。
     * @param enable true：开启  false：关闭。
     */
    d2(enable: boolean): number;
    /**
     * 麦克风状态获取。
     *
     * 此接口用于获取麦克风状态，返回值 0 为关闭麦克风状态，返回值 1 为打开麦克风状态。
     */
    e2(): number;
    /**
     * 开启或关闭扬声器。
     *
     * 此接口用于开启/关闭扬声器，并接收远端的音频流，需要在**接收到进房成功事件后**调用，加入房间默认不会打开扬声器。
     * {@link EnableSpeaker}(boolean) = {@link EnableAudioPlayDevice}(boolean) + {@link EnableAudioRecv}(boolean)。
     * @param enable true：开启  false：关闭。
     */
    f2(enable: boolean): number;
    /**
     * 扬声器状态获取。
     *
     * 此接口用于扬声器状态获取。返回值 0 为关闭扬声器状态，返回值 1 为打开扬声器状态。
     */
    g2(): number;
    /**
     * 开启音频采集设备。
     *
     * 此接口用来开启/关闭采集设备，需要在**接收到进房成功事件后**调用，加入房间默认不打开采集设备。
     * @param enable true：开启  false：关闭。
     */
    h2(enable: boolean): number;
    /**
     * 获取采集设备状态。
     *
     * 此接口用于采集设备状态获取。
     */
    i2(): boolean;
    /**
     * 开启或关闭播放设备。
     *
     * 此接口用于开启关闭播放设备，需要在**接收到进房成功事件后**调用，加入房间默认不打开播放设备。
     * @param enable true：开启  false：关闭。
     */
    j2(enable: boolean): number;
    /**
     * 获取播放设备状态。
     *
     * 此接口用于获取播放设备状态。
     */
    l2(): boolean;
    /**
     * 打开关闭音频上行。
     *
     * 此接口用于打开/关闭音频上行，需要在**接收到进房成功事件后**调用，用来控制否是将采集到的音频数据发送给远端用户。如果采集设备已经打开，那么会发送采集到的音频数据。如果采集设备没有打开，那么仍旧无声。采集设备的打开关闭请参见接口  {@link
     * EnableAudioCaptureDevice}。
     * @param enable true：打开  false：关闭。
     */
    m2(enable: boolean): number;
    /**
     * 获取音频上行状态。
     *
     * 此接口用于音频上行状态获取。
     */
    n2(): boolean;
    /**
     * 打开或关闭音频下行。
     *
     * 此接口用于打开/关闭音频下行，需要在**接收到进房成功事件后**调用，用于控制是否接收远端用户的音频数据。如果播放设备已经打开，那么会播放房间里其他人的音频数据。如果播放设备没有打开，那么仍旧无声。播放设备的打开关闭参见接口请参见接口 {@link
     * EnableAudioPlayDevice}。
     * @param enable true：打开  false：关闭。
     */
    o2(enable: boolean): number;
    /**
     * 获取音频下行状态。
     *
     * 此接口用于音频下行状态获取。
     */
    q2(): boolean;
    /**
     * 设置麦克风音量的增益。
     *
     * 此接口用于设置麦克风音量的增益。
     * @param volume 音量增益大小，取值 [0，200]，其中 100 为默认值，相当于音量大小不增不减。
     */
    s2(volume: number): number;
    /**
     * 获取麦克风音量的增益。
     *
     * 获取使用 {@link SetMicVolume} 设置的麦克风音量增益大小。
     */
    t2(): number;
    /**
     * 设置扬声器音量增益。
     *
     * 此接口用于设置扬声器音量的增益。
     * @param volume 音量增益大小，取值 [0，200]，其中 100 为默认值，相当于音量大小不增不减。
     */
    u2(volume: number): number;
    /**
     * 获取扬声器音量增益。
     *
     * 获取使用 {@link SetSpeakerVolume} 设置的扬声器音量增益大小。
     */
    v2(): number;
    /**
     * 动态设置房间内某成员音量增益。
     *
     * @param userID      用户 ID。
     * @param volume      音量增益大小，取值 [0，200]，其中 100 为默认值，相当于音量大小不增不减。
     */
    w2(userID: string, volume: number): number;
    /**
     * 获取设置的房间内成员音量增益。
     *
     * 获取通过{@link SetSpeakerVolumeByUserID}接口设置的音量增益。
     * @param userID      用户 ID。
     */
    z2(userID: string): number;
    /**
     * 开启/关闭耳返。
     *
     * @param enable      是否开启耳返。
     */
    a3(enable: boolean): number;
    /**
     * 设置耳返音量。
     *
     * 此接口用于设置耳返的音量大小。
     * @param volume      音量大小，取值 [0，200]，其中 100 为默认值，相当于音量大小不增不减。
     */
    b3(volume: number): number;
    /**
     * 禁言房间中某个用户。
     *
     * 将某个用户加入音频数据黑名单，即不接受该用户的语音， 只对本端生效，不会影响其他端。返回值为 0 表示调用成功。
     * @param userID      用户 ID。
     */
    c3(userID: string): number;
    /**
     * 解除对房间中某个用户的禁言。
     *
     * 将某个用户移除音频数据黑名单。返回值为0表示调用成功。
     * @param userID      用户 ID。
     */
    d3(userID: string): number;
    /**
     * 查询某个用户是否被禁言。
     *
     * @param userID      用户 ID。
     */
    e3(userID: string): boolean;
    /**
     * 初始化 3D 音效处理器。
     *
     * 注意此接口已经废除，无需调用。
     */
    f3(modelPath: string): number;
    /**
     * 开启或关闭 3D 音效。
     *
     * 此函数用于开启或关闭 3D 音效。开启之后可以听到 3D 音效。
     * @param enable           是否开启 3D 音效。
     */
    g3(enable: boolean): number;
    /**
     * 获取当前 3D 音效状态。
     *
     * 此函数用于获取当前 3D 音效状态。
     */
    h3(): boolean;
    /**
     * 获取麦克风设备数量（仅适用于桌面端）。
     */
    i3(): number;
    /**
     * 枚举麦克风设备（仅适用于桌面端）。
     *
     * 此接口用来枚举麦克风设备。配合{@link GetMicListCount}接口使用。
     * @param ppDeviceInfoList      设备信息数组指针。
     * @param nCount                设备信息数字长度。
     */
    j3(nCount: number): c2[];
    /**
     * 选择麦克风设备（仅适用于桌面端）。
     *
     * 此接口用来选中麦克风设备。如果不调用或者传入 "0"，则选中系统默认设备。GetMicList 接口中返回的第0个设备 id
     * 为默认设备，未选中设备时通话设备为默认设备，选中后业务层维护通话设备。如果该通话设备被拔出，则此时通话设备为默认设备，拔出的通话设备插入后，此时通话设备恢复为插入的通话设备。
     * @param micId      麦克风设备 ID，设备 ID 来自于{@link GetMicList}返回的设备信息列表。
     */
    l3(micId: string): number;
    /**
     * 获取当前使用的麦克风设备（仅适用于桌面平台）。
     *
     * 此接口用来获取当前使用的麦克风设备。
     * @param pDeviceInfo      设备信息指针。
     */
    m3(): c2;
    /**
     * 获取扬声器设备数量（仅适用于桌面端）。
     */
    n3(): number;
    /**
     * 枚举扬声器设备（仅适用于桌面端）。
     *
     * 此接口用来枚举扬声器设备。配合{@link GetSpeakerListCount}接口使用。
     * @param ppDeviceInfoList      设备信息数组指针。
     * @param nCount                设备信息数字长度。
     */
    q3(nCount: number): c2[];
    /**
     * 选择扬声器设备（仅适用于桌面端）。
     *
     * 此接口用来选中播放设备。如果不调用或者传入 "0"，则选中系统默认播放设备。
     * @param pSpeakerID      扬声器设备 ID，设备 ID 来自于{@link GetSpeakerList}返回设备信息列表。
     */
    r3(speakerID: string): number;
    /**
     * 获取当前使用的扬声器设备（仅适用于桌面端）。
     *
     * 此接口用来获取当前使用的扬声器设备。
     * @param pDeviceInfo      设备信息指针。
     */
    s3(): c2;
    /**
     * 启用音频自定义采集模式。
     *
     * 开启该模式后，SDK 不在运行原有的音频采集流程，即不再继续从麦克风采集音频数据，而是只保留音频编码和发送能力。
     * 您需要通过 {@link SendCustomAudioData} 不断地向 SDK 塞入自己采集的音频数据。
     * @param enable 是否启用，默认值：false。
     * @note 由于回声抵消（AEC）需要严格的控制声音采集和播放的时间，所以开启自定义音频采集后，AEC 能力可能会失效。
     */
    t3(enable: boolean): number;
    /**
     * 设置音频路由
     *
     * 设置“音频路由”，即设置声音是从手机的哪个设备播放出来的，常见的播放设备包括扬声器，听筒，因此该接口仅适用于手机等移动端设备。
     * 手机默认有 2 个播放器：一个是位于手机顶部的听筒，一个是位于手机底部的立体声扬声器。
     * 设置音频路由为听筒时，声音比较小，只有将耳朵凑近才能听清楚，隐私性较好，适合用于接听电话。
     * 设置音频路由为扬声器时，声音比较大，不用将手机贴脸也能听清，因此可以实现“免提”的功能。
     * @param route 音频路由，即声音由哪里输出（扬声器、听筒），默认值：{@link $ITMG_AUDIO_ROUTE_SPEAKER$}。
     */
    u3(route: b2): number;
    /**
     * 向 SDK 投送自己采集的音频数据。
     *
     * 请您精准地按每帧时长的间隔调用本接口，数据投送间隔不均匀时极易触发声音卡顿。
     * 参数 {@link TMGAudioFrame} 推荐下列填写方式（其他字段不需要填写）：
     * - data：音频帧 buffer。音频帧数据只支持 PCM 格式，支持[5ms ~ 100ms]帧长，推荐使用 20ms 帧长，长度计算方法：【48000采样率、单声道的帧长度：48000 × 0.02s × 1 × 16bit = 15360bit = 1920字节】。
     * - sample_rate：采样率，支持：16000、24000、32000、44100、48000。
     * - channel：声道数（如果是立体声，数据是交叉的），单声道：1； 双声道：2。
     * - timestamp：时间戳，单位为毫秒（ms），请使用音频帧在采集时被记录下来的时间戳（可以在采集到一帧音频帧之后，通过调用 {@link generateCustomPTS} 获取时间戳）。
     * - bits_type：位深，目前版本只支持16bit--PCM_BITS_TYPE_FIXED_16。
     * @param frame 音频数据。
     */
    v3(frame: a2): number;
    /**
     * 开启音频自定义播放。
     *
     * @note 需要您在进入房间前设置才能生效，暂不支持进入房间后再设置。
     * 如果您需要外接一些特定的音频设备，或者希望自己掌控音频的播放逻辑，您可以通过该接口启用音频自定义播放。
     * 启用音频自定义播放后，SDK 将不再调用系统的音频接口播放数据，您需要通过 {@link GetCustomAudioRenderingFrame} 获取 SDK 要播放的音频帧并自行播放。
     * @param enable 是否启用音频自定义播放，默认为关闭状态。
     */
    w3(enable: boolean): number;
    /**
     * 获取可播放的音频数据。
     *
     * 调用该接口之前，您需要先通过 {@link EnableCustomAudioRendering} 开启音频自定义播放。
     * 参数 {@link TMGAudioFrame} 推荐下列填写方式（其他字段不需要填写）：
     * - sample_rate：采样率，必填，支持 16000、24000、32000、44100、48000。
     * - channel：声道数，必填，单声道请填1，双声道请填2，双声道时数据是交叉的。
     * - data：用于获取音频数据的 buffer。需要您根据一帧音频帧的帧长度分配好 data 的内存大小。获取的 PCM 数据支持 10ms 或 20ms 两种帧长，推荐使用 20ms 的帧长。
     * - bits_type：位深，目前版本只支持16bit--PCM_BITS_TYPE_FIXED_16
     * 计算公式为：采样率 x 播放时长 x 声道数量 x 2（每个样点的字节数）， 例如： 48000采样率、单声道、且播放时长为 20ms 的一帧音频帧的 buffer 大小为 48000 × 0.02s × 1 × 16bit = 15360bit = 1920字节。
     * @param frame 音频数据帧。
     * @note
     *   1. 参数 frame 中的 sample_rate、channel 需提前设置好，同时分配好所需读取帧长的 data 空间。
     *   2. SDK 内部会根据 sample_rate 和 channel 自动填充 data 数据。
     *   3. 建议由系统的音频播放线程直接驱动该函数的调用，在播放完一帧音频之后，即调用该接口获取下一帧可播放的音频数据。
     */
    x3(frame: a2): number;
    /**
     * 开启音量回调。
     *
     * @param interval 音量回调周期，单位（秒）。
     * @note
     *   通过 ITMG_MAIN_EVENT_TYPE_USER_VOLUMES 事件返回用户音量数据。
     */
    y3(interval: number): number;
    /**
     * 停止音量回调。
     */
    z3(): number;
    /**
     * 获取实时麦克风音量。
     */
    a4(): number;
    /**
     * 获取实时扬声器音量。
     */
    b4(): number;
    /**
     * 获取音频上行实时音量。
     */
    c4(): number;
    /**
     * 获取房间内其他成员下行实时音量。
     *
     * @param userID 房间其他成员的 ID。
     */
    d4(userID: string): number;
    /**
     * 开始麦克风测试 [仅桌面端有效]。
     *
     * @param interval 麦克风音量的回调间隔。
     * @note
     *   通过 ITMG_MAIN_EVENT_TYPE_TEST_MIC_VOLUME 事件返回测试结果。
     */
    e4(interval: number): number;
    /**
     * 结束麦克风测试 [仅桌面端有效]。
     */
    f4(): number;
    /**
     * 开始扬声器测试 [仅桌面端有效]。
     *
     * @param filePath 声音文件的路径。
     * @note
     *   通过ITMG_MAIN_EVENT_TYPE_TEST_SPEAKER_VOLUME事件返回测试结果。
     */
    g4(filePath: string): number;
    /**
     * 结束扬声器测试 [仅桌面端有效]。
     */
    h4(): number;
}
