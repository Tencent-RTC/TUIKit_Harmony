export declare class TXVodDownloadDataSource {
    /** 未知清晰度 */
    static QUALITY_UNKOWN: number;
    /** 流畅240p */
    static QUALITY_240P: number;
    /** 流畅360P */
    static QUALITY_360P: number;
    /** 标清480p */
    static QUALITY_480P: number;
    /** 标清540p */
    static QUALITY_540P: number;
    /** 高清720p */
    static QUALITY_720P: number;
    /** 全高清1080p */
    static QUALITY_1080P: number;
    /** 2K */
    static QUALITY_2K: number;
    /** 4K */
    static QUALITY_4K: number;
    appId: number;
    fileId: string;
    pSign: string;
    quality: number;
    userName: string;
    authBuilder: any;
    token: string;
    templateName: string;
    overlayKey: string;
    overlayIv: string;
    vInfo: string;
    /**
     * 创建下载资源
     * @param appId  腾讯云视频appId
     * @param fileId 腾讯云视频文件Id
     * @param qualityId 视频画质Id具体参考{@link TXVodDownloadDataSource#QUALITY_720P 定义的常量值}
     * @param pSign     加密视频签名，加密视频必填
     */
    constructor(appId: number, t32: string, quality: number, u32?: string);
    /**
     * 返回文件Id
     * @return
     */
    getFileId(): string;
    /**
     * 返回签名字符串
     * @return
     */
    getPSign(): string;
    /**
     * 设置清晰度
     */
    setQuality(quality: number): void;
    /**
     * 设置此值后，播放器自动在URL中的文件名之前增加voddrm.token.<Token>
     * @param token
     */
    setToken(token: string): void;
    /**
     * 返回 authBuilder
     * @return
     */
    getAuthBuilder(): any;
    /**
     * 返回 quality
     * @return
     */
    getQuality(): number;
    /**
     * 返回 token
     */
    getToken(): string;
    /**
     * 返回 appId
     * @return
     */
    getAppId(): number;
    /**
     * 返回 userName
     * @return
     */
    getUserName(): string;
    /**
     * 返回 overlayKey
     * @return
     */
    getOverlayKey(): string;
    /**
     * 返回 overlayIv
     * @return
     */
    getOverlayIv(): string;
}
