import { TXPlayInfoParams } from "../../q3/x3";
/**
 * V4视频信息协议实现类
 * <p>
 * 负责V4视频信息协议的请求控制与数据获取
 * @author serenazhou
 */
export declare class TXCPlayInfoProtocolV4 {
    private static readonly TAG;
    private static readonly DEFAULT_HOSTS;
    private static readonly DEFAULT_PROTOCOL;
    private static readonly DEFAULT_PATH;
    static readonly ENCRPT_TYPE_PLAIN = "plain";
    static readonly ENCRPT_TYPE_SIMPLE_AES = "SimpleAES";
    static readonly ENCPRT_TYPE_FAIRPLAY = "FairPlay";
    static readonly ENCPRT_TYPE_Widevine = "Widevine";
    private playInfoParams;
    private parser?;
    private parserV2?;
    private version;
    private requestContext?;
    private overlayInfo;
    private vInfo;
    private hosts;
    private currentHostIndex;
    private static validHost;
    /**
     * 播放器请求协议
     *
     * @param 请求参数
     */
    constructor(params: TXPlayInfoParams);
    /**
     * 发送视频信息协议网络请求，获取播放链接
     *
     * @param callback 协议请求回调
     */
    sendRequest(callback: IPlayInfoRequestCallback): void;
    private doSendRequest;
    private handleError;
    /**
     * 解析视频信息协议请求响应的Json数据
     *
     * @param content  响应Json字符串
     * @param headers 协议请求回调
     */
    private parseJson;
    /**
     * 1 jsonbody 为回包 json 内容，overlayKey、overlayIv 是通过 cipheredOverlayKey、cipheredOverlayIv 解密得到的对称密钥
     * 2 checksum=md5(overlayKey+overlayIv+jsonbody), 并在回包 Header 中返回，字段名为 X-Vod-Checksum
     * 3 如果缺少 overlayKey、overlayIv，则不会计算 checksum。
     * 4 获取到 PlayCGI 回包后，则计算校验和，如果和回包 Header 中的 X-Vod-Checksum 一致, 则数据校验通过
     */
    private checkResponseDataValid;
    /**
     * 判断是否能切换host
     * @return
     */
    canSwitchHost(): boolean;
    /**
     * 拼装协议请求url
     *
     * @returns 协议请求url字符串
     */
    makeUrlString(): string;
    /**
     * 拼装协议请求url中的query字段
     *
     * @param pcfg 配置参数
     * @param psign 签名参数
     * @param content 上下文参数
     * @returns query字段字符串
     */
    private makeQueryString;
    private appendOverlayKeyIv;
    /**
     * 获取视频播放url
     *
     * @param type 类型字符串
     * @returns url字符串
     */
    getUrl(type: string): string;
    /**
     * 获取token
     *
     * @returns token字符串或null
     */
    getToken(): string;
    getName(): string;
    /**
     * 获取视频描述
     *
     * @return 视频描述
     */
    getDescription(): string;
    /**
     * 获取封面链接
     *
     * @return 封面链接
     */
    getCoverUrl(): string;
    /**
     * 获取视频播放时长
     *
     * @return 视频播放时长
     */
    getDuration(): number;
    /**
     * 获取视频size(byte)
     * @return
     */
    getSize(): number;
    /**
     * 获取雪碧图信息
     *
     * @return 雪碧图信息对象
     */
    getImageSpriteInfo(): TXCPlayImageSpriteInfo;
    /**
     * 获取关键帧信息
     *
     * @return 关键帧信息数组
     */
    getKeyFrameDescInfo(): TXCPlayKeyFrameDescInfo[];
    /**
     * 获取视频画质别名列表
     *
     * @return 画质别名数组
     */
    getResolutionNameList(): TXCResolutionName[];
    /**
     * 获取DRM类型
     *
     * @return DRM类型字符串
     */
    getDRMType(): string;
    /**
     * 获取密钥许可证URL
     *
     * @return 密钥许可证URL字符串或null
     */
    getKeyLicenseUrl(): string;
    /**
     * 获取水印文本
     *
     * @return 水印文本字符串
     */
    getWaterMarkText(): string;
    getOverlayInfo(): TXCOverlayInfo;
    getPenetrateContext(): string;
    getVInfo(): string;
    isAdvanced(): boolean;
}
export declare class TXCOverlayInfo {
    overlayKey: string;
    overlayIv: string;
    cipheredOverlayKey: string;
    cipheredOverlayIv: string;
}
export declare class TXCResolutionName {
    name: string;
    width: number;
    height: number;
    type: string;
    size: number;
    url: string;
}
export declare class TXCPlayImageSpriteInfo {
    imageUrls: Array<string>;
    webVttUrl: string;
}
export declare class TXCPlayKeyFrameDescInfo {
    content: string;
    time: number;
    toString(): string;
}
/**
 * 自适应码流信息
 */
export declare class TXCEncryptedStreamingInfo {
    drmType: string;
    urlStr: string;
}
/**
 * 视频信息协议请求回调接口
 */
export interface IPlayInfoRequestCallback {
    onSuccess(protocol: TXCPlayInfoProtocolV4, params: TXPlayInfoParams): void;
    onError(errCode: number, message: string): void;
}
/**
 * http回调
 */
export interface OnHttpCallback {
    onSuccess(data: string, headers: Object): void;
    onError(err: string): void;
}
