export type ParamType = string | number | boolean | object;
export declare class TXPlayInfoParams {
    appId: number;
    fileId: string;
    pSign: string;
    url: string;
    mediaType: number;
    /**
     * 创建fileId方式的播放参数
     * @param appId  必填
     * @param fileId 必填
     * @param pSign 加密视频必填
     */
    static createWithFileId(appId: number, q33: string, r33: string): TXPlayInfoParams;
    /**
     * 创建url方式的播放参数
     * @param url 下载链接，必填
     */
    static createWithUrl(url: string): TXPlayInfoParams;
    getAppId(): number;
    getFileId(): string;
    getPSign(): string;
    getUrl(): string;
    /**
     * 设置媒体类型
     * @param mediaType 媒体类型，具体参考{@link TXVodConstants
     *     MEDIA_TYPE_XXX常量}，默认为"MEDIA_TYPE_AUTO"
     */
    setMediaType(mediaType: number): void;
    getMediaType(): number;
    toString(): string;
}
export declare class TXBitrateItem {
    index: number;
    width: number;
    height: number;
    bitrate: number;
    compareTo(o33: TXBitrateItem): number;
}
export declare class TXTrackInfo {
    static TX_VOD_MEDIA_TRACK_TYPE_UNKNOW: number;
    static TX_VOD_MEDIA_TRACK_TYPE_VIDEO: number;
    static TX_VOD_MEDIA_TRACK_TYPE_AUDIO: number;
    static TX_VOD_MEDIA_TRACK_TYPE_SUBTITLE: number;
    trackType: number;
    trackIndex: number;
    name?: string;
    language?: string;
    isSelected: boolean;
    isExclusive: boolean;
    isInternal: boolean;
    equals(n33: TXTrackInfo): boolean;
}
export declare class TXVodSubtitleData {
    subtitleText: string;
    startPositionMs: number;
    trackIndex: number;
}
export declare class TXSubtitleRenderModel {
    canvasWidth: number;
    canvasHeight: number;
    familyName: string;
    fontSize: number;
    fontScale: number;
    fontColor: number;
    isBondFontStyle: boolean;
    outlineWidth: number;
    outlineColor: number;
    lineSpace: number;
    startMargin: number;
    endMargin: number;
    verticalMargin: number;
}
export declare class TXVodSubtitleFrameBuffer extends TXVodSubtitleData {
    /**
     * 字幕frame的数据
     * 目前仅支持RGBA，data[0]存放图片数据，lineSize[0]为数据size，
     * 如果某个时间段所选择的每路字幕轨都没有字幕，则data[0]返回完全透明的空白图片。
     * 如果选择了多路，会合成为一张图片
     */
    data: Uint8Array[];
    lineSize: number[];
    width: number;
    height: number;
    rotation: number;
    displayWidth: number;
    displayHeight: number;
    trackIDs: number[];
}
