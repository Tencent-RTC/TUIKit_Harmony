/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * AudioStreamUsage场景定义，不设置默认为MOVIE，必须与native层(tp2_audio_render_config.h)保持一致
 *
 * @author fantsyzhang
 * @date 2024/08/22
 */
export const enum TPAudioStreamUsage {
  UNKNOWN = 0,
  /**
   * 视频/电影场景
   */
  MOVIE = 1,
  /**
   * 音乐场景
   */
  MUSIC = 2,
  /**
   * 游戏场景
   */
  GAME = 3,
  /**
   * 闹钟
   */
  ALARM = 4,
  /**
   * 通知
   */
  NOTIFICATION = 5,
  /**
   * 语音通话
   */
  VOICECOMMUNICATION = 6,
  /**
   * 语音播报
   */
  ASSISTANT = 7,
}
