/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPResourceLoaderRetCode } from './ITPResourceLoader';

/**
 * 资源加载器数据信息，包括数据和返回码信息，使用{@link TPResourceLoaderDataBuilder}
 * 构建读取成功、需要重试、读取错误场景的结果信息对象
 */
export interface TPResourceLoaderData {
  /**
   * 获取传入的数据
   *
   * @return 数据buffer
   */
  getData(): Uint8Array;

  /**
   * 获取传入的返回码
   *
   * @return 读取返回码，{@link TPResourceLoaderRetCode}
   */
  getRetCode(): TPResourceLoaderRetCode;
}

/**
 * TPResourceLoaderData的构建类
 */
export class TPResourceLoaderDataBuilder {
  /**
   * 构建返回读取成功的数据信息
   *
   * @param data 读取的数据
   * @return 读取成功的数据信息
   */
  static buildSuccessfulData(data: Uint8Array): TPResourceLoaderData;

  /**
   * 构建返回读取重试的数据信息
   *
   * @return 读取重试的数据信息
   */
  static buildTryAgainData(): TPResourceLoaderData;

  /**
   * 构建返回读取错误的数据信息
   *
   * @return 读取错误的数据信息
   */
  static buildErrorData(): TPResourceLoaderData;
}
