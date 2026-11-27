/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAsset } from '../asset/ITPMediaAsset'

/**
 * ITPMediaAssetRequest用于播放器向调用方请求资源更新的情况，配合{@link ITPPlayerListener.IOnMediaAssetExpireListener}一起使用。
 * 播放器通过ITPMediaAssetExpireListener向外回调时，会携带一个ITPMediaAssetRequest实例，调用方更新完资源后，
 * 通过该ITPMediaAssetRequest实例向播放器传递一个新的asset。
 *
 * @author harleyxwang
 * @date 2024/03/11
 */
export interface ITPMediaAssetRequest {
  /**
   * 更新asset，调用方通过该方法向播放器更新asset
   *
   * @param asset ITPMediaAsset实例
   */
  updateMediaAsset(asset: ITPMediaAsset): void;
}
