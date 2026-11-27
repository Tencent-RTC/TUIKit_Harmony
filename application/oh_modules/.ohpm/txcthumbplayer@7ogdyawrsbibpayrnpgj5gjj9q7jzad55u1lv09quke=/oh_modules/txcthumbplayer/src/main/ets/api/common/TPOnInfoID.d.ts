/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * onInfoID
 * 播放器onInfo回调的消息定义
 * 必须写明触发OnInfo回调的时机
 * 必须写明OnInfo回调数据TPOnInfoParam中的参数、含义及类型，若没有回调数据则写"无"
 * 重构前后变更：https://iwiki.woa.com/pages/viewpage.action?pageId=4007279229
 *
 * 命名格式：
 * 消息参数类型_名称
 * 其中消息参数类型有：
 * 1.VOID    表示不携带参数
 * 2.LONG1   表示使用64位整型参数1         LONG2   表示使用64位整型参数1和2
 * 3.FLOAT1  表示使用浮点型参数1           FLOAT2  表示使用浮点型参数1和2
 * 4.STRING1 表示使用string型参数1          STRING2 表示使用string型参数1和2
 * 5.OBJ     表示使用object型扩展参数，OBJ类型参数可与2/3/4搭配使用
 * 例如：
 * VOID_FIRST_VIDEO_FRAME_RENDERED 表示收个视频帧渲染完成
 * LONG1_OBJ_SELECT_TRACK_ERROR 表示选轨失败，使用64位整型参数1和Object型扩展参数携带消息参数
 *
 *
 * 值定义区间：
 * 1、0～49999        内核层定义的OnInfo类型，与内核定义值一一对应
 * 2、50000～79999    平台层特定的OnInfo类型
 * 3、80000～99999    下载组件的OnInfo类型
 *
 * @author colinyzhang
 * @date 2024-03-08
 */

export const enum TPOnInfoID {
  /*
   * 未知类型
   * 参数无
   */
  VOID_UNKNOWN = -1,

  /*
   * 切换数据源成功完成
   * 切换数据源错误被认为是fatal类型，若出错，则通过IOnErrorCallback通知
   * 参数：
   * Long1   函数调用传入的opaque标识
   */
  LONG1_SWITCH_DATA_SOURCE_SUCCESS = 3,

  /*
   * 选择轨道执行成功
   * 参数：
   * Long1   函数调用传入的opaque标识
   */
  LONG1_SELECT_TRACK_SUCCESS = 10,

  /*
   * 选择轨道执行失败
   * 选择媒体轨道错误被认为是非fatal类型，所有通过该OnInfo消息通知
   * 参数：
   * Long1   函数调用传入的opaque标识
   * Object  TPError类型，error信息
   */
  LONG1_OBJ_SELECT_TRACK_ERROR = 11,

  /*
   * 取消选择轨道执行成功
   * 参数：
   * Long1   函数调用传入的opaque标识
   */
  LONG1_DESELECT_TRACK_SUCCESS = 12,

  /*
   * 取消选择轨道执行失败
   * 取消选择媒体轨道错误被认为是非fatal类型，所有通过该OnInfo消息通知
   * 参数：
   * Long1   函数调用传入的opaque标识
   * Object  TPError类型，error信息
   */
  LONG1_OBJ_DESELECT_TRACK_ERROR = 13,

  /*
   * 选择节目selectProgramAsync执行成功
   * 参数：
   * Long1   函数调用传入的opaque标识
   */
  LONG1_SELECT_PROGRAM_SUCCESS = 14,

  /*
   * 选择节目selectProgramAsync执行失败
   * 选择节目错误被认为是非fatal类型，所有通过该OnInfo消息通知
   * 参数：
   * Long1   函数调用传入的opaque标识
   * Object  TPError类型，error信息
   */
  LONG1_OBJ_SELECT_PROGRAM_ERROR = 15,

  /*
   * 播放开始事件
   * 首个clip打开
   * 参数无
   */
  VOID_FIRST_CLIP_OPENED = 101,

  /*
   * demuxer首次读到携带关键帧的数据包
   * 参数无
   */
  VOID_VIDEO_FIRST_KEY_PACKET_READ = 102,

  /*
   * 音频解码器首次打开
   * 参数无
   */
  VOID_FIRST_AUDIO_DECODER_START = 103,

  /*
   * 视频解码器首次打开
   * 参数无
   */
  VOID_FIRST_VIDEO_DECODER_START = 104,

  /*
   * 音频帧首次渲染
   * 参数无
   */
  VOID_FIRST_AUDIO_FRAME_RENDERED = 105,

  /*
   * 第一帧Video渲染完成
   * 参数无
   */
  VOID_FIRST_VIDEO_FRAME_RENDERED = 106,

  /*
   * demuxer首次读到数据包
   * 参数无
   */
  VOID_FIRST_PACKET_READ = 107,

  /*
   * 播放结束点事件
   * 循环播放时，新的循环开始
   * 参数无
   */
  VOID_CURRENT_LOOP_START = 150,

  /*
   * 循环播放时，当前循环结束
   * 参数无
   */
  VOID_CURRENT_LOOP_END = 151,

  /*
   * 开始一个新的clip播放
   * 参数：
   * Long1   clip序号
   */
  LONG1_CLIP_START = 152,

  /*
   * 当前clip播放结束
   * 参数：
   * Long1   clip序号
   */
  LONG1_CLIP_END = 153,

  /*
   * 缓冲开始
   * 参数无
   */
  VOID_BUFFERING_START = 200,

  /*
   * 缓冲结束
   * 参数无
   */
  VOID_BUFFERING_END = 201,

  /*
   * 音频解码器类型发生变化
   * 第一次创建解码器时触发
   * 播放过程中切换了解码器类型时触发
   * 参数：
   * Long1    变化后的解码器类型，TPDecoderType
   */
  LONG1_AUDIO_DECODER_TYPE_CHANGED = 203,

  /*
   * 视频解码器类型发生变化
   * 第一次创建解码器时触发
   * 播放过程中切换了解码器类型时触发
   * 参数：
   * Long1    变化后的解码器类型，TPDecoderType
   */
  LONG1_VIDEO_DECODER_TYPE_CHANGED = 204,

  /*
   * 音频passthrough模式开始
   * 参数无
   */
  VOID_AUDIO_PASSTHROUGH_START = 210,

  /*
   * 音频passthrough模式结束
   * 参数无
   */
  VOID_AUDIO_PASSTHROUGH_END = 211,

  /*
   * 音频AudioTrack的SessionId发生变化
   * 参数：
   * LONG1   变化后的SessionId
   */
  LONG1_AUDIO_TRACK_SESSION_ID_CHANGED = 212,

  /*
   * 自适应切换清晰度开始
   * 播放器内部每5s根据当前网络情况做一次码率检查，若发现更匹配的program码率，则进行清晰度切换并触发回调
   * 参数：
   * Long1   目标清晰度的programId
   */
  LONG1_ADAPTIVE_SWITCH_DEF_START = 251,

  /*
   * 自适应切换清晰度结束
   * 渲染器首次收到新清晰度program的帧时触发回调
   * 参数：
   * Long1   目标清晰度的programId
   */
  LONG1_ADAPTIVE_SWITCH_DEF_END = 252,

  /*
   * 字幕相关错误
   * 由于字幕错误不被认为fatal，所以通过oninfo回调出去
   * 参数：
   * Long1   对应轨道id
   * Object  TPError类型，error信息
   */
  LONG1_OBJ_SUBTITLE_ERROR = 254,

  /*
   * 视频丢帧率过高
   * 由于音画同步问题，播放器可能会丢弃部分帧，不渲染
   * 播放器每秒统计当前这一秒的丢帧率：渲染帧数/(渲染帧数+丢帧数)
   * 若高于TPOptionalID中设置的最高阈值，则触发回调
   * 参数：
   * Float1  丢帧率
   */
  FLOAT1_VIDEO_HIGH_FRAME_DROP_RATE = 255,

  /*
   * 视频帧率过低
   * 播放器每秒统计当前这一秒的帧率：渲染帧数/时长，
   * 若低于TPOptionalID中设置的最低阈值，则触发回调
   * 参数
   * Float1  帧率
   */
  FLOAT1_VIDEO_LOW_FRAME_RATE = 256,

  /*
   * MediaLabVR的延迟信息
   * 由MediaLabVR触发的延迟信息，单位ms
   * 参数
   * LONG1 延迟信息，毫秒
   */
  LONG1_MEDIA_LAB_VR_LATENCY_MS = 257,

  /*
   * 视频Hdr信息发生改变
   * 播放器渲染视频帧时，视频帧的hdr类型或hdr映射类型发生改变，通过此信息回调视频帧的hdr类型和hdr映射类型
   * 参数
   * Long1  hdr类型，详见TPHdrType
   * Long2  hdr映射类型，详见TPHdrMappingType
   */
  LONG2_VIDEO_HDR_INFO_CHANGED = 258,

  /*
   * 视频的Crop信息发生了变化
   * 需要对surface输出的视频内容进行进一步处理的应用场景需要考虑Crop信息。
   * 参数：
   * Object  TPVideoCropInfo类型，变化后的crop数据信息
   */
  OBJ_VIDEO_CROP_CHANGED = 500,

  /*
   * 读取到指定TPOptionalID的HLS私有标签
   * 参数：
   * String1 读取到的HLS私有标签内容
   */
  STRING1_PRIVATE_HLS_TAG = 501,

  /*
   * 读取到指定TPOptionalID的sei类型数据
   * 参数：
   * Object  TPSeiInfo类型，读取到的sei数据
   */
  OBJ_VIDEO_SEI = 503,

  /**
   * 当前播放片源的drm信息
   * 若当前播放的是drm片源，则在初始化解码器的时候回调media drm信息
   * 参数：
   * OBJECT  TPMediaDrmInfo类型，MediaDrm相关的一些信息
   */
  OBJ_MEDIA_DRM_INFO = 505,

  /*
   * 读取到WebVTT的OTE内容
   * 参数：
   * Long1   对应轨道id, 在GetTrackInfo中的index
   * String1 WebVTT的NOTE内容
   */
  LONG1_STRING1_SUBTITLE_NOTE = 506,

  /*
   * 解码器mediacodec已经准备就绪，
   * 播放器调用MediaCodec#start()后，进入executing状态时触发
   * 参数：
   * OBJECT  TPMediaCodecReadyInfo类型，MediaCodec ready消息
   */
  OBJ_MEDIA_CODEC_READY = 600,

  /*
   * 解码器mediacodec发生exception
   * 参数：
   * OBJECT  TPMediaCodecExceptionInfo类型，MediaCodec 异常消息
   */
  OBJ_MEDIA_CODEC_EXCEPTION = 601,

  /*
   * 更新非空渲染目标(即playerView(UIView/NSNiew)、surface或surfadeHolder)后的首帧视频渲染
   * 参数：无
   */
  VOID_FIRST_VIDEO_FRAME_RENDERED_AFTER_UPDATE_RENDER_TARGET = 602,

  /*
   * 播放器重启完成
   * 播放器重启过程可能较为耗时，可配合使用给予用户提示
   * 参数
   * Long1   重启前的播放器类型，TPPlayerCoreType
   * Long2   重启后的播放器类型，TPPlayerCoreType
   * Object  nullable，若重启由error触发，则为TPError类型
   */
  LONG2_OBJ_PLAYER_REBOOT_START = 50000,

  /*
   * 播放器重启完成(成功)
   * 播放器重启过程可能较为耗时，可配合使用给予用户提示
   * 参数无
   */
  VOID_PLAYER_REBOOT_END = 50001,

  /*
   * 播放器类型发生变化
   * 启播成功后触发
   * 播放器内部重启/切换成功后触发
   * 参数
   * Long1   播放器类型，TPPlayerCoreType
   */
  LONG1_PLAYER_TYPE_CHANGE = 50002,

  /*
   * 播放器对下载组件的使用发生变化
   * 执行启播时触发
   * 播放过程中下载组件出现故障，播放器重试不走下载组件而直连cdn地址时触发
   * 参数：
   * Long1   是否使用，0不使用，1使用
   */
  LONG1_IS_USE_DOWNLOAD_PROXY_CHANGE = 50003,

  /*
   * 系统播放器消息，通知上层系统播放器已可使用。在3D渲染等特殊场景，外部需要获取到系统播放器实例来实现功能。但系统播放器创建时机以及是否确定可用等信息外部无法感知。
   * 因此通过该消息通知依赖方系统播放器已可使用，并通过参数带出有效的系统播放器实例
   * 参数
   * Object  可被使用的AVPlayer实例
   */
  OBJ_SYSTEM_PLAYER_AVAILABLE = 50004,

  /*
   * 系统播放器消息，通知上层系统播放器将失效。在3D渲染等特殊场景，外部需要获取到系统播放器实例来实现功能，当播放器即失效时，需要通知使用方，以免继续操作一个失效的播放实例。
   * 因此通过该消息通知依赖方系统播放器失效，并通过参数带出失效的系统播放器实例
   * 参数
   * Object  失效的AVPlayer实例
   */
  OBJ_SYSTEM_PLAYER_UNAVAILABLE = 50005,

  /*
   * 传输组件上抛
   * 播放的视频数据全部下载完毕
   * 参数无
   */
  VOID_DOWNLOADED_ALL_FINISH = 80000,

  /*
   * 传输组件的下载进度发生变化
   * 每秒都会触发
   * 参数：
   * Object  TPDownloadProgressInfo类型，变化后的下载进度
   */
  OBJ_DOWNLOAD_PROGRESS_CHANGE = 80001,

  /*
   * 下载组件建议的码率
   * 需开启 TPOptionalID中建议码率
   * 当下载组件认为可以切换到更合适的码率的源时触发
   * 参数：
   * Long1   建议的码率，单位bps
   */
  LONG1_DOWNLOAD_NETWORK_SUGGEST_BITRATE = 80002,

  /*
   * 传输组件发生了错误，业务方收到该error不必报错，可等待播放器的报错
   * 参数
   * Object TPError类型，error信息
   */
  OBJ_DATA_TRANSPORT_ERROR = 80003,

  /*
   * 数据传输消息，该消息用来透传除了上述传输组件消息之外的其他消息
   * 参数
   * Long1 下载组件消息类型
   * Object 透传下载组件的消息参数对象
   */
  LONG1_OBJ_DATA_TRANSPORT_INFORMATION = 80100,
}
