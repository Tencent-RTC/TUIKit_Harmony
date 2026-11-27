/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放器的错误类型定义。
 * 在这些枚举定义中，
 * 数值[1, 100)部分为通用错误类型
 * 数值[100, 150)部分为Android平台通用错误类型
 * 数值[150, 200)部分为iOS平台通用错误类型
 * 数值[200, 250)部分为Windows平台通用错误类型
 * 数值[250, 1000)部分为以后其他平台预留
 * 数值[1000, 2000)部分是自研内核错误类型，跟native层(ITPPlayerMessageCallback#ErrorType)保持一致
 * 数值[2000, 2500)是Android MediaPlayer错误类型
 * 数值[2500, 3000)为iOS AVPlayer错误类型
 * 数值[3000, 3500)为Windows系统播放器错误类型
 * 数值[3500, 6000)为以后其他播放器的错误类型预留
 * 数值[6000, 6500)是下载组件错误码类型
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export const enum TPErrorType {
  /**
   * ThumbPlayer 未知错误类型
   */
  UNKNOWN = -1,

  /**
   * 自研内核通用错误类型
   */
  SELF_DEV_PLAYER_GENERAL = 1001,

  /**
   * 自研内核Demuxer通用错误类型
   */
  SELF_DEV_PLAYER_DEMUXER_GENERAL = 1100,

  /**
   * 自研内核Demuxer网络错误
   */
  SELF_DEV_PLAYER_DEMUXER_NETWORK = 1101,

  /**
   * 自研内核Demuxer解析时遇到码流数据错误
   */
  SELF_DEV_PLAYER_DEMUXER_STREAM = 1102,

  /**
   * Demuxer缓冲时间超过
   */
  SELF_DEV_PLAYER_DEMUXER_BUFFERING_TIMEOUT = 1103,

  /**
   * Demuxer预加载prepare超过
   */
  SELF_DEV_PLAYER_DEMUXER_PREPARE_TIMEOUT = 1104,

  /**
   * 自研内核Decoder通用错误类型
   */
  SELF_DEV_PLAYER_DECODER_GENERAL = 1200,

  /**
   * 自研内核Decoder不支持当前音频格式
   */
  SELF_DEV_PLAYER_DECODER_AUDIO_NOT_SUPPORT = 1210,

  /**
   * 自研内核Decoder解码音频数据有错误，无法解码
   */
  SELF_DEV_PLAYER_DECODER_AUDIO_STREAM = 1211,

  /**
   * 自研内核Decoder不支持当前视频格式
   */
  SELF_DEV_PLAYER_DECODER_VIDEO_NOT_SUPPORT = 1220,

  /**
   * 自研内核Decoder解码当前视频数据有错误，无法解码
   */
  SELF_DEV_PLAYER_DECODER_VIDEO_STREAM = 1221,

  /**
   * 自研内核Decoder当前字幕格式解码器不支持
   */
  SELF_DEV_PLAYER_DECODER_SUBTITLE_NOT_SUPPORT = 1230,

  /**
   * 自研内核Decoder当前字幕数据有错误，无法解码
   */
  SELF_DEV_PLAYER_DECODER_SUBTITLE_STREAM = 1231,

  /**
   * 自研内核Renderer通用错误类型
   */
  SELF_DEV_PLAYER_RENDERER_GENERAL = 1300,

  /**
   * 自研内核音频后处理通用错误类型
   */
  SELF_DEV_PLAYER_AUDIO_POSTPROCESS_GENERAL = 1500,

  /**
   * 自研内核视频后处理未知错误
   */
  SELF_DEV_PLAYER_VIDEO_POSTPROCESS_GENERAL = 1600,

  /**
   * 自研内核错误码类型到此为止
   */
  SELF_DEV_PLAYER_END = 1999,

  // TODO(karlyczhang, 2024/03/08): 鸿蒙系统播放器错误码类型待补充

  /**
   * 下载组件通用错误类型
   */
  DOWNLOAD_PROXY_GENERAL = 6000,

  /**
   * 下载组件错误类型到此为止
   */
  DOWNLOAD_PROXY_END = 6499,
}
