/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * demuxer缓冲策略枚举定义，其值必须和native层(tp_buffer_strategy_defs.h)保持一致
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPBufferStrategy {
  /**
   * 自动模式，由内部自己决策
   */
  AUTO = -1,

  /**
   * 禁用缓冲
   */
  DISABLED = 0,

  /**
   * 正常缓冲大小，即固定缓冲区大小
   */
  NORMAL = 1,

  /**
   * 动态修改缓冲区大小
   */
  JITTER = 2,
}
