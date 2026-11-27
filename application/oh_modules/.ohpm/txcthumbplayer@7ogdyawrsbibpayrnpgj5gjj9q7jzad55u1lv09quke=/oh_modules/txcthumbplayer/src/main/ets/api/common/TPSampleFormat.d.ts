/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 音频sample format定义，这些枚举的定义必须与内核保持一致
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export const enum TPSampleFormat {
  /**
   * undefined
   */
  TP_SAMPLE_FORMAT_UNKNOWN = -1,
  /**
   * unsigned 8 bits.
   */
  TP_SAMPLE_FORMAT_U8 = 0,
  /**
   * signed 16 bits
   */
  TP_SAMPLE_FORMAT_S16 = 1,
  /**
   * signed 32 bits
   */
  TP_SAMPLE_FORMAT_S32 = 2,
  /**
   * float
   */
  TP_SAMPLE_FORMAT_FLT = 3,
  /**
   * double
   */
  TP_SAMPLE_FORMAT_DBL = 4,
  /**
   * unsigned 8 bits, planar
   */
  TP_SAMPLE_FORMAT_U8P = 5,
  /**
   * signed 16 bits, planar
   */
  TP_SAMPLE_FORMAT_S16P = 6,
  /**
   * signed 32 bits, planar
   */
  TP_SAMPLE_FORMAT_S32P = 7,
  /**
   * float, planar
   */
  TP_SAMPLE_FORMAT_FLTP = 8,
  /**
   * double, planar
   */
  TP_SAMPLE_FORMAT_DBLP = 9,
  /**
   * signed 64 bits
   */
  TP_SAMPLE_FORMAT_S64 = 10,
  /**
   * signed 64 bits, planar
   */
  TP_SAMPLE_FORMAT_S64P = 11,
}
