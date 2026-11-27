/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * HDR映射类型定义. 与内核层枚举值保持一致，不要改动
 *
 * @author karlyczhang
 * @date 2024/03/06
 */
export const enum TPHdrMappingType {
  /**
   * 非HDR映射（TP_HDR_TYPE_NONE类型视频帧的映射类型）
   */
  NONE = 0,

  /**
   * 硬件HDR动态元数据映射，系统硬件支持的HDR动态元数据映射，如DolbyVision，HDRVivid，HDR10+
   */
  HARD_HDR_DYNAMIC_MAPPING = 1,

  /**
   * 软件HDR动态元数据映射，软件支持的HDR动态元数据映射，如HDRVivid软件渲染适配HDR屏
   */
  SOFT_HDR_DYNAMIC_MAPPING = 2,

  /**
   * 硬件HDR10静态元数据映射，系统硬件支持的HDR10静态元数据映射，如HDR10或HDRVivid降级为HDR10兼容模式
   */
  HARD_HDR10_STATIC_MAPPING = 3,

  /**
   * 软件HDR10静态元数据映射，软件支持的HDR10静态元数据映射
   */
  SOFT_HDR10_STATIC_MAPPING = 4,

  /**
   * 软件SDR动态元数据映射，软件支持的SDR屏动态元数据映射，如HDRVivid软件渲染适配SDR屏
   */
  SOFT_SDR_DYNAMIC_MAPPING = 5,

  /**
   * 硬件HLG映射（系统硬件支持的Hlg映射）
   */
  HARD_HLG_MAPPING = 6,

  /**
   * 软件HLG映射（软件支持的的Hlg映射）
   */
  SOFT_HLG_MAPPING = 7,
}
