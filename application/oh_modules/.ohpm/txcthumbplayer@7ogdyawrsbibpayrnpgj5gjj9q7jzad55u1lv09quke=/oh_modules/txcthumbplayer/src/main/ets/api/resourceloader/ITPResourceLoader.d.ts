/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPResourceLoaderData } from './TPResourceLoaderData';
import { TPResourceLoaderMediaContentInfo } from './TPResourceLoaderMediaContentInfo'

/**
 * 资源加载器返回码，用于描述读取媒体内容信息或媒体数据时接口返回标识，根据返回码决策继续读取、重试或中止读取行为
 */
export const enum TPResourceLoaderRetCode {

  /**
   * 资源加载器接口返回成功
   */
  TP_RESOURCE_LOADER_RET_CODE_SUCCESS = 0,

  /**
   * 资源加载器接口返回重试
   */
  TP_RESOURCE_LOADER_RET_CODE_TRY_AGAIN = -1,

  /**
   * 资源加载器接口返回错误
   */
  TP_RESOURCE_LOADER_RET_CODE_ERROR = -2
}

/**
 * ResourceLoader接口
 */
export interface ITPResourceLoader {
  /**
   * 资源加载器打开一个资源传输通道，启动一个资源传输任务时首先调用这个方法；返回true表示资源加载通道打开成功，可以进行数据读取；
   * 返回false表示资源加载通道打开失败，将终止资源加载流程
   *
   * @param requestId 资源请求索引id
   * @param url 资源url
   * @return 是否成功开启资源加载器通道
   */
  open(requestId: number, url: string): boolean;

  /**
   * 资源加载器读取媒体资源信息，在{@link #open}后和{@link #readData}前被调用
   *
   * @param requestId 资源请求索引id
   * @param url 资源url
   * @return 媒体信息，参考{@link TPResourceLoaderMediaContentInfo}
   */
  readMediaContentInfo(requestId: number, url: string): TPResourceLoaderMediaContentInfo;

  /**
   * 资源加载器seek资源数据到指定位置，在{@link #readMediaContentInfo}后和{@link #close}前被调用，调用场景与媒体资源播放过程中
   * 的seek一致，seek成功返回{@link #TP_RESOURCE_LOADER_RET_CODE_SUCCESS}，
   * seek失败返回{@link #TP_RESOURCE_LOADER_RET_CODE_ERROR}
   *
   *
   * @param requestId 资源请求索引id
   * @param url 资源url
   * @param position seek指定的位置
   * @return seek操作返回码，{@link #TP_RESOURCE_LOADER_RET_CODE_SUCCESS}表示成功
   * {@link #TP_RESOURCE_LOADER_RET_CODE_ERROR}表示失败
   */
  seekData(requestId: number, url: string, position: number): TPResourceLoaderRetCode;

  /**
   * 资源加载器读取媒体资源数据，在{@link #readMediaContentInfo}后和{@link #close}前被调用，
   * 使用顺序读取的方式，如果需要调整读取位置，结合调用{@link #seekData}方法完成；
   *
   * @param requestId 资源请求索引id
   * @param url 资源url
   * @param size 读取数据长度
   * @return 读取数据信息，包含Uint8Array数据和返回码，参考{@link TPResourceLoaderData}
   */
  readData(requestId: number, url: string, size: number): TPResourceLoaderData;

  /**
   * 资源加载器关闭一个资源传输通道，在一个资源传输完成后被调用
   *
   * @param requestId 资源请求索引id
   * @param url 资源url
   */
  close(requestId: number, url: string): void;
}
