/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMultiMediaAsset } from './ITPMultiMediaAsset';
import { ITPUrlMediaAsset } from './ITPUrlMediaAsset';
import { TPDrmType } from '../common/TPDrmType';
import { ITPDrmMediaAsset } from './ITPDrmMediaAsset';
import { ITPMediaAssetParamMap } from './ITPMediaAssetParamMap';
import { ITPFdMediaAsset } from './ITPFdMediaAsset';
import { ITPSimulatedLiveMediaAsset, ITPSimulatedLiveCallback } from './ITPSimulatedLiveMediaAsset';
import { ITPMediaAsset } from './ITPMediaAsset';
import { ITPRtcMediaAsset } from './ITPRtcMediaAsset';

/**
 * asset创建工厂
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

export class TPMediaAssetFactory {
  /**
   * 创建url播放媒体资源
   * @param url 播放地址
   * @return {@link TPUrlMediaAsset}
   */
  static createUrlMediaAsset(url: string): ITPUrlMediaAsset;

  /**
   * 创建fd播放媒体资源
   * @param fd 本地文件句柄
   * @param offset 数据偏移量
   * @param length 资源长度
   * @return {@link TPFdMediaAsset}
   */
  static createFdMediaAsset(fd: number, offset: number, length: number): ITPFdMediaAsset;

  /**
   * 创建组合型播放媒体资源，例如多个分片mp4的组合
   * @return {@link TPMultiMediaAsset}
   */
  static createMultiMediaAsset(): ITPMultiMediaAsset;

  /**
   * 创建加密播放媒体资源
   * @param url             播放地址
   * @param drmType         drm类型
   * @param certificateUrl  设备身份认证url，允许不设置，内部会解析
   * @param licenseUrl      获取加密信息url
   * @return {@link TPDrmMediaAsset}
   */
  static createDrmMediaAsset(url: string, drmType: TPDrmType,
    certificateUrl: string, licenseUrl: string): ITPDrmMediaAsset;

  /**
   * 创建Rtc直播媒体资源
   * @param url 播放地址
   * @return {@link TPRtcMediaAsset}
   */
  static createRtcMediaAsset(url: string): ITPRtcMediaAsset;

  /**
   * 创建设置给媒体资源的有序参数map
   * @return 返回创建的ITPMediaAssetParamMap
   */
  static createMediaAssetParamMap(): ITPMediaAssetParamMap;

  /**
   * 创建模拟直播播放媒体资源
   * @param startAsset 播放资源
   * @param callback 模拟直播监听器
   * @return {@link ITPSimulatedLiveMediaAsset}
   */
  static createSimulatedLiveMediaAsset(startAsset: ITPMediaAsset,
    callback: ITPSimulatedLiveCallback): ITPSimulatedLiveMediaAsset;
}
