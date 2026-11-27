/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放器onInfo回调携带的数据信息
 *
 * @author karlyczhang
 * @date 2024-02-28
 */
export interface TPOnInfoParam {
  /**
   * long型数据载体
   */
  longParam1?: number;
  longParam2?: number;

  /**
   * float型数据载体
   */
  floatParam1?: number;
  floatParam2?: number;

  /**
   * string型数据载体
   */
  strParam1?: string;
  strParam2?: string;

  /**
   * 扩展数据载体
   */
  objParam?: Object;
}
