/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { TPDrmType } from "../common/TPDrmType";

/**
 *  设备的drm能力属性,thumbPlayer的定义，后续可扩展添加
 *
 * @author harleyxwang
 * @date 2024/03/11
 */
export interface TPDrmCapAttribute {
  /**
   * drm类型，具体参考TPDrmType中的定义
   */
  readonly drmType: TPDrmType;

  /**
   * drm安全级别，从系统设备获取的drm安全级别,Widevine和ChinaDrm的安全级别不一样
   * Widevine目前枚举：L1，L2，L3，具体见：https://www.vdocipher.com/blog/widevine-drm-hollywood-video/#4
   * ChinaDrm目前枚举：SW，HW，EH，具体见：https://developer.huawei.com/consumer/cn/doc/development/Media-Guides/wiseplaydrm_faq-0000001050415243#section78711333142117
   */
  readonly securityLevel: string;

  /**
   * drm设备支持的最大的会话数量
   */
  readonly maxNumberOfSessions: number;

  /**
   * 支持的drm加密方案类型，多个支持的加密方案类型进行与运算。drm加密方案类型参考{@link TPDrmCryptoSchemeType}
   */
  readonly supportCryptoSchemeTypes: number;
}
