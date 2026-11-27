/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMLogListener } from "./V2TIMListener";
/**
 * （一）枚举值定义
 */
/**
 * 登录状态
 */
export declare enum V2TIMLoginStatus {
    /**
     * 已登录
     */
    V2TIM_STATUS_LOGINED = 1,
    /**
     * 登录中
     */
    V2TIM_STATUS_LOGINING = 2,
    /**
     * 无登录
     */
    V2TIM_STATUS_LOGOUT = 3
}
/**
 * 日志级别
 */
export declare enum V2TIMLogLevel {
    /**
     * 不输出任何 sdk log
     */
    V2TIM_LOG_NONE = 0,
    /**
     * 输出 DEBUG，INFO，WARNING，ERROR 级别的 log
     */
    V2TIM_LOG_DEBUG = 3,
    /**
     * 输出 INFO，WARNING，ERROR 级别的 log
     */
    V2TIM_LOG_INFO = 4,
    /**
     * 输出 WARNING，ERROR 级别的 log
     */
    V2TIM_LOG_WARN = 5,
    /**
     * 输出 ERROR 级别的 log
     */
    V2TIM_LOG_ERROR = 6
}
/**
 * 消息接收选项
 */
export declare enum V2TIMReceiveMessageOpt {
    /**
     * 在线正常接收消息，离线时会进行 APNs 推送
     */
    V2TIM_RECEIVE_MESSAGE = 0,
    /**
     * 不会接收到消息，离线不会有推送通知
     */
    V2TIM_NOT_RECEIVE_MESSAGE = 1,
    /**
     * 在线正常接收消息，离线不会有推送通知
     */
    V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE = 2,
    /**
     * 在线接收消息，离线只接收@消息的推送
     */
    V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT = 3,
    /**
     * 在线和离线都只接收@消息
     */
    V2TIM_NOT_RECEIVE_MESSAGE_EXCEPT_AT = 4
}
/**
 * 搜索关键字匹配类型
 */
export declare enum V2TIMKeywordListMatchType {
    V2TIM_KEYWORD_LIST_MATCH_TYPE_OR = 0,
    V2TIM_KEYWORD_LIST_MATCH_TYPE_AND = 1
}
/**
 * （二）对象类型定义
 */
/**
 * SDK 配置
 */
export interface V2TIMSDKConfig {
    /**
     * 本地写 log 文件的等级，默认 DEBUG 等级， IMSDK 的日志默认存储于程序文件的运行目录下
     */
    logLevel?: V2TIMLogLevel;
    /**
     * log 监听回调（回调在主线程，日志回调可能比较频繁，请注意不要在回调里面同步处理太多耗时任务，可能会堵塞主线程）
     */
    logListener?: V2TIMLogListener;
}
