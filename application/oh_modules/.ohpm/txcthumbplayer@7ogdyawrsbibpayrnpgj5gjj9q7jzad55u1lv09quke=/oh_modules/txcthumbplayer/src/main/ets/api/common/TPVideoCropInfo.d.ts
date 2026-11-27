/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * video裁剪信息
 *                               width
 * /////////////////////////////////////////////////////////////////
 * ///                             -                       -       /
 * ///                             |                       |       /
 * ///                          cropTop                    |       /
 * ///                             |                       |       /
 * ///                             -                  cropBottom   /
 * ///                 //////////////////////////////      |       /
 * ///                 /                            /      |       /
 * ///                 /       CROP RECTANGLE       /      |       / height
 * ///                 /                            /      |       /
 * ///|-- cropLeft --|//////////////////////////////       -       /
 * ///                                                             /
 * ///|-------------- cropRight -------------------|               /
 * ///                                                             /
 * /////////////////////////////////////////////////////////////////
 *
 * @author karlyczhang
 * @date 2024/03/14
 */
export interface TPVideoCropInfo {
  /** 视频帧的宽 */
  width: number;

  /** 视频帧的高 */
  height: number;

  /** 裁剪区域左边界 与 视频帧左边界的距离 */
  cropLeft: number;

  /** 裁剪区域右边界 与 视频帧左边界的距离 */
  cropRight: number;

  /**  裁剪区域上边界 与 视频帧上边界的距离 */
  cropTop: number;

  /** 裁剪区域下边界 与 视频帧上边界的距离 */
  cropBottom: number;
}
