/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAsset } from './ITPMediaAsset';

/**
 * simulated live media asset，模拟直播资源，目前只支持hls格式的url asset
 *
 * @author haiminzhong
 * @date 2024/7/24
 */

/**
 * 模拟直播资源请求器
 */
export interface ITPSimulatedLiveAssetRequest {
  /**
   * 追加asset
   * 目前仅限用于hls类型的url资源
   * @param asset 视频源
   */
  appendMediaAsset(asset: ITPMediaAsset): void;
}

/**
 * 模拟直播回调
 */
export interface ITPSimulatedLiveCallback {
  /**
   * 获取下一个播放资源的回调
   * @param requester 播放资源请求器
   */
  onNextAssetRequired(requester: ITPSimulatedLiveAssetRequest): void;
}

export interface ITPSimulatedLiveMediaAsset extends ITPMediaAsset {
  /**
   * 设置起始asset
   * @param asset 视频源
   */
  setStartAsset(asset: ITPMediaAsset): void;

  /**
   * 设置模拟直播监听器
   * @param listener 监听器
   */
  setSimulatedLiveCallback(callback: ITPSimulatedLiveCallback): void;

  /**
   * 设置播放地址的http header
   * @param httpHeader url的http header
   */
  setHttpHeader(httpHeader: Map<string, string>): void;

  /**
   * 添加备份地址，备份地址可以添加多个
   * @param backUrl 备份地址
   */
  addBackUrl(backUrl: string): void;

  /**
   * 添加备份地址和其对应的http header
   * @param backUrl 备份地址
   * @param httpHeader 备份地址的http header
   */
  addBackUrl(backUrl: string, httpHeader: Map<string, string>): void;
}
