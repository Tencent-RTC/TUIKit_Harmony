/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * TPDebugTrackingInfo的事件ID
 *
 * @author colinyzhang
 * @date 2024/03/08
 */

export const enum TPDebugTrackingInfoID {
  UNKNOWN = -1,
  /**
   * 首次起播
   */
  FIRST_START = 0,
  /**
   *  播放调度线程开始prepare
   */
  PLAYER_SCHEDULING_THREAD_PREPARE_START = 1,
  /**
   * Demuxer 线程开始prepare
   */

  DEMUXER_THREAD_PREPARE_START = 2,
  /**
   * Demuxer打开文件开始
   */
  DEMUXER_FILE_OPEN_START = 3,
  /**
   * Demuxer打开文件结束
   */
  DEMUXER_FILE_OPEN_END = 4,
  /**
   * Demuxer 线程开始onPrepared
   */
  DEMUXER_THREAD_ON_PREPARED = 5,
  /**
   * 播放调度线程开始onPrepared
   */
  PLAYER_SCHEDULING_THREAD_ON_PREPARED = 6,
  /**
   * 首次视频解码器创建开始
   */
  FIRST_VIDEO_DECODER_CREATE_START = 7,
  /**
   * 首次音频解码器创建开始
   */
  FIRST_AUDIO_DECODER_CREATE_START = 8,
  /**
   * 首帧视频渲染
   */
  FIRST_VIDEO_FRAME_RENDERED = 9,
  /**
   * 首帧音频渲染
   */
  FIRST_AUDIO_FRAME_RENDERED = 10,
  /**
   * Demuxer读到第一个audio/video packet
   */
  FIRST_PACKET_READ = 19,

  // DRM流程相关的打点
  DRM_PREPARE_START = 100,
  DRM_PREPARE_END = 101,
  DRM_OPEN_SESSION_START = 102,
  DRM_OPEN_SESSION_END = 103,
  DRM_GET_PROVISION_REQ_START = 104,
  DRM_GET_PROVISION_REQ_END = 105,
  DRM_SEND_PROVISION_REQ = 106,
  DRM_RECV_PROVISION_RESP = 107,
  DRM_PROVIDE_PROVISION_RESP_START = 108,
  DRM_PROVIDE_PROVISION_RESP_END = 109,
  DRM_GET_KEY_REQ_START = 110,
  DRM_GET_KEY_REQ_END = 111,
  DRM_SEND_KEY_REQ = 112,
  DRM_RECV_KEY_RESP = 113,
  DRM_PROVIDE_KEY_RESP_START = 114,
  DRM_PROVIDE_KEY_RESP_END = 115,
  DRM_KEY_REQ_DNS_RESOLVED = 116,
  DRM_KEY_REQ_SOCKET_CONNECTED = 117,

  // TPPlayer 上层的打点事件.
  TP_PLAYER_API_SET_DATA_SOURCE_START = 1000,
  TP_PLAYER_API_SET_DATA_SOURCE_END = 1001,
  TP_PLAYER_API_PREPARE_START = 1002,
  TP_PLAYER_API_ON_PREPARED = 1003,
  TP_PLAYER_API_ON_FIRST_VIDEO_FRAME_RENDERED = 1004,
  TP_PLAYER_API_ON_FIRST_AUDIO_FRAME_RENDERED = 1005,
}

/**
 * 播放器运行过程中的一些细节信息，用于调试或者上报
 *
 * @author colinyzhang
 * @date 2024/03/08
 */

export interface TPDebugTrackingInfo {
  /**
   * 事件ID
   */
  readonly trackingInfoId: TPDebugTrackingInfoID;

  /**
   * 信息采集时的系统实时时间，即从UTC1970-1-1 0:0:0开始计时，单位毫秒
   */
  readonly timeSince1970Ms: number;

  /**
   * 信息采集时的系统自启动以来经过的时间，单位毫秒
   */
  readonly elapsedTimeSinceBootMs: number;
}
