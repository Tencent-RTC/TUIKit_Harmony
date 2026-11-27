/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * TP层AudioTrack获取latency策略的类型定义，枚举值与native层保持一致。
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPAudioTrackGetLatencyStrategy {
  /**
   * 通过调用audioTrack.getTimestamp的方式计算audioTrack的latency
   */
  GET_TIMESTAMP = 0,

  /**
   * 通过获取硬件层latency的方式计算audioTrack的latency
   */
  GET_HARDWARE_LATENCY = 1,

  /**
   * 仅在蓝牙场景下通过获取硬件层latency的方式计算audioTrack的latency
   */
  GET_HARDWARE_LATENCY_ONLY_BLUETOOTH = 2,
}
