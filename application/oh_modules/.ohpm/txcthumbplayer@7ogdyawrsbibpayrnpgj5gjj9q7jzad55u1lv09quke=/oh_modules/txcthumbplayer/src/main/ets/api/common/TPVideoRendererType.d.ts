/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 视频渲染器类型定义
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPVideoRendererType {
  /**
   * None，使用该配置值可以关闭渲染
   */
  NONE = -1,

  /**
   * Harmony AVCodec，类似虚拟渲染
   */
  OH_AVCODEC = 109,
}
