/**
 * 通用信息回调接口
 * 对应 platform/android/TPDownloadProxy/src/main/java/com/tencent/thumbplayer/core/datatransport/api/ITPDataTransportCommonInfoListener.java
 */
export interface TPDataTransportCommonInfoListener {
    onCommonInfoUpdate(messageInfoType: TPDataTransportMessageInfoType, messageInfo: TPDataTransportMessageInfo): Promise<void>;
}
/**
 * Common 消息的回调信息
 */
export interface TPDataTransportMessageInfo {
    readonly taskId: number;
    readonly messageType: TPDataTransportMessageInfoType;
    readonly obj1?: unknown;
    readonly obj2?: unknown;
    readonly obj3?: unknown;
    readonly obj4?: unknown;
}
export declare enum TPDataTransportMessageInfoType {
    /**
     * url 过期统一回调，把边下边播转在线播放、cdn url 过期处理逻辑相同
     * @param {Record<string,string>} obj1 透传参数信息
     */
    CdnUrlExpired = 1,
    /**
     * 通知播放器切换清晰度
     * @param {string} obj1 vid
     * @param {string} obj2 msg_Info
     * @param {number} obj3 speed_kbytes
     */
    NotifyPlayerSwitchDefinition = 2,
    /**
     * HTTP请求头、响应头信息
     * @param {string} obj1 header info
     */
    HttpHeader = 3,
    /**
     * M3U8 内容回调
     * @param {string} exInfo
     */
    NotifyM3u8Content = 4,
    /**
     * http-flv 预下载完成回调
     * @param {number} obj1 status
     * @param {Uint8Array} obj2 codec param
     * @param {string} obj3 exInfo
     * @param {number} obj4 len
     */
    FlvPreloadStatus = 5,
    /**
     * QUIC 下载状态回调
     * @param {string} obj1 exInfo
     */
    QuicDownloadStatus = 6,
    /**
     * Quic 回调上报信息
     */
    QuicReportQuality = 7,
    /**
     * TAB 实验 ID
     * @param {string} obj1 msg_info
     * @param {string} obj2 exInfo
     */
    TabTestId = 8,
    /**
     * 通知播放器刷新 m3u8 buffer
     */
    M3u8Refresh = 9,
    /**
     * 多网卡命中低速
     * @param {string} obj1 extraInfo
     */
    MultiNetworkLowSpeed = 10,
    /**
     * 多网卡使用状态
     * @param ext1 String extraInfo
     */
    MultiNetworkStatus = 11,
    /**
     * 通知播放器读数据异常
     */
    ReadInvalid = 12,
    /**
     * 开始请求 cdn url，请求的结果在 MESSAGE_REQUEST_CDN_URL_COMPLETE 中回调
     * @param {string} obj1 CDN URL
     */
    StartRequestCdnUrl = 13,
    /**
     * 完成 cdn 请求，成功、失败都会回调
     * @param {string} obj1 CDN URL
     * @param {string} obj2 CDN HTTP header "X-ServerIp
     * @param {string} obj3 CDN HTTP header "Client-Ip"
     * @param {string} obj4 errorCodeStr 获取不到时，上报错误码
     */
    RequestCdnUrlComplete = 14,
    /**
     * 数据下载状态更新，实时更新数据下载情况，可用于二次缓冲原因上报，非 0 表示具体异常原因 上报用
     * @param {number} obj1 errorCode
     */
    OnDownloadStatusUpdate = 15,
    /**
     * 下载协议相关信息回调，使用 quic/tcp 上报用
     * @param {string} obj1 protocol 协议类型
     * @param {string} obj2 protocolVer 协议版本号
     */
    DownloadProtocolUpdate = 16,
    /**
     * 把边下边播转在线播放
     */
    NoMoreData = 17,
    /**
     * 跟 iOS 对齐，Android 目前没用
     * 回前台后，通知播放器本地代理初始化完毕。播放任务需要等本地代理初始化完后，才能发起播放请求
     */
    ReInit = 18,
    /**
     * 跟 iOS 对齐，Android 目前没用
     * 正在播放任务退后台，下载组件调用析构前通知播放器
     */
    DeInit = 19,
    /**
     * 本地代理 token 校验失败
     * @param {number} obj1 errorCode
     */
    VerifyTokenFailed = 20,
    /**
     * 更新下一个分片信息，主要用在轮播场景
     */
    UpdateNextClip = 21,
    /**
     * 支持多网卡的通用CGI请求结果成功回调
     * @param {number} obj1 http_status_code，http 返回码
     * @param {string} obj2 http_response_header，http响应头
     * @param {string} obj3 content，返回内容
     * @param {string} obj4 extInfo，拓展信息，JSON 格式字符串，目前包含实际请求的网卡信息
     */
    MultiNetworkCgiSucceed = 22,
    /**
     * 支持多网卡的通用CGI请求结果失败回调
     * @param {number} obj1 error_code，错误码
     * @param {string} obj2 extInfo，拓展信息，JSON 格式字符串，目前包含 HTTP 状态码状态码字段是 "httpStatusCode"
     */
    MultiNetworkCgiFailed = 23,
    /**
     * 低清晰度策略，通知播放器无缝上切
     */
    LowDefinitionStartSwitchUp = 24,
    /**
     * 通知播放器重新请求CDN下载
     */
    ReplayCdn = 25,
    /**
     * 伪直播当前片播放完时回调
     */
    SimulateLiveEndOfCurrentClip = 26
}
