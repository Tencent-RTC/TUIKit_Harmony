/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPHdrType } from "../common/TPHdrType";
import { TPHdrCapAttribute } from "./TPHdrCapAttribute";
import { TPHdrMappingType } from "../common/TPHdrMappingType";

/**
 * hdr能力支持情况，目前仅有不支持和支持两个，后续可扩展
 *
 * @author karlyczhang
 * @date 2024/03/06
 */
export const enum TPHdrCap {
  NOT_SUPPORT = 0,
  SUPPORT = 1
}

/**
 * 用于获取和管理hdr能力的对象。使用该类前需要先调用TPMgr.initThumbPlayer()接口进行初始化，初始化完成后才可调用。
 *
 * @author karlyczhang
 * @date 2024/03/06
 */
export class TPHdrCapability {
  /**
   * 获取hdr能力的支持情况
   *
   * @param hdrType hdr类型，参考{@link TPHdrType}，包括HDR10,HDR10+,HLG,DOLBY VISION等。
   * @return 返回hdr能力支持情况，返回值见{@link TPHdrCap}
   */
  static getHdrCapability(hdrType: TPHdrType): TPHdrCap;

  /**
   * 查询指定的HDR能力属性
   *
   * @param hdrType HDR类型，参考{@link TPHdrType}。
   * @return HDR能力属性，参考TPHdrCapAttribute.d.ts
   */
  static getHdrCapAttribute(hdrType: TPHdrType): TPHdrCapAttribute;

  /**
   * 添加定制化的hdr能力。即添加指定hdr类型的hdr映射方式是否支持
   *
   * @param hdrType hdr类型，参考{@link TPHdrType}
   * @param supportedMappingType 该hdr类型的hdr映射方式，参考{@link TPHdrMappingType}
   * @param hdrCap 定制化的hdr能力支持情况，具体见{@link TPHdrCap}
   */
  static addCustomizedHdrCapability(hdrType: TPHdrType, supportedMappingType: TPHdrMappingType, hdrCap: TPHdrCap): void;
}
