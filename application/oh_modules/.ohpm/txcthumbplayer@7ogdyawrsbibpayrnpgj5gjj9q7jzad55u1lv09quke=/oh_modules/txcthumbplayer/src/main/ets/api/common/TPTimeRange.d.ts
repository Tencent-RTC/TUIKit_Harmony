/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 时间区间定义，用于指定媒体流的某一段时间
 *
 * @author harleyxwang
 * @date 2024/03/15
 */
export interface TPTimeRange {
  /**
   * 开始时间，单位为毫秒
   */
  startTimeMs: number;

  /**
   * 结束时间，单位为毫秒，值为-1则表示直到媒体流末尾
   */
  endTimeMs : number;
}
