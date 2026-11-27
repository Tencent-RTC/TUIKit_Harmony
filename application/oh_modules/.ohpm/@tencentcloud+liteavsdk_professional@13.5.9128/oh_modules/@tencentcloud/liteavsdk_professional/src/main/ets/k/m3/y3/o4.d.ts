import { TXCResolutionName, TXCPlayImageSpriteInfo, TXCPlayKeyFrameDescInfo, TXCEncryptedStreamingInfo } from "./z3";
/**
 * V4视频协议解析实现类
 *
 * 负责解析V4视频信息协议请求响应的Json数据
 */
export declare class TXCPlayInfoParserV4 {
    private response;
    name: string;
    url: string;
    description: string;
    coverUrl?: string;
    duration: number;
    size: number;
    waterMarkText?: string;
    encryptedStreamingInfoList?: TXCEncryptedStreamingInfo[];
    resolutionNameList: TXCResolutionName[];
    token: string;
    drmType: string;
    widevineLicenseUrl: string;
    imageSpriteInfo?: TXCPlayImageSpriteInfo;
    keyFrameDescInfo?: TXCPlayKeyFrameDescInfo[];
    private mIsAdvanced;
    constructor(response: JSON);
    parsePlayInfo(response: JSON): void;
    private parseSubStreams;
    private parseKeyFrameDescList;
    private parseWaterMarkInfo;
    /**
     * 获取视频播放url
     *
     * @param type 类型字符串
     * @returns url字符串
     */
    getUrl(type: string): string | null;
    /**
     * 获取加密视频播放url
     *
     * @param encryptType 加密类型字符串
     * @returns 加密的url字符串
     */
    getEncryptedUrl(d37: string): string;
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
    /**
     * 是否为Advanced加密级别
     *
     * @return 是否Advanced
     */
    isAdvanced(): boolean;
}
