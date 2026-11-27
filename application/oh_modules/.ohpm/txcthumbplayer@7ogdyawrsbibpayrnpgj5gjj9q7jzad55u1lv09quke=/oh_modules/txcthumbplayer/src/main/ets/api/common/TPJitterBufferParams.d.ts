/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * JitterBuffer配置项，使用方式可参考：
 * https://iwiki.woa.com/pages/viewpage.action?pageId=847912025
 *
 * @author karlyczhang
 * @date 2024/03/13
 */
export class TPJitterBufferParams {
  /** 允许下调高水位阈值的最小时长，低于此值将不再下调，单位ms */
  minDecreaseDurationMs: number;

  /** 允许上调高水位阈值的最小时长，高于此值将不再上调，单位ms */
  maxIncreaseDurationMs: number;

  /** 每次上调高水位阈值的时长，单位ms */
  perIncreaseDurationMs: number;

  /** 每次下调高水位阈值的时长，单位ms */
  perDecreaseDurationMs: number;

  /** 调整高水位阈值的时间间隔，防止频繁调整，单位ms */
  adjustIntervalThresholdMs: number;

  /** 读包卡顿认定时长，超过则需要调整高水位阈值，单位ms */
  frozenThresholdMs: number;
}
