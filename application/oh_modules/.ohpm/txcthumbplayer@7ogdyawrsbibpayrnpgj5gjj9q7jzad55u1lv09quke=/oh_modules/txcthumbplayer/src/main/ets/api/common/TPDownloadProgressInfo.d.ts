/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 下载进度相关数据参数
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export interface TPDownloadProgressInfo {
  /**
   * 当前可以播到的时间点，以时间position=0起始计算，单位毫秒
   */
  availablePositionMs: number;

  /**
   * 当前的下载速度bps
   */
  downloadSpeedbps: number;

  /**
   * 当前文件已经下载的大小
   */
  downloadBytes: number;

  /**
   * 当前文件总大小
   */
  fileTotalBytes: number;

  /**
   * 扩展信息
   */
  extraInfo: string;
}
