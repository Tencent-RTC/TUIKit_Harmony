/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * ThumbPlayer可选控制参数值类型
 * 目前包含boolean/number/string/number数组/string数组/object
 *
 * @author karlyczhang
 * @date 2024/03/04
 */
type TPOptionalParamValueType = boolean | number | string | number[] | string[] | object;


/**
 * 创建boolean类型的可选参数
 *
 * @param key 参数key值, key取值参考 {@link TPOptionalID}
 * @param value 参数的value
 * @return 返回TPOptionalParam的对象
 */
export function buildBooleanParam(key: string, value: boolean): TPOptionalParam;

/**
 * 创建int类型的可选参数
 *
 * @param key 参数key值, key取值参考 {@link TPOptionalID}
 * @param value 参数的value
 * @return 返回TPOptionalParam的对象
 */
export function buildIntParam(key: string, value: number): TPOptionalParam;

/**
 * 创建long类型的可选参数
 *
 * @param key 参数key值, key取值参考 {@link TPOptionalID}
 * @param value 参数的value
 * @return 返回TPOptionalParam的对象
 */
export function buildLongParam(key: string, value: number): TPOptionalParam;

/**
 * 创建float类型的可选参数
 *
 * @param key 参数key值, key取值参考 {@link TPOptionalID}
 * @param value 参数的value
 * @return 返回TPOptionalParam的对象
 */
export function buildFloatParam(key: string, value: number): TPOptionalParam;

/**
 * 创建int数组类型的param
 *
 * @param key key值, key取值参考 {@link TPOptionalID}
 * @param value int数组
 * @return 返回TPOptionalParam的对象
 */
export function buildQueueIntParam(key: string, value: number[]): TPOptionalParam;

/**
 * 创建string类型的1个参数的可选参数
 *
 * @param key 参数key值, key取值参考 {@link TPOptionalID}
 * @param value 参数的value
 * @return 返回TPOptionalParam的对象
 */
export function buildStringParam(key: string, value: string): TPOptionalParam;

/**
 * 创建string数组类型的param
 *
 * @param key key值, key取值参考 {@link TPOptionalID}
 * @param value string数组
 * @return 返回TPOptionalParam的对象
 */
export function buildQueueStringParam(key: string, value: string[]): TPOptionalParam;

/**
 * 创建object类型的可选参数
 *
 * @param key 参数的key值, key取值参考 {@link TPOptionalID}
 * @param value 参数的value值
 * @return 返回TPOptionalParam的对象
 */
export function buildObjectParam(key: string, value: object): TPOptionalParam;

/**
 * ThumbPlayer可选控制参数
 *
 * @author karlyczhang
 * @date 2024/03/04
 */
export interface TPOptionalParam {
  /**
   * 获取当前参数的key 参考{@link TPOptionalID}里的定义
   *
   * @return 当前参数的key
   */
  getKey(): string;

  /**
   * 获取当前参数的value，返回TPOptionalParamValueType类型，采用typeof/instanceof来进行类型判断后进行类型转换
   *
   * @return 当前参数的value
   */
  getValue(): TPOptionalParamValueType;

  /**
   * 是否为必须在播放器prepare前设置的optionalParam
   *
   * @return 是否为必须在播放器prepare前设置的optionalParam
   */
  isBeforeOptionalParam(): boolean;
}
