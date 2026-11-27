/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 视频的解码器类型定义，与内核层数值定义一致
 *
 * @author harleyxwang
 * @date 2024/03/06
 */
export const enum TPVideoDecoderType {
  /**
   * 未知解码器
   */
  TP_VIDEO_DECODER_UNKNOWN = -1,
  /**
   * 软件解码器,FFmpeg video decoder
   */
  TP_VIDEO_DECODER_FFMPEG = 101,
  /**
   * Standalone video decoder
   */
  TP_VIDEO_DECODER_STANDALONE = 104,
  /**
   * Harmony video decoder
   */
  TP_VIDEO_DECODER_OHAVCODEC = 107,
}
