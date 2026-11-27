/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAsset } from './ITPMediaAsset';

/**
 * url media asset，用于只有一个播放url的情况，比如hls、单片mp4、字幕轨、音轨等。
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

export interface ITPUrlMediaAsset extends ITPMediaAsset {
  /**
   * 设置播放地址
   * @param url 播放地址
   */
  setUrl(url: string): void;

  /**
   * 设置播放地址及其对应http header
   * @param url 播放地址
   * @param httpHeader url的http header
   */
  setUrl(url: string, httpHeader: Map<string, string>): void;

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
