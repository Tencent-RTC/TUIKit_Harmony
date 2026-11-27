/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放器属性id
 *
 * @author colinyzhang
 * @date 2024-03-11
 */

export const enum TPPropertyID {
  /**
   * 音频的codec ID
   */
  LONG_AUDIO_CODEC_TYPE = 'tp_property_id_long_audio_codec_type',
  /**
   * 音频的码率，单位bps
   */
  LONG_AUDIO_BITRATE = 'tp_property_id_long_audio_bitrate',
  /**
   * 音频的编码profile
   */
  LONG_AUDIO_CODEC_PROFILE = 'tp_property_id_long_audio_codec_profile',
  /**
   * 音频的通道数
   */
  LONG_AUDIO_CHANNEL_COUNT = 'tp_property_id_long_audio_channel_count',
  /**
   * 音频的session id, id >0为合法值
   */
  LONG_AUDIO_SESSION_ID = 'tp_property_id_long_audio_session_id',
  /**
   * 音频采样率
   */
  LONG_AUDIO_SAMPLE_RATE = 'tp_property_id_long_audio_sample_rate',
  /**
   * 视频的codec id
   */
  LONG_VIDEO_CODEC_TYPE = 'tp_property_id_long_video_codec_type',
  /**
   * 视频的码率，单位bps
   */
  LONG_VIDEO_BITRATE = 'tp_property_id_long_video_bitrate',
  /**
   * 视频的profile
   */
  LONG_VIDEO_CODEC_PROFILE = 'tp_property_id_long_video_codec_profile',
  /**
   * 视频的画面旋转角度
   */
  LONG_VIDEO_ROTATION = 'tp_property_id_long_video_rotation',
  /**
   * 视频的帧率
   */
  FLOAT_VIDEO_FRAME_RATE = 'tp_property_id_float_video_framerate',
  /**
   * 视频的颜色空间
   */
  LONG_VIDEO_COLOR_SPACE = 'tp_property_id_long_video_color_space',
  /**
   * 视频解码的帧数
   */
  LONG_VIDEO_DECODE_FRAME_COUNT = 'tp_property_id_long_video_decode_frame_count',
  /**
   *  视频解码的总耗时，单位us
   */
  LONG_VIDEO_DECODE_TOTAL_COST_US = 'tp_property_id_long_video_decode_total_cost_us',
  /**
   * 视频渲染的帧数
   */
  LONG_VIDEO_RENDER_FRAME_COUNT = 'tp_property_id_long_video_render_frame_count',
  /**
   *  视频渲染的总耗时，单位us
   */
  LONG_VIDEO_RENDER_TOTAL_COST_US = 'tp_property_id_long_video_render_total_cost_us',
  /**
   * 字幕的codec id
   */
  LONG_SUBTITLE_CODEC_TYPE = 'tp_property_id_long_subtitle_codec_type',
  /**
   * 内核播放器实例的内存地址
   */
  LONG_PLAYER_MEM_ADDRESS = 'tp_property_id_long_player_mem_address',
  /**
   * 音频的container format
   */
  STRING_CONTAINER_FORMAT = 'tp_property_id_string_container_format'
}
