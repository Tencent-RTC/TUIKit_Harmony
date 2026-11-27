import { Context } from '@ohos.abilityAccessCtrl';
import { TXVodDownloadDataSource } from "./u3";
import { TXVodDownloadMediaInfo } from "./p3";
import { ITXVodDownloadCallback } from "./v3";
export declare class TXVodDownloadManager {
    static readonly DOWNLOAD_FORMAT_ERROR = -5004;
    static readonly DOWNLOAD_DISCONNECT = -5005;
    static readonly DOWNLOAD_PATH_ERROR = -5007;
    static readonly DOWNLOAD_403FORBIDDEN = -5008;
    private static instance;
    private managerImpl;
    private constructor();
    /**
     * 下载管理器
     * @return 管理器实例
     */
    static getInstance(context: Context): TXVodDownloadManager;
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
     * @param preferredResolution 下载分辨率, 默认720*1280切不存在时向下匹配
     * @return
     */
    startDownloadUrl(url: string, a33?: number): TXVodDownloadMediaInfo;
    /**
     * 以fileId方式开始下载
     * @param dataSource fileId数据
     * @return
     */
    startDownloadDataSource(dataSource: TXVodDownloadDataSource): TXVodDownloadMediaInfo;
    /**
     * 停止下载。ITXVodDownloadCallback.onDownloadStop回调时停止成功
     * @param dinfo
     */
    stopDownload(z32: TXVodDownloadMediaInfo): void;
    /**
     * 删除下载信息。不支持删除正在下载的任务
     * @param downloadMediaInfo
     */
    deleteDownloadMediaInfo(y32: TXVodDownloadMediaInfo): boolean;
    /**
     * 同步获取所有下载列表信息。耗时操作, 建议worker线程中调用
     * 调用此接口要确保之前通过{@link TXVodDownloadDataSource(int, String, int, String, String)}创建下载任务参数或者
     * 调用{@link this#startDownloadUrl}下载
     * @return 下载列表
     */
    syncGetDownloadMediaInfoList(): TXVodDownloadMediaInfo[];
    /**
     * 通过fileId同步获取下载信息。耗时操作, 建议worker线程中调用
     * 调用此接口要确保之前通过{@link TXVodDownloadDataSource(int, String, int, String, String)}创建下载任务参数
     * @param appId  腾讯云视频appId
     * @param fileId 腾讯云视频文件Id
     * @param qualityId 视频画质Id具体参考{@link TXVodDownloadDataSource#QUALITY_720P 定义的常量值}
     * @return
     */
    syncGetDownloadMediaInfoByFileId(appId: number, w32: string, x32: number): TXVodDownloadMediaInfo | null;
    /**
     * 通过url同步获取下载信息。耗时操作, 建议worker线程中调用
     * 调用此接口要确保之前调用{@link this#startDownloadUrl(String, long, String)}下载的
     *
     * @param url 下载链接
     * @param preferredResolution 须与下载时传入的偏好清晰度值相同,若下载时未传入，这里不传入
     * @return
     */
    syncGetDownloadMediaInfoByUrl(url: string, v32?: number): TXVodDownloadMediaInfo | null;
}
