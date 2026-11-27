/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * drm类型定义
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

export const enum TPDrmType {
  /**
   * 未加密
   */
  NONE = -1,
  /**
   * google的widevine
   */
  WIDEVINE = 0,
  /**
   * chinaDrm 2.0的硬解方案
   */
  CHINADRM_2_0 = 3,
}
