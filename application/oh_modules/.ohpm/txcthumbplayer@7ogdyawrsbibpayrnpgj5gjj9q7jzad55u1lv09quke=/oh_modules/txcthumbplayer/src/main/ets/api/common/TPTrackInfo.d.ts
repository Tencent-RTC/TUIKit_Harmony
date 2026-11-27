/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { ITPContainerInfo } from "./ITPContainerInfo";
import { TPMediaType } from "./TPMediaType";

/**
 * track信息
 * 包含视频轨，音频轨和字幕轨
 *
 * @author harleyxwang
 * @date 2024/03/12
 */
export interface TPTrackInfo {
  /**
   * 轨道媒资类型
   */
  mediaType: TPMediaType;

  /**
   * 轨道名字, 用于外挂字幕/音轨设置名字
   */
  name?: string;

  /**
   * 轨道语言, 用于外挂字幕设置语言
   */
  language?: string;

  /**
   * 当前轨道是否被选中
   */
  isSelected: boolean;

  /**
   * 如果是true，该类型轨道每个时刻只有一条能被选中，如果是false，该类型轨道可以同时选中多条
   */
  isExclusive: boolean;

  /**
   * 如果是true，该类型轨道为内部轨道，如果是false，该类型轨道为外部轨道。
   */
  isInternal: boolean;

  /**
   * 封装格式信息，如果containerType为TP_CONTAINER_TYPE_UNKNOWN，则为null，
   * 如果containerType为TP_CONTAINER_TYPE_HLS，则为TPHlsTag
   * 如果TP_CONTAINER_TYPE_DASH，则为TPDashFormat
   */
  readonly containerInfo?: ITPContainerInfo;
}
