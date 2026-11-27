/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 视频渲染拉伸模式
 *
 * @author colinyzhang
 * @date 2024-03-11
 */

export const enum TPVideoGravity {
  /**
   * 保持宽高比，上下或者左右填充黑边
   */
  SCALE_ASPECT_FIT = 0,
  /**
   * 保持宽高比，铺满屏幕，部分画面可能超出屏幕
   */
  SCALE_ASPECT_FILL = 1,
  /**
   * 改变宽高比，铺满屏幕
   */
  SCALE_TO_FILL = 2,
  /**
   * 保持宽高比，视频铺满屏幕，部分视频画面可能超出屏幕，但字幕固定不变
   */
  SCALE_ASPECT_FILL_FIX_SUBTITLE = 3,
  /**
   * 不缩放居中显示，比如暂停时的广告，暂时仅Windows支持。
   */
  CENTER = 4,
  /**
   * 按4:3比例缩放，上下或者左右填充黑边，暂时仅Windows支持。
   */
  SCALE_4X3 = 5,
  /**
   * 按16:9比例缩放，上下或者左右填充黑边，暂时仅Windows支持。
   */
  SCALE_16X9 = 6
}
