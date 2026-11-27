/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAsset } from './ITPMediaAsset';

/**
 * 组合型media asset，用于将多个media asset拼接在一起的情况，比如多个分片mp4
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

export interface ITPMultiMediaAsset extends ITPMediaAsset {
  /**
   * 添加一个asset，内部按添加的顺序排列。
   * @param asset                     目前只支持ITPUrlMediaAsset
   * @param clipDurationMs            分片播放时长
   * @return true:添加成功 false:添加失败
   */
  addAsset(asset: ITPMediaAsset, clipDurationMs: number): boolean;
}
