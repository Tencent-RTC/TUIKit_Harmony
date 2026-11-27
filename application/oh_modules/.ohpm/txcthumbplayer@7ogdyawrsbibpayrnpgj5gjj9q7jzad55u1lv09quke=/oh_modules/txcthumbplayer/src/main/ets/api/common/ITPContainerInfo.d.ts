/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { TPContainerType } from "./TPContainerType";

/**
 * 封装格式信息接口
 *
 * @author harleyxwang
 * @date 2024/03/12
 */
export interface ITPContainerInfo {
  /**
   * 获取container type，参考{@link TPContainerType}
   */
  readonly containerType: TPContainerType;
}
