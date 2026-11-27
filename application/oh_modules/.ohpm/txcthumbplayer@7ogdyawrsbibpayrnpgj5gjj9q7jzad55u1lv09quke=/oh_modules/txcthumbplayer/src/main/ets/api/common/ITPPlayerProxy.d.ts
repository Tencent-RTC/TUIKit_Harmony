/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import {ITPPlayer} from "../player/ITPPlayer";

/**
 * 播放器实例代理接口
 * 业务方通过调用setTPPlayerProxy设置该代理接口，实现对createTPPlayer创建的所有播放实例进行代理
 * 可用于hook播放器接口的调用，获取播放器运行态信息
 *
 * @author davidgeng
 * @date 2024/06/27
 */
export interface ITPPlayerProxy {
  /**
   * 创建播放器代理实例
   *
   * @param player 播放器实例. 注意: 该变量有可能为空，实现代理时需要处理该case，建议返回null
   * @return ITPPlayer 代理后的播放器实例
   */
  createProxyInstance(player: ITPPlayer): ITPPlayer;
}
