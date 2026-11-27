/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPOptionalParam } from '../optionalparam/TPOptionalParam'

/**
 * 播放器构建参数
 * 播放器内核类型选择列表, 自研播放器内核类型或者系统播放器内核类型，取值参考TPPlayerCoreType中播放器内核类型定义
 * 设置后，ITPPlayer.stop()调用后，仍然是同一个播放会话（生命周期），并不会重新或者重置播放器内核类型选择策略，
 * 会保持为当前的播放器内核类型。
 * 举例，设置播放器内核类型策略为[TPPlayerCoreType.SELF_DEV_PLAYER, TPPlayerCoreType.HARMONY_OS_AV_PLAYER]
 * a) 如果ITPPlayer.stop调用时，播放器没有发生内核类型切换，当前播放器内核类型为自研播放器内核类型，后面重新
 *   ITPPlayer.prepare后，播放器内核类型仍然是自研播放器，中间发生错误时，仍然会切到系统播放器内核类型进行重试。
 * b) 如果ITPPlayer.stop调用时，播放器已经发生了内核类型切换，从自研播放器内核已经切到了系统播放器内核类型，则后面重新
 *   ITPPlayer.prepare后，播放器内核类型会是当前正在使用的播放器内核类型：系统播放器内核类型，再次发生错误时，
 *   将会直接报错。
 * 在ITPPlayer.reset后，会重置播放器内核类型列表为构造时传入的列表。可以认为是以初始传入的playerCoreTypes重新
 * 构造的播放器。默认值：内部决策, 默认优先只使用自研播放器内核
 *
 * @author colinyzhang
 * @date 2024/3/12
 */

export const TP_PLAYER_CONSTRUCT_ID_QUEUE_INT_CORE_TYPE = 'construct_id_queue_int_core_type';

export class TPPlayerConstructParams {
  /**
   * 添加构造播放器的可选参数。参数的key限定为TP_PLAYER_CONSTRUCT_ID_QUEUE_INT_CORE_TYPE
   *
   * @param optionalParam 可选参数
   */
  addOptionalParam(optionalParam: TPOptionalParam): void;

  /**
   * 获取已经添加的播放器的可选参数。
   *
   * @return 可选参数列表
   */
  getOptionalParams(): TPOptionalParam[];
}
