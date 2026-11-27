// Copyright (c) 2026 Tencent. All rights reserved.

/**
 * API 回调函数类型
 */
export type APICallback = (code: number, message: string, data: string) => void;

/** Registers system observation, information and timer entry points with AKI. */
export namespace JSBind {
  function bindFunction(name: string, callback: (token: string) => void): number;
  function bindFunction(name: string, callback: () => string): number;
  function bindFunction(name: string, callback: (timerId: number) => void): number;
  function bindFunction(name: string, callback: (timeout: number, task: () => void) => void): number;
  function bindFunction(name: string,
    callback: (timerId: number, interval: number, task: (timerId: number) => void) => void): number;
}

/** Delivers an AudioKit snapshot to a cancellable native observation session. */
export function NativeOnMobileDeviceSnapshot(token: string, snapshot: string): void;

/**
 * 引擎 → ArkTS 的被动事件分发器（无返回值）
 */
export type OnCallHandler = (eventName: string, id: string, jsonData: string) => void;

/**
 * 引擎 → ArkTS 的同步查询分发器（返回 JSON 字符串）
 */
export type OnQueryHandler = (eventName: string, id: string, jsonData: string) => string;

/**
 * PipelineNapi 类型声明
 */
export class PipelineNapi {
  constructor();

  /**
   * 初始化引擎
   */
  Init(): void;

  /**
   * 反初始化引擎
   */
  Uninit(): void;

  /**
   * 异步调用引擎 API（ArkTS → 引擎）
   * @param eventName 事件名称
   * @param id 实例标识
   * @param jsonData JSON 格式的参数
   * @param callback 回调函数
   */
  Call(eventName: string, id: string, jsonData: string, callback: APICallback): void;

  /**
   * 同步查询引擎 API（ArkTS → 引擎）
   * @param eventName 事件名称
   * @param id 实例标识
   * @param jsonData JSON 格式的参数
   * @returns JSON 格式的返回结果
   */
  Query(eventName: string, id: string, jsonData: string): string;

  /**
   * 注册引擎 → ArkTS 的事件分发器（被动回调）
   * @param handler 接收引擎上抛的事件，无返回值
   */
  SetOnCallHandler(handler: OnCallHandler): void;

  /**
   * 注册引擎 → ArkTS 的同步查询分发器（被动同步查询）
   * @param handler 接收引擎同步查询并返回 JSON 字符串
   */
  SetOnQueryHandler(handler: OnQueryHandler): void;
}
