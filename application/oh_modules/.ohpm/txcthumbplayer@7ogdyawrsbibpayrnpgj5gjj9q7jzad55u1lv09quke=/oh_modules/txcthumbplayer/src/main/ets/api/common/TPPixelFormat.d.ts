/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 视频pixel format定义， 枚举值必须和native层保持一致
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export const enum TPPixelFormat {
  /**
   * 未知类型
   */
  TP_PIXEL_FORMAT_UNKNOWN = -1,
  /**
   * planar YUV 4:2:0, 12bpp, (1 Cr & Cb sample per 2x2 Y samples)
   */
  TP_PIXEL_FORMAT_YUV420P = 0,
  /**
   * planar YUV 4:2:0, 12bpp, full scale (JPEG), deprecated in favor of TP_PIX_FMT_YUV420P and setting color_range
   */
  TP_PIXEL_FORMAT_YUVJ420P = 12,
  /**
   * packed RGBA 8:8:8:8, 32bpp, RGBARGBA.
   */
  TP_PIXEL_FORMAT_RGBA = 26,
  /**
   * packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), little-endian.
   */
  TP_PIXEL_FORMAT_RGB565 = 37,
  /**
   * hardware decoding through MediaCodec
   */
  TP_PIXEL_FORMAT_MEDIACODEC = 167,
}
