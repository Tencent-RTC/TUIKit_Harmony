/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 音视频帧数据事件Flag
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export const enum TPFrameEventFlag {
  /**
   * 未定义事件
   */
  TP_FRAME_EVENT_FLAG_UNKNOWN = 0,
  /**
   * Eos事件
   */
  TP_FRAME_EVENT_FLAG_EOS = 1 << 0,
  /**
   * Flush事件
   */
  TP_FRAME_EVENT_FLAG_FLUSH = 1 << 1,
}
