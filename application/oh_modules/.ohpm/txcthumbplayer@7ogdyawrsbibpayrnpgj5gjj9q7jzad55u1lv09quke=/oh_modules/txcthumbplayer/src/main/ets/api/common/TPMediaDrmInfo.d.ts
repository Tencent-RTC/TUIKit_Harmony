/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPDrmType } from "./TPDrmType";

/**
 * MediaDrm相关的一些信息
 *
 * @author karlyczhang
 * @date 2024/03/14
 */
export interface TPMediaDrmInfo {
  /** DRM视频播放使用的组件名 */
  componentName: string;

  /** DRM类型, 详见{@link TPDrmType} */
  drmType: TPDrmType;
}
