/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 播放器返回码
 *
 * @author colinyzhang
 * @date 2024-03-11
 */
export const enum TPResultBase {
  /**
   * 通用错误码起始值
   */
  GENERAL_RESULT_BASE = 11000000,
  /**
   * framework错误码起始值
   */
  FRAMEWORK_RESULT_BASE = 11010000,
  /**
   * demuxer错误码起始值
   */
  DEMUXER_RESULT_BASE = 11020000,
  /**
   * decoder错误码起始值
   */
  DECODER_RESULT_BASE = 11030000,
  /**
   * videoProcess错误码起始值
   */
  VIDEO_PROCESS_RESULT_BASE = 11040000,
  /**
   * audioProcess错误码起始值
   */
  AUDIO_PROCESS_RESULT_BASE = 11050000,
  /**
   * renderer错误码起始值
   */
  RENDERER_RESULT_BASE = 11060000,
  /**
   * drm错误码起始值
   */
  DRM_RESULT_BASE = 11070000,
  /**
   * richMedia错误码起始值
   */
  RICH_MEDIA_RESULT_BASE = 11080000,
}

export const enum TPResult {
  /**
   * 通用，成功
   */
  OK = 0,
  /**
   * 通用，失败
   */
  FAILED = TPResultBase.GENERAL_RESULT_BASE + 1,
  INVALID_LICENSE = TPResultBase.GENERAL_RESULT_BASE + 2,

  // 函数入口一致性判断
  /**
   * 通用，未初始化
   */
  NOT_INIT = TPResultBase.GENERAL_RESULT_BASE + 10,
  /**
   * 通用，未实现
   */
  NOT_IMPL = TPResultBase.GENERAL_RESULT_BASE + 11,
  /**
   * 通用，非法参数
   */
  INVALID_ARG = TPResultBase.GENERAL_RESULT_BASE + 12,
  /**
   * 通用，状态错误
   */
  UNMATCHED_STATE = TPResultBase.GENERAL_RESULT_BASE + 13,

  // 流程控制
  /**
   * 通用，需要重试
   */
  TRY_AGAIN = TPResultBase.GENERAL_RESULT_BASE + 30,
  /**
   * 通用，用户中断
   */
  USER_INTERRUPT = TPResultBase.GENERAL_RESULT_BASE + 31,
  /**
   * 通用，EOF
   */
  EOF = TPResultBase.GENERAL_RESULT_BASE + 32,
  /**
   * 通用，跳过当前这次处理
   */
  SKIP_CURRENT = TPResultBase.GENERAL_RESULT_BASE + 33,
  /**
   * 通用，跳过当前数据组的处理
   */
  SKIP_GROUP = TPResultBase.GENERAL_RESULT_BASE + 34,
  /**
   * 通用，忽略当前调用
   */
  IGNORE_CURRENT_CALL = TPResultBase.GENERAL_RESULT_BASE + 35,

  // 处理过程错误
  /**
   * 通用，内存不足
   */
  OUT_OF_MEMORY = TPResultBase.GENERAL_RESULT_BASE + 50,
}
