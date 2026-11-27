/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * content信息数据，包括信息和结果码信息，使用{@link TPResourceLoaderMediaContentInfoBuilder}
 * 构建读取成功、需要重试、读取错误场景的结果信息对象
 */
export interface TPResourceLoaderMediaContentInfo {
  /**
   * 获取传入的资源媒体类型，对应http响应中的Content-Type字段，如video/mp4(mp4)，application/vnd.apple.mpegurl(m3u8)等
   *
   * @return 资源媒体类型
   */
  getContentType(): string;

  /**
   * 获取传入的资源大小，对应http响应中的Content-Length字段
   *
   * @return 资源大小
   */
  getContentLength(): number;
}

/**
 * TPResourceLoaderMediaContentInfo的构建类
 */
export class TPResourceLoaderMediaContentInfoBuilder {
  /**
   * 构建返回读取成功时的内容信息
   *
   * @param contentType 资源媒体类型，对应http响应中的Content-Type字段，如video/mp4(mp4)，application/vnd.apple.mpegurl(m3u8)等
   * @param contentLength 设置资源内容大小，对应http响应中的Content-Length字段
   * @return 读取成功时的内容信息
   */
  static buildSuccessfulContentInfo(contentType: string, contentLength: number): TPResourceLoaderMediaContentInfo;

  /**
   * 构建返回读取重试时的内容信息
   *
   * @return 读取重试时的内容信息
   */
  static buildTryAgainContentInfo(): TPResourceLoaderMediaContentInfo;

  /**
   * 构建返回读取错误时的内容信息，此时资源加载器终止读取
   *
   * @return 读取错误时的内容信息
   */
  static buildErrorContentInfo(): TPResourceLoaderMediaContentInfo;
}
