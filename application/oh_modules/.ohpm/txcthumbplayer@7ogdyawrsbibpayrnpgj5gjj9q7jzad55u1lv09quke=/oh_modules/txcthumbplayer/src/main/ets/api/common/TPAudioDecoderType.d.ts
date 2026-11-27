/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 音频的解码器类型定义,与内核层数值定义一致
 *
 * @author harleyxwang
 * @date 2024/03/06
 */
export const enum TPAudioDecoderType {
  /**
   * 未知解码器
   */
  TP_AUDIO_DECODER_UNKNOWN = -1,
  /**
   * FFmpeg audio decoder
   */
  TP_AUDIO_DECODER_FFMPEG = 1,
  /**
   * Android dolby audio decoder
   */
  TP_AUDIO_DECODER_DOLBY = 4,
  /**
   * Standalone audio decoder
   */
  TP_AUDIO_DECODER_STANDALONE = 5,
  /**
   * Harmony audio decoder
   */
  TP_AUDIO_DECODER_OHAVCODEC = 6,
}
