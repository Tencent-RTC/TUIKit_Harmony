/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPVideoCodecType } from "./TPVideoCodecType";
import { TPVideoSeiType } from './TPVideoSeiType';

/**
 * video sei信息
 *
 * @author karlyczhang
 * @date 2024/03/14
 */
export interface TPVideoSeiInfo {
  /** 视频编码类型 */
  codecType: TPVideoCodecType;

  /** sei数据类型*/
  seiType: TPVideoSeiType;

  /** sei数据 */
  readonly seiData: ArrayBuffer;
}
