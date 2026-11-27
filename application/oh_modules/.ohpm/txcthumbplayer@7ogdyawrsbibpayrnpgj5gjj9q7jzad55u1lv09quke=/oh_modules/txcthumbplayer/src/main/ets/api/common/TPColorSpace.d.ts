/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 颜色空间定义，枚举值必须和native层(TPPixelFormat.h)保持一致
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPColorSpace {
  /**
   * order of coefficients is actually GBR, also IEC 61966-2-1 (sRGB)
   */
  RGB = 0,

  /**
   * also ITU-R BT1361 / IEC 61966-2-4 xvYCC709 / SMPTE RP177 Annex B
   */
  BT709 = 1,

  /**
   * UNSPECIFIED
   */
  UNSPECIFIED = 2,

  /**
   * RESERVED
   */
  RESERVED = 3,

  /**
   * FCC Title 47 Code of Federal Regulations 73.682 (a)(20)
   */
  FCC = 4,

  /**
   * also ITU-R BT601-6 625 / ITU-R BT1358 625 / ITU-R BT1700 625 PAL & SECAM / IEC 61966-2-4 xvYCC601
   */
  BT470BG = 5,

  /**
   * also ITU-R BT601-6 525 / ITU-R BT1358 525 / ITU-R BT1700 NTSC
   */
  SMPTE170M = 6,

  /**
   * functionally identical to above
   */
  SMPTE240M = 7,

  /**
   * Used by Dirac / VC-2 and H.264 FRext, see ITU-T SG16 , TP_COL_SPC_YCOCG is the same
   */
  YCGCO = 8,

  /**
   * ITU-R BT2020 non-constant luminance system
   */
  BT2020_NCL = 9,

  /**
   * ITU-R BT2020 constant luminance system
   */
  BT2020_CL = 10,

  /**
   SMPTE 2085, Y'D'zD'x
   */
  SMPTE2085 = 11,

  /**
   * Chromaticity-derived non-constant luminance system
   */
  CHROMA_DERIVED_NCL = 12,

  /**
   * Chromaticity-derived constant luminance system
   */
  CHROMA_DERIVED_CL = 13,

  /**
   * ITU-R BT.2100-0, ICtCp
   */
  ICTCP = 14,
}
