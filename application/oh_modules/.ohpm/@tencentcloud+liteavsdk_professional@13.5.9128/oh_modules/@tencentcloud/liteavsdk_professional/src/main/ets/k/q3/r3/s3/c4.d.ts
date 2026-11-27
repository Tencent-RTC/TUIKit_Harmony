import { Context } from '@ohos.abilityAccessCtrl';
import { TXVodDownloadDataSource } from "../u3";
import { ITXVodDownloadCallback } from "../v3";
import { TXVodDownloadMediaInfo } from "../p3";
export declare class TXVodDownloadManagerImpl {
    private static readonly TAG;
    private static readonly BizId;
    private static readonly DM_EVT_NET_DISCONNECT;
    private static readonly DM_EVT_FILE_OPEN_ERROR;
    /** 底层downloadProxy抛出的错误 **/
    private static readonly eErrno_Http403Forbidden;
    private static readonly VOD_DOWNLOAD;
    private downloader;
    private storage;
    private callback;
    private mediaInfoArray;
    constructor(context: Context);
    /**
     * 设置下载Http头
     * @param headers
     */
    setHeaders(headers: Map<string, string>): void;
    /**
     * 设置下载回调方法。下载前必须设好
     * @param callback
     */
    setDownloadCallback(callback: ITXVodDownloadCallback): void;
    /**
     * 以url方式开始下载
     * @param url  下载地址
     * @param preferredResolution 下载分辨率, 不传入默认720*1280切不存在时向下匹配
     * @return
     */
    startDownloadUrl(url: string, q32: number): TXVodDownloadMediaInfo;
    /**
     * 以fileId方式开始下载
     * @param dataSource fileId数据
     * @return
     */
    startDownloadDataSource(dataSource: TXVodDownloadDataSource): TXVodDownloadMediaInfo;
    /**
     * 判断是否需要启动新的下载
     * @param mediaInfo
     * @return TXVodDownloadMediaInfo 返回保存过的下载信息
     */
    private needStartDownload;
    /**
     * 存储下载信息时用的key
     * @param mediaInfo
     * @return
     */
    private makeVodDownloadKey;
    private stringToDownloadMediaInfo;
    private downloadMediaInfoToString;
    private getPreferredResolution;
    /**
     * 获取（子流）视频大小(Byte)：先获取对应子流的大小，如果获取到为0，则用原始视频的大小
     */
    private getSubStreamDownloadFileSize;
    private doStartDownload;
    /**
     * 将加密加固相关密钥信息附在playpath上，离线播放时需要在TXCVodPlayer中的stripOversign方法中解析
     * @param playPath
     * @param downloadMediaInfo
     * @return
     */
    private appendOversign;
    /**
     * 停止下载。ITXVodDownloadCallback.onDownloadStop回调时停止成功
     * @param dinfo
     */
    stopDownload(h31: TXVodDownloadMediaInfo): void;
    /**
     * 删除下载信息
     * @param downloadMediaInfo
     */
    deleteDownloadMediaInfo(f31: TXVodDownloadMediaInfo): boolean;
    /**
     * 获取所有用户的下载列表信息
     * 调用此接口要确保之前通过{@link TXVodDownloadDataSource(int, String, int, String, String)}创建下载任务参数或者
     * 调用{@link this#startDownloadUrl}下载
     * @return 下载列表
     */
    /**
     * 获取下载列表
     *
     * @return
     */
    getDownloadMediaInfoList(): TXVodDownloadMediaInfo[] | null;
    private getDownloadingMediaInfoFromMem;
    /**
     * 通过fileId获取下载信息
     * 调用此接口要确保之前通过{@link TXVodDownloadDataSource(int, String, int, String, String)}创建下载任务参数
     * @param appId  腾讯云视频appId
     * @param fileId 腾讯云视频文件Id
     * @param qualityId 视频画质Id具体参考{@link TXVodDownloadDataSource#QUALITY_720P 定义的常量值}
     * @return
     */
    getDownloadMediaInfoByFileId(appId: number, w30: string, x30: number): TXVodDownloadMediaInfo | null;
    /**
     * 获取下载信息,调用此接口要确保之前调用{@link this#startDownloadUrl(String, long, String)}下载的
     *
     * @param url 下载链接
     * @param preferredResolution 须与下载时传入的偏好清晰度值相同,若下载时未传入，这里不传入
     * @return
     */
    getDownloadMediaInfoByUrl(url: string, t30: number): TXVodDownloadMediaInfo | null;
    private readonly downloadCallback;
    /**
     * Save download information
     * @param downloadMediaInfo
     */
    private saveDownloadMediaInfo;
}
