/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Subtitle Player Core Group Agreement.
 */

import { TPSubtitleDataType } from "./TPSubtitleDataType";

/**
 * 字幕数据抽象类，{@link TPSubtitleFrameBuffer} 和 {@link TPSubtitleText}
 * 都继承于该类
 *
 * @author jiesonchen
 * @date 2024-05-08
 */
export interface TPSubtitleData {
  /**
   * 字幕数据类型
   */
  readonly dataType: TPSubtitleDataType;

  /**
   * 当前输出字幕的开始时间
   */
  readonly startTimeMs: number;
}
