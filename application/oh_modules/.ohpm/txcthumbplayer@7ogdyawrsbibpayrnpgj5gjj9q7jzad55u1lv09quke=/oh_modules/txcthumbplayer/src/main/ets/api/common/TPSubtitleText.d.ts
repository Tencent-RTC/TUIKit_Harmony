/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Subtitle Player Core Group Agreement.
 */

import { TPSubtitleData } from "./TPSubtitleData";

/**
 * 字幕文本，用于字幕输出文本
 *
 * @author jiesonchen
 * @date 2024-05-08
 */
export interface TPSubtitleText extends TPSubtitleData {
  /**
   * 字幕文本字符串，utf-8编码。
   * 对于同一路字幕，如果一个时间点同时命中了两段字幕文本，也是一个一个输出。
   * 对于选择了多路字幕的情况，多个轨道按照选择顺序依次输出
   */
  readonly text: string;

  /**
   * 当前输出的字幕的轨道id，该轨道id即{@link ITPPlayer#getTrackInfo()}返回的数组下标。
   */
  readonly trackID: number;
}
