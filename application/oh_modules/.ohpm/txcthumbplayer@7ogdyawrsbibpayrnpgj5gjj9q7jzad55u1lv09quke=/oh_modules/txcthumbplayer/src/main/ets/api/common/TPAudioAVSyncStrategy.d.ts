/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 音频同步策略枚举定义，与内核层数值定义一致
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPAudioAVSyncStrategy {
  /**
   *  默认模式, 同步sleep
   */
  NORMAL = 0,

  /**
   * 持续FreeRun模式, audio不做sleep, 但其pts参与同步更新clock
   */
  FREERUN = 1,

  /**
   * 自动调整模式, 根据音频缓冲数据大小来决定采用何种策略。
   * 当音频渲染缓冲区内数据小于最小缓冲阈值（各渲染器最小缓冲阈值不一样，内部设定，外面不可配）时, 走FreeRun模式，但audio既不做sleep，其pts也不参与更新clock。
   * 当音频渲染缓冲区内数据大于等于最小缓冲阈值时，走TPAudioAVSyncStrategyNormal模式。
   */
  ADAPTIVE = 2,
}
