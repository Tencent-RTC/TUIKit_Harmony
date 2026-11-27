/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 日志打印等级，用于控制应打印的日志类型
 */
export const enum TPLogLevel {
  VERBOSE = 0,
  DEBUG = 1,
  INFO = 2,
  WARNING = 3,
  ERROR = 4,
}

/**
 * 日志打印回调接口
 *
 * @author harleyxwang
 * @date 2024/03/19
 */
export interface ITPLogCallback {
  /**
   * 日志打印接口
   *
   * @param logLevel 日志打印级别
   * @param tag 日志tag
   * @param content 日志内容
   */
  traceLog(logLevel: TPLogLevel, tag: string, content: string);
}
