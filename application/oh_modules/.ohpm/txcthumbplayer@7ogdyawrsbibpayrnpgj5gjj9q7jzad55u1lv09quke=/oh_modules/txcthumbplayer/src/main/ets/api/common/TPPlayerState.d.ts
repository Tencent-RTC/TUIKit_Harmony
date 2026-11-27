/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放器状态
 *
 * @author colinyzhang
 * @date 2024-03-08
 */

export const enum TPPlayerState {
  /**
   * 空闲状态
   */
  IDLE = 0,
  /**
   * 已初始化
   */
  INITIALIZED = 1,
  /**
   * 加载资源中
   */
  PREPARING = 2,
  /**
   * 准备就绪
   */
  PREPARED = 3,
  /**
   * 开始播放
   */
  STARTED = 4,
  /**
   * 暂停
   */
  PAUSED = 5,
  /**
   * 播放完成
   */
  COMPLETE = 6,
  /**
   * 停止中
   */
  STOPPING = 7,
  /**
   * 结束播放
   */
  STOPPED = 8,
  /**
   * 错误状态
   */
  ERROR = 9,
  /**
   * 释放状态
   */
  RELEASED = 10
}
