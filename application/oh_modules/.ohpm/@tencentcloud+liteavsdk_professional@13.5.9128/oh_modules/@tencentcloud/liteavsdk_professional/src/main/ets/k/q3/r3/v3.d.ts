import { TXVodDownloadMediaInfo } from "./p3";
export interface ITXVodDownloadCallback {
    /**
     * 下载开始
     * @param mediaInfo 下载对象
     */
    onDownloadStart(mediaInfo: TXVodDownloadMediaInfo): void;
    /**
     * 下载进度更新
     * @param mediaInfo 下载对象
     */
    onDownloadProgress(mediaInfo: TXVodDownloadMediaInfo): void;
    /**
     * 下载停止。调 TXVodDownloadManager.stopDownload 方法会收到此回调
     * @param mediaInfo 下载对象
     */
    onDownloadStop(mediaInfo: TXVodDownloadMediaInfo): void;
    /**
     * 下载结束。
     * @param mediaInfo 下载对象
     */
    onDownloadFinish(mediaInfo: TXVodDownloadMediaInfo): void;
    /**
     * 下载过程中遇到错误
     * @param mediaInfo 下载对象
     * @param error 错误码请参考 TXVodDownloadManager
     * @param reason 错误原因
     */
    onDownloadError(mediaInfo: TXVodDownloadMediaInfo, error: number, reason: string): void;
}
