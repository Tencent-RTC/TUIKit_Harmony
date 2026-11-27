/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * optional param key定义
 *
 * optional key的声明格式如下: OPTIONAL_ID+设置时机（BEFORE/GLOBAL）+ 数据类型
 * (BOOL/LONG/FLOAT/STRING/QUEUE_INT/QUEUE_STRING/OBJECT)+ 名称。
 * 举例说明：
 *      设置时机 BEFORE：表示这个参数必须在prepareAsync之前设置，否则设置无效
 *      设置时机 GLOBAL：表示这个参数在播放过程中都可以设置（包含BEFORE时机），设置之后就立即生效
 *      OPTIONAL_ID_BEFORE_LONG_START_PLAYING_TIME_MS表示此option id是用于设置开始播放的时间点，
 *      它的value的数据类型是long类型， 需要在prepareAsync之前设置。
 *
 * @author harleyxwang
 * @date 2024/03/21
 */
export const enum TPOptionalID {
  // 公共配置

  /**
   * 播放器调度线程优先级，取值参考:{@link TPThreadPriority}
   * 默认值：TP_THREAD_PRIORITY_DEFAULT 默认的线程优先级, 继承父线程优先级
   */
  OPTIONAL_ID_BEFORE_INT_PLAYER_SCHEDULING_THREAD_PRIORITY = 'optional_id_before_int_player_scheduling_thread_priority',

  /**
   * 是否使能DRM事件打点 如果不设置，则默认为false, 如果设置true后，
   * 将会通过{@link IOnDebugTrackingInfoCallback} 回调信息
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_DRM_EVENT_TRACKING = 'optional_id_before_bool_enable_drm_event_tracking',

  // Demuxer相关配置

  /**
   * 开始播放的时间点
   * 默认值：0
   */
  OPTIONAL_ID_BEFORE_LONG_START_PLAYING_TIME_MS = 'optional_id_before_long_start_playing_time_ms',

  /**
   * 跳转到开始播放的时间点时，是否使用精确seek
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_START_PLAYING_TIME_ACCURATE_SEEK = 'optional_id_before_bool_start_playing_time_accurate_seek',

  /**
   * demuxer线程优先级，取值参考:{@link TPThreadPriority}
   * 默认值：TP_THREAD_PRIORITY_DEFAULT，继承自父线程优先级
   */
  OPTIONAL_ID_BEFORE_INT_DEMUXER_THREAD_PRIORITY = 'optional_id_before_int_demuxer_thread_priority',

  /**
   * 数据缓冲区的大小，用总时长数量表示，单位毫秒
   * 默认值：6000ms
   */
  OPTIONAL_ID_BEFORE_LONG_BUFFER_PACKET_TOTAL_DURATION_MS = 'optional_id_before_long_buffer_packet_total_duration_ms',

  /**
   * 首次播放加载数据大小，用于控制缓存数据量来通知Prepared，用总时长表示，单位毫秒
   * 默认值：200ms
   */
  OPTIONAL_ID_BEFORE_LONG_PREPARE_PACKET_TOTAL_DURATION_MS = 'optional_id_before_long_prepare_packet_total_duration_ms',

  /**
   * 缓冲时（缓冲数据不够引起的二次缓冲，或seek引起的拖动缓冲）最少要缓存多长时间的数据才能结束缓冲，回抛bufferingEnd，单位ms
   * 默认值：4000ms
   */
  OPTIONAL_ID_BEFORE_LONG_BUFFERING_FOR_PLAYBACK_MS = 'optional_id_before_long_buffering_for_playback_ms',

  /**
   * 缓冲超时时间，即最大允许的缓冲时间，超过这个时间，则播放器将报错
   * 默认值：60000ms
   */
  OPTIONAL_ID_BEFORE_LONG_BUFFERING_TIMEOUT_MS = 'optional_id_before_long_buffering_timeout_ms',

  /**
   * 是否要保持原始流的PTS值。如果为true，则输出到render的PTS会保持原始流的值，可能做时间单位的变换，但不会做任何其他形式的变换（比如对PTS跳变进行重新对齐）。
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_KEEP_ORIGINAL_PTS = 'optional_id_before_bool_keep_original_pts',

  /**
   * HLS格式的回调Tag, 例如设置：['#EXT-QQHLS-AD,#EXT-X-PROGRAM-DATE-TIME'],通过如下回调获取
   * {@link TPOnInfoID#TP_ONINFO_ID_STRING1_PRIVATE_HLS_TAG}
   * 默认值：空
   */
  OPTIONAL_ID_BEFORE_QUEUE_STRING_HLS_TAG_CALLBACK = 'optional_id_before_queue_string_hls_tag_callback',

  /**
   * 是否开启根据当前屏幕刷新率进行丢帧处理逻辑
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_DROP_FRAME_BY_REFRESH_RATE = 'optional_id_before_bool_enable_drop_frame_by_refresh_rate',

  /**
   * 是否打开audio passthrough的开关
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AUDIO_PASSTHROUGH = 'optional_id_before_bool_enable_audio_passthrough',

  /**
   * prepare超时时间，超过这个时间，则直接报错，单位ms
   * 默认值：60000ms
   */
  OPTIONAL_ID_BEFORE_LONG_PREPARE_TIMEOUT_MS = 'optional_id_before_long_prepare_timeout_ms',

  /**
   * 设置起播时的流分析最大时长（当前仅对ffmpeg有效，较小的值有利于降低起播耗时，但会增大流分析失败的机率)，单位ms
   * 默认值：0，表示使用FFmpeg内置的默认大小(5000ms)
   */
  OPTIONAL_ID_BEFORE_LONG_MAX_ANALYZE_DURATION_MS = 'optional_id_before_long_max_analyze_duration_ms',

  /**
   * 选择播放器demuxer策略, standalone,ffmpeg demuxer，取值参考:{@link TPDemuxerType}
   * 默认值：内部决策, 详见TPDemuxerStrategy的实现
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_DEMUXER_TYPE = 'optional_id_before_queue_int_demuxer_type',

  /**
   * 设置缓冲机制，取值参考：{@link TPBufferStrategy}
   * 默认值：auto，自动模式，由内部自己决策
   */
  OPTIONAL_ID_BEFORE_INT_BUFFER_STRATEGY = 'optional_id_before_int_buffer_strategy',

  /**
   * JitterBuffer参数，取值参考:{@link TPJitterBufferParams}
   * 默认值：null，内部自己决策
   */
  OPTIONAL_ID_BEFORE_OBJECT_JITTER_BUFFER_PARAMS = 'optional_id_before_object_jitter_buffer_params',

  /**
   * 配置业务想接收的定制化SEI类型，取值为int型数组
   * 默认值：空
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_SPECIAL_SEI_TYPES_CALLBACK = 'optional_id_before_queue_int_special_sei_types_callback',

  /**
   * 设置是否开启精确duration计算，主要是为了aac文件。 因为aac文件是音频裸码流，没有duration信息，FFMPEG获取到的duration是根据比特率计算的，可能不准确。
   * 如果需要获取精确的duration信息，需要打开该设置开关。对于时长比较长的文件，不建议打开该设置，因为对首缓可能有影响。
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_ACCURATE_DURATION = 'optional_id_before_bool_enable_accurate_duration',

  /**
   * 设置是否允许忽略音频文件中的视频流。主要作用于"mp3","wav","wma","aac","flac","ogg","ape"等常见的音频格式文件
   * 默认值：true，忽略常见音频格式文件中的视频流。
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_IGNORE_VIDEO_STREAM_IN_COMMON_AUDIO_FORMATS
                             = 'optional_id_before_bool_enable_ignore_video_stream_in_common_audio_formats',

  /**
   * 设置切换数据源时保留的最小缓冲时长，单位ms
   * 默认值：2000ms
   */
  OPTIONAL_ID_BEFORE_LONG_MIN_LEFT_PACKET_QUEUE_TOTAL_DURATION_MS_FOR_SWITCH_DATA_SOURCE
                             = 'optional_id_before_long_min_left_packet_queue_total_duration_ms_for_switch_data_source',

  /**
   * 如果支持avs3 audio音频解码，需要传入对应解码模型绝对路径，否则无法解码；
   * 解封装时FFMPEG尝试打开解码器，所以此模型配置放置于demuxer相关项
   * 默认值：''
   */
  OPTIONAL_ID_BEFORE_STRING_AVS3_AUDIO_DECODER_MODEL_PATH = 'optional_id_before_string_avs3_audio_decoder_model_path',
  /**
   * avs3 audio解码器支持多线程解码，可配置多线程数量
   * 默认值：0 不对解码器进行外部多线程数量配置，由内部自行判断
   */
  OPTIONAL_ID_BEFORE_INT_AVS3_AUDIO_DECODER_THREAD_COUNT = 'optional_id_before_int_avs3_audio_decoder_thread_count',

  /**
   * 设置是否使能新的FLV的特殊配置解析
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_NEW_FLV_SPECIAL_CONFIG_PARSE = 'optional_id_before_bool_enable_new_flv_special_config_parse',

  /**
   * 设置是否使能FFmpeg HLS直播拉新m3u8首片不连续修复逻辑
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_FFMPEG_LIVE_HLS_FIRST_SEGMENT_DISCONTINUITY_FIX
                             = 'optional_id_before_bool_enable_ffmpeg_live_hls_first_segment_discontinuity_fix',

  /**
   * 设置是否使能片内seek修复逻辑
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_SEGMENT_INTERNAL_SEEK_FIX = 'optional_id_before_bool_enable_segment_internal_seek_fix',

  // Decoder相关配置

  /**
   * Decoder能容忍的最大错误次数，超过这个次数就按配置的或者默认的策略切换至下一个解码
   * 默认值：100
   */
  OPTIONAL_ID_BEFORE_INT_DECODER_MAX_TOLERATED_ERROR_COUNT = 'optional_id_before_int_decoder_max_tolerated_error_count',

  /**
   * 解码参数发生改变后，是否需要reset decoder， 默认true，
   * 但是在一些定制平台上，如企鹅盒子，如果发生编码参数变化（如清晰度变化），解码器内部能自己检测解码参数并reset，
   * 如果我们调用它们的解码器接口重置的话，会有很长的耗时，导致清晰度切换过程出现卡顿。
   * 默认值：true
   */
  OPTIONAL_ID_BEFORE_BOOL_RESET_DECODER_ON_PARAMETER_CHANGE = 'optional_id_before_bool_reset_decoder_on_parameter_change',

  /**
   * 视频解码策略，int数组类型，数组取值为:{@link TPVideoCodecType}
   * 默认值：内部决策
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_VIDEO_DECODER_TYPE = 'optional_id_before_queue_int_video_decoder_type',

  /**
   * 音频解码策略，int数组类型，数组取值为:{@link TPAudioDecoderType}
   * 默认值：内部决策
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_AUDIO_DECODER_TYPE = 'optional_id_before_queue_int_audio_decoder_type',

  /**
   * 设置下载组件开关配置，特殊场景不能使用代理，比如直播答题
   * 默认值：true
   */
  OPTIONAL_ID_BEFORE_BOOL_USE_DOWNLOAD_PROXY = 'optional_id_before_bool_use_download_proxy',

  /**
   * 设置是否开启本地代理http加密校验
   * 需开启{@link TPOptionalID#OPTIONAL_ID_BEFORE_BOOL_USE_DOWNLOAD_PROXY}
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_USE_PROXY_AUTHENTICATION = 'optional_id_before_bool_use_proxy_authentication',

  /**
   * 设置是否开启下载组件发生异常并且socket连接拒绝之后重试原始URL
   * 默认值：true
   */
  // #lizard forgives
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_RETRY_ORIGINAL_URL_WHEN_DOWNLOAD_PROXY_EXCEPTION_AND_CONNECT_REFUSED
                      = 'optional_id_before_bool_enable_retry_original_url_when_download_proxy_exception_and_connect_refused',

  /**
   * 视频解码线程优先级，取值参考:{@link TPThreadPriority}
   * 默认值：TP_THREAD_PRIORITY_DEFAULT, 复用父线程优先级
   */
  OPTIONAL_ID_BEFORE_INT_VIDEO_DECODER_THREAD_PRIORITY = 'optional_id_before_int_video_decoder_thread_priority',

  /**
   * 音频解码线程优先级，取值参考:{@link TPThreadPriority}
   * 默认值：TP_THREAD_PRIORITY_DEFAULT, 复用父线程优先级
   */
  OPTIONAL_ID_BEFORE_INT_AUDIO_DECODER_THREAD_PRIORITY = 'optional_id_before_int_audio_decoder_thread_priority',

  /**
   * 设置通过 IOnAudioFrameOutCallback 回抛的音频格式 取值见 {@link TPSampleFormat}
   * 默认值：TP_SAMPLE_FMT_NONE， 依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_AUDIO_SAMPLE_FORMAT = 'optional_id_before_int_out_audio_sample_format',

  /**
   * 设置通过 IOnAudioFrameOutCallback 回抛的音频声道布局 取值见 {@link TPChannelLayout}
   * 默认值：依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_LONG_OUT_AUDIO_CHANNEL_LAYOUT = 'optional_id_before_long_out_audio_channel_layout',

  /**
   * 设置通过 IOnAudioFrameOutCallback 回抛的音频采样率，单位为Hz
   * 默认值：0，依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_AUDIO_SAMPLE_RATE_HZ = 'optional_id_before_int_out_audio_sample_rate_hz',

  /**
   * 设置通过 IOnAudioFrameOutCallback 回抛的音频帧大小，单位为byte
   * 默认值：0，依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_AUDIO_FRAME_SIZE_BYTE = 'optional_id_before_int_out_audio_frame_size_byte',

  /**
   * 设置通过 IOnVideoFrameOutCallback 回抛的视频格式 取值见 {@link TPPixelFormat}
   * 默认值：TP_PIX_FMT_NONE，依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_VIDEO_PIXEL_FORMAT = 'optional_id_before_int_out_video_pixel_format',

  /**
   * 设置通过 IOnVideoFrameOutCallback 回抛的视频宽度
   * 默认值：0，依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_VIDEO_WIDTH = 'optional_id_before_int_out_video_width',

  /**
   * 设置通过 IOnVideoFrameOutCallback 回抛的视频高度
   * 默认值：0，依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_VIDEO_HEIGHT = 'optional_id_before_int_out_video_height',

  /**
   * 设置通过 IOnVideoFrameOutCallback 回抛的视频旋转角度
   * 默认值：0，依视频源，内部决策
   */
  OPTIONAL_ID_BEFORE_INT_OUT_VIDEO_ROTATION = 'optional_id_before_int_out_video_rotation',

  /**
   * 禁用secure解码组件的drm类型列表。默认是若系统支持secure解码组件就优先使用secure解码组件，
   * 如果配置了该项，则针对该drm类型，不使用secure解码组件。
   * 默认值：空
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_DRM_TYPE_FOR_DISABLE_SECURE_COMPONENT = 'optional_id_before_queue_int_drm_type_for_disable_secure_component',

  // AVSync相关配置

  /**
   * 设置当直播出现高延迟时的需要采取的措施，取值参考：{@link TPReduceLiveLatencyStrategy}
   * 默认值：不采取任何措施TP_REDUCE_LIVE_LATENCY_STRATEGY_NONE
   */
  OPTIONAL_ID_BEFORE_INT_REDUCE_LIVE_LATENCY_ACTION = 'optional_id_before_int_reduce_live_latency_action',

  /**
   * 设置当{@link #OPTIONAL_ID_BEFORE_INT_REDUCE_LIVE_LATENCY_ACTION} 配置为 (TP_REDUCE_LIVE_LATENCY_ACTION_SPEED_UP)时，
   * 需要加速播放的倍速值，必须大于1.0
   * 默认值：1.0
   */
  OPTIONAL_ID_BEFORE_FLOAT_REDUCE_LATENCY_SPEED_UP_RATE = 'optional_id_before_float_reduce_latency_speed_up_rate',

  /**
   * 设置当{@link #OPTIONAL_ID_BEFORE_INT_REDUCE_LIVE_LATENCY_ACTION} 不为 (TP_REDUCE_LIVE_LATENCY_STRATEGY_NONE)时，
   * 缓冲区缓存数据量到达一定阈值时，开始降低延时，单位：ms
   * 默认值：0
   */
  OPTIONAL_ID_BEFORE_LONG_BEGIN_REDUCE_LATENCY_BUFFER_PACKET_DURATION_MS
                                              = 'optional_id_before_long_begin_reduce_latency_buffer_packet_duration_ms',

  /**
   * 是否开启音视频同步。对于一些特殊应用场景，需要关闭音视频同步，比如，输出预览用的一组图像， 把播放器当作转码器的数据源提供方，等等。
   * 默认值：true
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AV_SYNC = 'optional_id_before_bool_enable_av_sync',

  /**
   * 在处理音视频同步的时候，是否把Audio Render底层的latency计算进来。特别针对部分高延迟的蓝牙耳机。
   * 默认值：true
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AUDIO_RENDERER_LATENCY_COMPENSATION = 'optional_id_before_bool_enable_audio_renderer_latency_compensation',

  /**
   * 蓝牙模式下 设置audio latency的最大阈值
   * 默认值：2000ms
   */
  OPTIONAL_ID_BEFORE_LONG_AUDIO_BLUETOOTH_MAX_LIMIT_LATENCY_MS = 'optional_id_before_long_audio_bluetooth_max_limit_latency_ms',

  /**
   * 非蓝牙模式下（手机speaker、wifi音箱）设置audio latency的最大阈值
   * 默认值：500ms
   */
  OPTIONAL_ID_BEFORE_LONG_AUDIO_NON_BLUETOOTH_MAX_LIMIT_LATENCY_MS = 'optional_id_before_long_audio_non_bluetooth_max_limit_latency_ms',

  /**
   * 音频同步策略, 类型由{@link TPAudioAVSyncStrategy}定义
   * 默认值：TP_AUDIO_AVSYNC_PERSIST_FREERUN，持续FreeRun模式, audio不做sleep, 但apts参与同步更新clock
   */
  OPTIONAL_ID_BEFORE_INT_AUDIO_AVSYNC_STRATEGY = 'optional_id_before_int_audio_avsync_strategy',

  /**
   * 视频渲染监测周期。
   * 默认值:0ms，即不开启监测
   */
  OPTIONAL_ID_BEFORE_LONG_VIDEO_RENDER_MONITOR_PERIOD_MS = 'optional_id_before_long_video_render_monitor_period_ms',

  /**
   * 若在OPTIONAL_ID_BEFORE_LONG_VIDEO_RENDER_MONITOR_PERIOD_MS时间内视频丢帧率高于该阈值
   * 则通过oninfo中的TP_INFO_VIDEO_HIGH_FRAME_DROP_RATE消息进行通知。
   * 取值范围[0.0f, 1.0f]，
   * 默认值：1.0f，即不进行通知
   */
  OPTIONAL_ID_BEFORE_FLOAT_VIDEO_HIGH_FRAME_DROP_RATE_THRESHOLD = 'optional_id_before_float_video_high_frame_drop_rate_threshold',

  /**
   * 若在OPTIONAL_ID_BEFORE_LONG_VIDEO_RENDER_MONITOR_PERIOD_MS时间内视频帧率低于该阈值
   * 则通过oninfo中的TP_PLAYER_INFO_LONG2_VIDEO_LOW_FRAMERATE进行通知。
   * 取值[0.0f, FLOAT_MAX]，
   * 默认值：0.0f，即不进行通知。fps
   */
  OPTIONAL_ID_BEFORE_FLOAT_VIDEO_LOW_FRAMERATE_THRESHOLD = 'optional_id_before_float_video_low_framerate_threshold',

  /**
   * audioTrack获取latency策略, 值参考TPAudioTrackGetLatencyStrategy
   * 默认值：2，仅在蓝牙场景下通过获取硬件层latency的方式计算audioTrack的latency
   */
  OPTIONAL_ID_BEFORE_INT_AUDIOTRACK_GET_LATENCY_STRATEGY = 'optional_id_before_int_audiotrack_get_latency_strategy',

  // Render相关配置

  /**
   * 是否开启硬解出数据模式（Buffer模式），开启后解码器输出CPU可访问的帧数据而非Surface直渲。
   * 用于TRTC播片场景，使解码帧可通过回调送给TRTC进行推流。
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_MEDIACODEC_OUTPUT_DATA = 'optional_id_before_bool_enable_mediacodec_output_data',

  /**
   * 是否开启视频解码帧回调
   * {@link IOnVideoFrameOutCallback}回调
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_VIDEO_FRAME_CALLBACK = 'optional_id_before_bool_enable_video_frame_callback',

  /**
   * 是否开启音频解码帧回调
   * {@link IOnAudioFrameOutCallback}回调
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AUDIO_FRAME_CALLBACK = 'optional_id_before_bool_enable_audio_frame_callback',

  /**
   * 音频渲染类型列表，数组类型{@link TPAudioRendererType}，默认不填写，交由内部决策
   * 默认值：空，内部决策
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_AUDIO_RENDERER_TYPE = 'optional_id_before_queue_int_audio_renderer_type',

  /*
   * 视频渲染类型列表，数组类型{@link TPRendererType}，默认不填写 交由内部决策
   * 默认值：空，内部决策
   */
  OPTIONAL_ID_BEFORE_QUEUE_INT_VIDEO_RENDERER_TYPE = 'optional_id_before_queue_int_video_renderer_type',

  /**
   * 音频渲染线程优先级，取值参考:{@link TPThreadPriority}
   * 默认值：TP_THREAD_PRIORITY_DEFAULT，继承自父线程优先级
   */
  OPTIONAL_ID_BEFORE_INT_AUDIO_RENDERER_THREAD_PRIORITY = 'optional_id_before_int_audio_renderer_thread_priority',

  /**
   * 外挂字幕的输出方式，取值参考 {@link TPSubtitleDataType}
   * 默认值：TP_SUBTITLE_DATA_TYPE_TEXT，字符串输出
   */
  OPTIONAL_ID_BEFORE_INT_OUT_SUBTITLE_DATA_TYPE = 'optional_id_before_int_out_subtitle_data_type',

  /**
   * 是否回调字幕数据. 控制是否通过
   * {@link IOnSubtitleDataOutCallback#onSubtitleDataOut(ITPPlayer, TPSubtitleData)}回调字幕数据
   * 默认值：false 不回调
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_SUBTITLE_DATA_CALLBACK = 'optional_id_before_bool_enable_subtitle_data_callback',

  /**
   * 是否启用后处理调节音量
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AUDIO_VOLUME_BY_POSTPROCESS = 'optional_id_before_bool_enable_audio_volume_by_postprocess',

  /**
   * 是否开启自适应帧率
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_VIDEO_ADAPTIVE_FRAMERATE = 'optional_id_before_bool_enable_video_adaptive_framerate',

  /**
   * 是否使能audioTrack write卡死应变方案
   * 默认值: false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AUDIO_TRACK_WRITE_STUCK_FALLBACK = 'optional_id_before_bool_enable_audio_track_write_stuck_fallback',

  /**
   * 是否打开音频倍数强制处理
   * 默认值: false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_AUDIO_SPEED_FORCE_PROCESS = 'optional_id_before_bool_enable_audio_speed_force_process',

  /**
   * 设置avs3 audio（audio vivid）音频渲染引擎的HOA阶数，默认3阶，最高支持7阶
   */
  OPTIONAL_ID_BEFORE_INT_AVS3_AUDIO_RENDER_HOA_ORDER = 'optional_id_before_int_avs3_audio_render_hoa_order',

  /**
   * audio渲染连续出错的上限值，达到该值时回抛oninfo
   * 则通过oninfo中的TP_ONINFO_ID_OBJ_AUDIO_RENDER_ERROR消息进行通知。
   * 默认值：100
   */
  OPTIONAL_ID_BEFORE_INT_AUDIO_RENDER_MAX_ERROR_COUNT = 'optional_id_before_int_audio_render_max_error_count',

  /**
   * 音频设备配置信息开关
   *  默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_PREFERRED_AUDIO_DEVICE_INFO = 'optional_id_before_bool_enable_preferred_audio_device_info',

  /**
   * HLS安全加固加解密KEY,通过thumbplayer透传到ffmpeg
   */
  OPTIONAL_ID_BEFORE_STRING_HLS_OVERLAY_KEY = 'optional_id_before_string_hls_overlay_key',

  /**
   * HLS安全加固加解密IV,通过thumbplayer透传到ffmpeg
   */
  OPTIONAL_ID_BEFORE_STRING_HLS_OVERLAY_IV = 'optional_id_before_string_hls_overlay_iv',

  /**
   * 附加信息
   */
  OPTIONAL_ID_BEFORE_STRING_V_INFO = 'optional_id_before_string_v_info',

  //下面这部分是GLOBAL的，播放过程中都可以设置

  /**
   * 设置杜比音频解码的输出reference level
   * 默认值：-17
   */
  OPTIONAL_ID_GLOBAL_LONG_DOLBY_OUTPUT_REFERENCE_LEVEL = 'optional_id_global_long_dolby_output_reference_level',

  /**
   * 设置跳过片尾的时间（区别于position，例如需要跳过最后一分钟的片尾，当前传输应该是 60 * 1000)，单位ms
   * 默认值：0，不跳过片尾，播放完整个视频
   */
  OPTIONAL_ID_GLOBAL_LONG_SKIP_END_TIME_MS = 'optional_id_global_long_skip_end_time_ms',

  /**
   * <p>若未设置有效render target，暂缓执行start，直到外部设置有效的render target</p>
   * <p>可避免Android等平台切前台继续播放时，需要重新传入新的render target，导致短暂的有声无画现象</p>
   * <p>会影响后台播放，若需要后台播放能力，不能设置该参数</p>
   * 默认：false
   */
  OPTIONAL_ID_GLOBAL_BOOL_PEND_START_UNTIL_VALID_RENDER_TARGET_SET = 'optional_id_global_bool_pend_start_until_valid_render_target_set',

  /**
   * 自适应清晰度切换设置可支持的bitrate的range范围下限, 默认不设下限, 单位bps.
   * 默认值：0，不设下限
   */
  OPTIONAL_ID_GLOBAL_LONG_ADAPTIVE_LIMIT_BITRATE_RANGE_MIN = 'optional_id_global_long_adaptive_limit_bitrate_range_min',

  /**
   * 自适应清晰度切换设置可支持的bitrate的range范围上限, 默认不设上限, 单位bps.
   * 默认值：0，不设上限
   */
  OPTIONAL_ID_GLOBAL_LONG_ADAPTIVE_LIMIT_BITRATE_RANGE_MAX = 'optional_id_global_long_adaptive_limit_bitrate_range_max',

  /**
   * 是否打开自适应清晰度切换开关 thumbPlayer内部进行清晰度自适应切换，目前仅支持标准嵌套m3u8资源
   * 默认：false
   */
  OPTIONAL_ID_GLOBAL_BOOL_ENABLE_ADAPTIVE_SWITCH_DEF = 'optional_id_global_bool_enable_adaptive_switch_def',

  /**
   * 是否打开从audio render发出的数据回抛到上层做后处理
   * 默认值：false
   */
  OPTIONAL_ID_GLOBAL_BOOL_ENABLE_AUDIO_POSTPROCESS_CALLBACK = 'optional_id_global_bool_enable_audio_postprocess_callback',

  /**
   * 字幕渲染参数{@link TPSubtitleRenderParams}
   */
  OPTIONAL_ID_GLOBAL_OBJECT_SUBTITLE_RENDER_PARAMS = 'optional_id_global_object_subtitle_render_params',

  /**
   * 是否打开下载组件建议码率回调开关, 如果不设置, 默认为关闭 回调建议码率 (单位为bps) 通过
   * {@link TPOnInfoID#TP_ONINFO_ID_LONG1_DOWNLOAD_NETWORK_SUGGEST_BITRATE}回调
   * 默认值：默认为关闭
   */
  OPTIONAL_ID_GLOBAL_BOOL_ENABLE_SUGGESTED_BITRATE_CALLBACK = 'optional_id_global_bool_enable_suggested_bitrate_callback',

  /**
   * MediaLabVR流的viewport字符串参数，欧拉角信息，以","隔开，分别是yaw,pitch,roll,x,y
   * yaw   : 围绕Z轴旋转的角度
   * pitch : 围绕Y轴旋转的角度
   * roll  : 围绕X轴旋转的角度
   * x     : FOV的横向弧度
   * y     : FOV的纵向弧度
   */
  OPTIONAL_ID_GLOBAL_STRING_MEDIALABVR_VIEWPORT = 'optional_id_global_string_medialabvr_viewport',

  /**
   * ffmpeg的filter gragh参数描述字符串例如：'stereotools=mode=lr>ms[ms];[ms]stereotools=delay=-20[out];[out]volume=volume=6dB'
   * 设置为空字符串则为关闭音效, 默认值为空字符，即关闭音效。
   */
  OPTIONAL_ID_GLOBAL_STRING_FFMPEG_AUDIO_FILTER_DESCRIPTION = 'optional_id_global_string_ffmpeg_audio_filter_description',

  /**
   * 缓冲过滤阈值，即小于该阈值的缓冲会被过滤掉
   * 默认值：100ms
   */
  OPTIONAL_ID_BEFORE_LONG_BUFFERING_FILTER_THRESHOLD_MS = 'optional_id_before_long_buffering_filter_threshold_ms',

  /**
   * 音频渲染器外部可选配置，设置的值参考 {@link TPAudioRenderConfig}
   * 默认值：空
   */
  OPTIONAL_ID_BEFORE_OBJECT_AUDIO_RENDER_CONFIG = 'optional_id_before_object_audio_render_config',

  //
  // 补充的 ID
  //

  /**
   * 数据缓冲区的最小缓冲大小，用总时长数量表示，单位毫秒
   * 默认值：6000ms
   */
  OPTIONAL_ID_BEFORE_LONG_BUFFER_PACKET_MIN_TOTAL_DURATION_MS = 'optional_id_before_long_buffer_packet_min_total_duration_ms',

  /**
   * 异常case下，允许缓冲区扩充的最大时长，单位ms
   * 默认值：40000ms
   */
  OPTIONAL_ID_BEFORE_LONG_BUFFER_PACKET_MAX_TOTAL_DURATION_MS = 'optional_id_before_long_buffer_packet_max_total_duration_ms',

  /**
   * 首次播放预加载数据大小，用总时长表示，单位毫秒
   * 默认值：200ms
   */
  OPTIONAL_ID_BEFORE_LONG_PRELOAD_PACKET_TOTAL_DURATION_MS = 'optional_id_before_long_preload_packet_total_duration_ms',

  /**
   * 缓冲区填满时间低于该值，表示网络很快，则提前结束缓冲，单位ms
   * 默认值：1000ms
   */
  OPTIONAL_ID_BEFORE_LONG_MIN_BUFFERING_TIME_MS = 'optional_id_before_long_min_buffering_time_ms',

  /**
   * 缓冲区填满时间高于该值，表示网络很慢，则提前结束缓冲，单位ms
   * 默认值：8000ms
   */
  OPTIONAL_ID_BEFORE_LONG_MAX_BUFFERING_TIME_MS = 'optional_id_before_long_max_buffering_time_ms',

  /**
   * TCP连接和读取超时时间，单位ms
   * 默认值：5000ms
   */
  OPTIONAL_ID_BEFORE_LONG_TCP_TIMEOUT_MS = 'optional_id_before_long_tcp_timeout_ms',

  /**
   * TCP连接和读取重试次数
   * 默认值：5
   */
  OPTIONAL_ID_BEFORE_INT_TCP_RETRY_COUNT = 'optional_id_before_int_tcp_retry_count',

  /**
   * HLS多Program时，根据设定的Program下标选择起播
   * 默认值：-1
   */
  OPTIONAL_ID_BEFORE_INT_HLS_PROGRAM_DEFAULT_PLAY_INDEX = 'optional_id_before_int_hls_program_default_play_index',

  /**
   * HLS多Program时，根据设定的Luma Samples选最优的Program进行起播
   * 默认值：-1
   */
  OPTIONAL_ID_BEFORE_INT_HLS_PROGRAM_PREFER_LUMASAMPLES = 'optional_id_before_int_hls_program_prefer_lumasamples',

  /**
   * HLS多Program时，根据设定的Bandwidth选最优的Program进行起播，单位bps
   * 默认值：-1
   */
  OPTIONAL_ID_BEFORE_LONG_HLS_PROGRAM_PREFER_BANDWIDTH = 'optional_id_before_long_hls_program_prefer_bandwidth',

  /**
   * 是否开启premium权限
   * 默认值：false
   */
  OPTIONAL_ID_BEFORE_BOOL_ENABLE_PREMIUM = 'optional_id_before_bool_enable_premium',

  /**
   * 外挂字幕的输出方式（int 版本，与 OUT_SUBTITLE_DATA_TYPE 等价），取值参考 {@link TPSubtitleOutputType}
   * 默认值：TP_SUBTITLE_OUTPUT_TEXT
   */
  OPTIONAL_ID_BEFORE_INT_SUBTITLE_OUTPUT_TYPE = 'optional_id_before_int_subtitle_output_type',
}
