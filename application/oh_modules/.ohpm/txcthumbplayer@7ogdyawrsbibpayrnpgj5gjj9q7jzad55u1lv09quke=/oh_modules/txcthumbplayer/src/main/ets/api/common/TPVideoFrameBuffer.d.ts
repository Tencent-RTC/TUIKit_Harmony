/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPFrameEventFlag } from "./TPFrameEventFlag";
import { TPPixelFormat } from "./TPPixelFormat";

export interface TPVideoFrameBuffer {
  /**
   * 原始视频帧数据
   * 当数据为非planar时，data[0]存放数据，
   * 当数据为planar时，data[0] 至 data[planeCount-1] 存放每个通道的数据。
   */
  readonly data: Uint8Array[];

  /**
   * 每个通道的lineSize
   */
  readonly lineSize: number[];

  /**
   * 旋转角度，取值为0、90、180、270
   */
  readonly rotation: number;

  /**
   * 显示宽
   * 部分带有SAR信息的视频，数据宽高不一定等于显示宽高，需要根据该值来决定如何做显示
   */
  readonly displayWidth: number;

  /**
   * 显示高
   * 部分带有SAR信息的视频，数据宽高不一定等于显示宽高，需要根据该值来决定如何做显示
   */
  readonly displayHeight: number;

  /**
   * 当前sample的PTS（Presentation Time Stamp）：即显示时间戳
   */
  readonly ptsMs: number;

  /**
   * 当前帧的轨道id，与ITPPlayer中的getTrackInfo返回的数组的下标对应
   */
  readonly trackID: number;

  /**
   * 事件标识
   */
  readonly eventFlag: TPFrameEventFlag;

  /**
   * 视频格式，值定义见TPPixelFormat.d.ts
   */
  readonly format: TPPixelFormat;

  /**
   * 视频原始宽度，即数据宽度
   */
  readonly width: number;

  /**
   * 视频原始高度，即数据高度
   */
  readonly height: number;
}
