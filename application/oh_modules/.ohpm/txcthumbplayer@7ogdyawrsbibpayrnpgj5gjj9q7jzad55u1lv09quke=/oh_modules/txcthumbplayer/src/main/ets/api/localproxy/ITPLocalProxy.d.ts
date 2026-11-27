/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAsset } from "../asset/ITPMediaAsset";
import { TPDownloadProgressInfo } from "../common/TPDownloadProgressInfo";
import { TPError } from "../common/TPError";

/**
 * 创建媒体资源的本地代理实例
 * 注意: sdk未初始化或传输组件不可用时返回为null
 *
 * @return 本地代理实例
 */
export function createTPLocalProxy(): ITPLocalProxy | null;

/**
 * 本地代理回调接口
 *
 * @author karlyczhang
 * @date 2024/08/12
 */
export interface ITPLocalProxyCallback {
  /**
   * 下载成功
   */
  onDownloadSuccess(): void;

  /**
   * 下载出错
   *
   * @param error 错误信息
   */
  onDownloadError(error: TPError): void;

  /**
   * 下载进度回调
   *
   * @param progressInfo 进度信息
   */
  onDownloadProgressUpdate(progressInfo: TPDownloadProgressInfo): void;
}

/**
 * 构建媒体资源的本地代理接口
 * 使用传输组件生成媒体资源的本地代理地址，业务方可从该地址获取数据或直接用该地址播放
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export interface ITPLocalProxy {
  /**
   * 构建本地代理地址. 注意该接口不可重复调用，重复调用该接口时抛状态异常
   *
   * @param mediaAsset 播放资源（目前仅支持在线的TPUrlMediaAsset和TPDrmMediaAsset)
   * @param callback 本地代理回调
   * @return 本地代理地址
   */
  buildProxyUrl(mediaAsset: ITPMediaAsset, callback: ITPLocalProxyCallback): string;

  /**
   * 释放本地代理
   */
  release(): void;
}
