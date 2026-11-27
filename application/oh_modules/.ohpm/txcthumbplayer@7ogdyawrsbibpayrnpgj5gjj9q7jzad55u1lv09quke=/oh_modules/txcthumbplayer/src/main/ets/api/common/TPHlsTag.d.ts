/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { ITPContainerInfo } from "./ITPContainerInfo";

/**
 * Hls封装格式信息
 *
 * @author harleyxwang
 * @date 2024/03/13
 */

export interface TPHlsTag extends ITPContainerInfo {
  /**
   * 轨道名称，对应HLS master playlist audio/subtitle内字段NAME, 用于唯一标识音轨/字幕
   */
  name: string;

  /**
   * 轨道语言，对应HLS master playlist内audio/subtitle的字段LANGUAGE, 用于音轨/字幕选择
   */
  language: string;

  /**
   * 轨道组id，对应HLS master playlist内audio/subtitle的字段GROUP-ID, 用于音轨/字幕匹配不同视频
   */
  groupID: string;

  /**
   * 轨道带宽，对应HLS master playlist内video的字段BANDWIDTH, 标识视频码率信息, 匹配相应的网络带宽
   */
  bandwidth: number;

  /**
   * 轨道分辨率(用于HLS master playlist video对应字段RESOLUTION), 标识视频分辨率
   */
  resolution: string;

  /**
   * 轨道帧率，对应HLS master playlist内video的字段FRAME-RATE, 标识视频帧率
   */
  frameRate: number;

  /**
   * 轨道编解码信息，对应HLS master playlist内video的字段CODECS, 标识视频编解码信息
   */
  codecs: string;
}
