/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMOfflinePushConfig } from "../../../Index";
/**
 * 腾讯云通信服务 IMSDK
 *
 * 离线推送的接口
 */
export declare class V2TIMOfflinePushManager {
    /**
     * 设置离线推送配置信息
     *
     * 如果您想关闭离线推送，请把 config 设置为 undefined。
     */
    setOfflinePushConfig(config?: V2TIMOfflinePushConfig): Promise<void>;
    /**
     * APP 检测到应用退后台时可以调用此接口
     *
     * - 从 6.1 版本开始，如果配置了离线推送，会收到厂商或 TPNS 的离线推送通道下发的通知栏消息。
     */
    doBackground(): Promise<void>;
    /**
     * APP 检测到应用进前台时可以调用此接口
     *
     * - 从 6.1 版本开始，调用 doForeground，会停止离线推送。但如果应用被 kill，仍然可以正常接收离线推送。
     */
    doForeground(): Promise<void>;
}
