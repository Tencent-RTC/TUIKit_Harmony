/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * seek模式
 *
 * @author colinyzhang
 * @date 2024-03-11
 */

export const enum TPSeekMode {
  /**
   * 默认
   */
  DEFAULT = 0,
  /**
   * 如果目标位置是一个关键帧，则直接seek到目标位置。否则，seek到离目标位置最近的上一个关键帧。
   */
  PREVIOUS_KEY_FRAME = 1,
  /**
   * 如果目标位置是一个关键帧，则直接seek到目标位置。否则，seek到离目标位置最近的下一个关键帧。
   */
  NEXT_KEY_FRAME = 2,
  /**
   * 精准seek，即使目标位置不是一个关键帧，也通过丢帧的方式Seek到目标位置，相对比较耗时
   */
  ACCURATE_POSITION = 3,
  /**
   * 适用于data source包含多个clip的情况，跳到下一个clip。
   */
  NEXT_CLIP = 4,
}
