/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 容器类型枚举定义
 *
 * @author harleyxwang
 * @date 2024/03/12
 */
export const enum TPContainerType {
  /**
   * 未知容器类型
   */
  UNKNOWN = 0,
  /**
   * hls容器
   */
  HLS = 1,

  /**
   * dash容器
   */
  DASH = 2,
}
