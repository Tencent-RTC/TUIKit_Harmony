/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { Context } from '@ohos.abilityAccessCtrl';
import { ITPLogCallback, TPLogLevel } from "../common/ITPLogCallback";
import { TPOptionalParam } from "../optionalparam/TPOptionalParam";

/**
 * ThumbPlayer内部模块名称，用于在TPMgr.getLibVersion中获取相应模块版本
 *
 * @author karlyczhang
 * @date 2024/4/25
 */
export const enum TPModuleName {
  /**
   * 播放器内核
   */
  PLAYER_CORE = "TPCore",

  /**
   * 下载组件
   */
  DOWNLOAD_PROXY = "DownloadProxy"
}

/**
 * ThumbPlayer管理类
 *
 * @author karlyczhang
 * @date 2024/2/19
 */
export class TPMgr {
  /**
   * 初始化ThumbPlayer
   *
   * @param context 上下文信息，鸿蒙平台下是UIAbilityContext
   */
  static initThumbPlayer(context: Context): void;

  /**
   * ThumbPlayer是否初始化完成
   *
   * @return true初始化完成, false未初始化
   */
  static isInitialized(): boolean;

  /**
   * 设置日志回调, 在JS主引擎调用这个方法
   * @param callback 日志回调对象
   */
  static setLogCallback(callback: ITPLogCallback): void;

  /**
   * 设置日志打印等级, 在JS主引擎调用这个方法
   *
   * @param logLevel 日志等级，等级大于等于logLevel的日志才会输出
   */
  static setLogLevel(logLevel: TPLogLevel): void;

  /**
   * 获取播放器版本号
   *
   * @return 播放器版本号
   */
  static getThumbPlayerVersion(): string;

  /**
   * 通过模块名获取模块版本号. 调用initThumbPlayer之后才能获取
   *
   * @param moduleName 模块名
   * @return 对应模块的版本号, 如果未初始化或者未找到对应模块返回空
   */
  static getLibVersion(moduleName: TPModuleName): string;

  /**
   * 设置ThumbPlayer全局通用参数
   *
   * @param param 通用参数
   */
  static addOptionalParam(param: TPOptionalParam): void;
}
