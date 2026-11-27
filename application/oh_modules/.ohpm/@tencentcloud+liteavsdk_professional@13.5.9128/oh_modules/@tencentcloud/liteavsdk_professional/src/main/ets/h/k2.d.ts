/**
 * Copyright (c) 2021 Tencent. All rights reserved.
 * Module:   V2TXLivePremier @ TXLiteAVSDK
 * Function: V2TXLive 高级接口
 */
import { Context } from '@ohos.abilityAccessCtrl';
import { V2TXLiveLogConfig, V2TXLiveLogLevel } from "./o2";
/**
 * 获取 V2TXLivePremier 实例
 *
 * 你可以按照下列方式创建 V2TXLivePremier Instance。
 * <pre>
 * let context: Context = getContext();
 * let premier: V2TXLivePremier = getV2TXLivePremierShareInstance(context);
 * </pre>
 */
export declare function getV2TXLivePremierShareInstance(context?: Context): V2TXLivePremier;
export interface V2TXLivePremier {
    /**
     * 获取 SDK 版本号
     */
    getSDKVersionStr(): string;
    /**
     * 设置 V2TXLivePremier 回调接口
     */
    setObserver(observer: V2TXLivePremierObserver): void;
    /**
     * 设置 Log 的配置信息
     */
    setLogConfig(config: V2TXLiveLogConfig): void;
    /**
     * 设置 SDK 接入环境
     *
     * @note 如您的应用无特殊需求，请不要调用此接口进行设置。
     * @param env 目前支持 “default” 和 “GDPR” 两个参数。
     *        - default：默认环境，SDK 会在全球寻找最佳接入点进行接入。
     *        - GDPR：所有音视频数据和质量统计数据都不会经过中国大陆地区的服务器。
     */
    setEnvironment(env: string): void;
    /**
     * 设置 SDK 的授权 License
     *
     * 文档地址：https://cloud.tencent.com/document/product/454/34750。
     * @param url licence 的地址。
     * @param key licence 的秘钥。
     */
    setLicence(url: string, key: string): void;
    /**
     * 设置 userId
     *
     * @param userId 业务侧自身维护的用户/设备id。
     */
    setUserId(userId: string): void;
    /**
     * 调用实验性 API 接口
     *
     * @note  该接口用于调用一些实验性功能。
     * @param jsonStr 接口及参数描述的 JSON 字符串。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     *         - V2TXLIVE_ERROR_INVALID_PARAMETER: 操作失败，参数非法。
     */
    callExperimentalAPI(jsonStr: string): number;
}
export interface V2TXLivePremierObserver {
    /**
     * 自定义 Log 输出回调接口
     */
    onLog?: (level: V2TXLiveLogLevel, log: string) => void;
    /**
     * setLicence 接口回调
     *
     * @param result 设置 licence 结果 0 成功，负数失败。
     * @param reason 设置 licence 失败原因。
     */
    onLicenceLoaded?: (result: number, reason: string) => void;
}
