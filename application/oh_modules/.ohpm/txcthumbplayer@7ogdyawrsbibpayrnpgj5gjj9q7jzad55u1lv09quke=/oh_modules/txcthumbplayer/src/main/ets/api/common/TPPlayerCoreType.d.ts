/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放器类型
 *
 * @author colinyzhang
 * @date 2024-03-08
 */

export const enum TPPlayerCoreType {
  /**
   * 未知
   */
  UNKNOWN = 0,
  /**
   * 自研播放器
   */
  SELF_DEV_PLAYER = 1,
  /**
   * 系统播放器 (AVPlayer)
   */
  HARMONY_OS_AV_PLAYER = 5
}
