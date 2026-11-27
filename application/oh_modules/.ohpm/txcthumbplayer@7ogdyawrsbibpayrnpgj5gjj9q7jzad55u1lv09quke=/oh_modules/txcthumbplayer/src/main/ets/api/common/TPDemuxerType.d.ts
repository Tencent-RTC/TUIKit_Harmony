/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * demuxer type枚举定义，其值与内核定义保持一致，不能随便修改
 *
 * @author harleyxwang
 * @date 2024/03/18
 */
export const enum TPDemuxerType {
  /**
   * 未知类型
   */
  UNKNOWN = -1,

  /**
   * ffmpeg demuxer
   */
  FFMPEG = 0,

  /**
   * 自研standalone demuxer
   */
  STANDALONE = 1,

  /**
   * webrtc demuxer
   */
  WEBRTC = 2,

  /**
   * webrtcengine demuxer
   * webrtc-engine基于webrtc-core提供标准webrtc协议栈以及音视频处理能力、网络传输等模块
   */
  WEBRTC_ENGINE = 3,
}
