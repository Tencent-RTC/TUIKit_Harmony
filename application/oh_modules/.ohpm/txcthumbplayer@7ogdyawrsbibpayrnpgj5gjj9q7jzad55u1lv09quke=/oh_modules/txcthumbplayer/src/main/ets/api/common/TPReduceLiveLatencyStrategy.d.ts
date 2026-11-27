/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 降低直播延迟策略
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPReduceLiveLatencyStrategy {
  /**
   * 不采取任何措施
   */
  NONE = 0,

  /**
   * 通过加速播放来降低延迟
   */
  SPEED_UP = 1,

  /**
   * 通过丢帧来降低延迟
   */
  SKIP_FRAME = 2,
}
