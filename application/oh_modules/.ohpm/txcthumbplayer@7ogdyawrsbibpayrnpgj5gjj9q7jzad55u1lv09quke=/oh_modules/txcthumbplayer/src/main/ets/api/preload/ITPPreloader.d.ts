/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPError } from "../common/TPError";
import { TPDownloadProgressInfo } from "../common/TPDownloadProgressInfo";
import { ITPMediaAsset } from "../asset/ITPMediaAsset";

/**
 * 创建预加载的实例
 * 注意: sdk未初始化或传输组件不可用时返回为null
 *
 * @return 预加载对象.
 */
export function createPreloader(): ITPPreloader | null;

/**
 * 非法的预加载id， 预加载失败将会返回
 */
export const INVALID_PRELOAD_ID = -1;

/**
 * 数据预加载接口
 * 多任务设计，不同任务的操作和回调通过返回的preloadID来区分
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export interface ITPPreloader {
  /**
   * 设置预加载回调
   * 本方法要先于{@link #start(ITPMediaAsset)}才可以正常收到回调
   *
   * @param callback 预加载回调
   */
  setPreloadCallback(callback: ITPPreloadCallback): void;

  /**
   * 启动预加载，如果启动失败将会返回{@link #INVALID_PRELOAD_ID}
   * 本方法需要先调用{@link #setPreloadListener(ITPPreloadListener)}才可以正常收到回调
   *
   * @param asset 媒体资源，当前只支持{@link ITPUrlMediaAsset} {@link ITPMultiMediaAsset}
   * @return preloadID, 预加载id, 停止预加载将会使用到
   */
  start(asset: ITPMediaAsset): number;

  /**
   * 停止预加载
   *
   * @param preloadID {@link #start(ITPMediaAsset)}返回的preload id
   */
  stop(preloadID: number): void;
}

/**
 * 数据预加载接口回调接口
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export interface ITPPreloadCallback {
  /**
   * 预加载成功
   *
   * @param preloadID {@link #start(ITPMediaAsset)}返回的preload id
   */
  onPreloadSuccess(preloadID: number): void;

  /**
   * 预加载失败
   *
   * @param preloadID {@link #start(ITPMediaAsset)}返回的preload id
   * @param error 错误信息
   */
  onPreloadError(preloadID: number, error: TPError): void;

  /**
   * 预加载进度
   *
   * @param preloadID {@link #start(ITPMediaAsset)}返回的preload id
   * @param progressInfo 下载进度信息
   */
  onPreloadProgressUpdate(preloadID: number, progressInfo: TPDownloadProgressInfo): void;
}
