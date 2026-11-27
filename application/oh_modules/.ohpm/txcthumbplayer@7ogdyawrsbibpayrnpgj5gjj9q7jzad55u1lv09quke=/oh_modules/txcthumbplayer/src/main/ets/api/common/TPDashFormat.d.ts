/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { ITPContainerInfo } from "./ITPContainerInfo";

/**
 * dash容器格式信息
 *
 * @author harleyxwang
 * @date 2024/03/13
 */

export interface TPDashFormat extends ITPContainerInfo {
  /**
   * 轨道id，对应dash mpd内Representation元素的id属性
   */
  representationId: string;

  /**
   * 轨道编码集，对应dash mpd内的codecs属性
   */
  codecs: string;

  /**
   * 轨道互联网媒体类型，对应dash mpd内的mimeType属性
   */
  mimeType: string;

  /**
   * 轨道语言，对应dash mpd内的lang属性
   */
  language: string;

  /**
   * 轨道名称，对应dash mpd内的Label属性
   */
  label: string;

  /**
   * 轨道宽，仅用于video，对应dash mpd内的width属性
   */
  width: number;

  /**
   * 轨道高，仅用于video，对应dash mpd内的height属性
   */
  height: number;

  /**
   * 轨道带宽，对应dash mpd内的bandwidth属性
   */
  bandwidth: number;

  /**
   * 轨道音频频道数目，从dash mpd AudioChannelConfiguration元素的属性中解析出的通道数
   */
  channels: number;

  /**
   * 轨道音频采样率，对应dash mpd内的audioSamplingRate属性
   */
  samplingRate: number;

  /**
   * 轨道帧率，仅用于video，对应dash mpd内的frameRate属性
   */
  frameRate: number;
}
