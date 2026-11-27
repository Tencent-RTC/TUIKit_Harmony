/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 媒体类型定义，跟native(TPMediaType.h)保持一致
 *
 * @author harleyxwang
 * @date 2024/03/12
 */
export const enum TPMediaType {
  /**
   * Unknown media type
   */
  UNKNOWN = -1,

  /**
   * media type类型为video
   */
  VIDEO = 0,

  /**
   * media type类型为Audio
   */
  AUDIO = 1,

  /**
   * media type类型为二进制数据
   */
  DATA = 2,

  /**
   *  media type类型为字幕
   */
  SUBTITLE = 3,

  /**
   * media type类型为attachment
   */
  ATTACHMENT = 4,
}
