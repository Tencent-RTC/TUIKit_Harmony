/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放源切换模式
 *
 * @author colinyzhang
 * @date 2024-03-11
 */

export const enum TPSwitchDataSourceMode {
  /**
   * 数据源切换时, 采用默认值, 由播放器内核选择keep no buffering
   */
  DEFAULT = 0,
  /**
   * 数据源切换时，清空当前的buffer，立即切换到新的数据源，比如直播场景。
   */
  IMMEDIATELY = 1,
  /**
   * 数据源切换时，在保证切换后不卡顿的情况下，快速切换到新的数据源。
   */
  FAST_WITH_KEEP_NO_BUFFERING = 2,
  /**
   * 数据源切换时，必须耗费完已经缓存的所有数据后，才能切换到新的数据源。
   */
  AFTER_ALL_BUFFERED_DATA_CONSUMED = 3,
}
