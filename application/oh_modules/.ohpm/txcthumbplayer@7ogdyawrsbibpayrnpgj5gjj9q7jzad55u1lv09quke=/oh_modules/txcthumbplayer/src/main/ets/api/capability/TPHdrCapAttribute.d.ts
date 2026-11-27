/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPHdrType } from "../common/TPHdrType";
import { TPHdrMappingType } from "../common/TPHdrMappingType";

/**
 * HDR能力属性，用于说明设备支持的对应HDR能力的相关特性
 *
 * @author karlyczhang
 * @date 2024/03/06
 */
export interface TPHdrCapAttribute {
  /**
   * HDR类型，具体参考{@link TPHdrType}
   */
  readonly hdrType: TPHdrType
  /**
   * 设备支持HDR能力的映射方式（HDR能力设备可能支持一种或多种映射方式，映射方式详见{@link TPHdrMappingType}）
   */
  readonly supportedMappingType: Set<TPHdrMappingType>
}
