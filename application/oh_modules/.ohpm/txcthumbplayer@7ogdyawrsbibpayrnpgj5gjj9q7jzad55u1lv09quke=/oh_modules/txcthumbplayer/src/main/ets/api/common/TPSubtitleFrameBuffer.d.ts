/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Subtitle Player Core Group Agreement.
 */

import { TPPixelFormat } from "./TPPixelFormat";
import { TPSubtitleData } from "./TPSubtitleData";

/**
 * 字幕帧数据
 *
 * @author jiesonchen
 * @date 2024-05-08
 */
export interface TPSubtitleFrameBuffer extends TPSubtitleData {
  /**
   * 字幕frame的数据
   * 目前仅支持RGBA，data[0]存放图片数据，lineSize[0]为数据size，
   * 如果某个时间段所选择的每路字幕轨都没有字幕，则data[0]返回完全透明的空白图片。
   * 如果选择了多路，会合成为一张图片
   */
  readonly data: Uint8Array[];

  /**
   * 数据size，lineSize[0]对应的是data[0]的size，lineSize[1]对应data[1]的size，依此类推。
   * lineSize的长度视格式而定，因目前仅支持RGBA，所以只用到lineSize[0]
   */
  readonly lineSize: number[];

  /**
   * 字幕frame的格式, 目前仅支持{@link TPPixelFormat#TP_PIXEL_FORMAT_RGBA}
   */
  readonly format: TPPixelFormat;

  /**
   * 字幕frame的原始宽度
   */
  readonly width: number;

  /**
   * 字幕frame的原始高度
   */
  readonly height: number;

  /**
   * 字幕frame的旋转角度，取值为0、90、180、270
   */
  readonly rotation: number;

  /**
   * 字幕frame的显示宽
   */
  readonly displayWidth: number;

  /**
   * 字幕frame的显示高
   */
  readonly displayHeight: number;

  /**
   * 当前输出的字幕的轨道id列表，该轨道id即{@link ITPPlayer#getTrackInfo()}返回的数组下标。
   */
  readonly trackIDs: number[];
}
