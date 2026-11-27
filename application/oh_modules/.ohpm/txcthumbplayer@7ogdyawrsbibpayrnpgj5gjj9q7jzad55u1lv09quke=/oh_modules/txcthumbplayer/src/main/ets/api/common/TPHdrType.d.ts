/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 *  hdr类型 定义区，必须与native层(tp2_hdr_type.h)保持一致
 *
 * @author karlyczhang
 * @date 2024/03/06
 */
export const enum TPHdrType {
  /**
   * 非hdr类型
   */
  NONE = -1,

  /**
   * hdr10
   */
  HDR10 = 0,

  /**
   * hdr10+
   */
  HDR10PLUS = 1,

  /**
   * dolby vision
   */
  DOLBYVISION = 2,

  /**
   * HLG
   */
  HLG = 3,

  /**
   * HDR Vivid
   */
  HDRVIVID = 4,
}
