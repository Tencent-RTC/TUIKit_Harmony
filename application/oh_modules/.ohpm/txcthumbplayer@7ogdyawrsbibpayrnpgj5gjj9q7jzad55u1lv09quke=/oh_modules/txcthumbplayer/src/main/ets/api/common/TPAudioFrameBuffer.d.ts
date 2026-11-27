/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPChannelLayout } from "./TPChannelLayout";
import { TPFrameEventFlag } from "./TPFrameEventFlag";
import { TPSampleFormat } from "./TPSampleFormat";

/**
 * 音频帧数据
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export interface TPAudioFrameBuffer {
  /**
   * 音频sample数据
   * 如果是planar，则是二维数组，每一行代表一个channel的数据
   * 如果是非planar，则是一维数组，第一行放置interleave数据
   * 具体数据存放，通过{@link #format}来获取
   */
  readonly data: Uint8Array[];

  /**
   * 音频sample数据大小
   * 当数据为非planar时，size[0]存放数据长度
   * 当数据为planar时，size[0] 至 size[channels-1] 存放每个声道的size
   */
  readonly dataSize: number[];

  /**
   * 音频的采样率
   */
  readonly sampleRate: number;

  /**
   * 音频的channel layout，见 TPChannelLayout.d.ts 中的定义
   */
  readonly channelLayout: TPChannelLayout;

  /**
   * 音频格式，见TPSampleFormat.d.ts中的定义
   */
  readonly format: TPSampleFormat;

  /**
   * 当前sample的PTS（Presentation Time Stamp）：即显示时间戳
   */
  readonly ptsMs: number;

  /**
   * 每个声道的采样数
   */
  readonly nbSamples: number;

  /**
   * 声道数
   */
  readonly channels: number;

  /**
   * 事件标识
   */
  readonly eventFlag: TPFrameEventFlag;
}
