/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 字幕的codec定义, 与内核层TPCodec.h中数值定义一致
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPSubtitleCodecType {
  /**
   * 表示未知编码类型
   */
  UNKNOWN = -1,

  // 字幕的codec 定义区，与内核层数值一致，TPSubtitleCodecType.XXX表示字幕XXX编码类型
  DVD_SUBTITLE = 6000,
  DVB_SUBTITLE = 6001,
  TEXT = 6002,  ///< raw UTF-8 text
  XSUB = 6003,
  SSA = 6004,
  MOV_TEXT = 6005,
  HDMV_PGS_SUBTITLE = 6006,
  DVB_TELETEXT = 6007,
  SRT = 6008,

  MICRODVD = 6800,
  EIA_608 = 6801,
  JACOSUB = 6802,
  SAMI = 6803,
  REALTEXT = 6804,
  STL = 6805,
  SUBVIEWER1 = 6806,
  SUBVIEWER = 6807,
  SUBRIP = 6808,
  WEBVTT = 6809,
  MPL2 = 6810,
  VPLAYER = 6811,
  PJS = 6812,
  ASS = 6813,
  HDMV_TEXT_SUBTITLE = 6814,
  TTML = 6815,
}
