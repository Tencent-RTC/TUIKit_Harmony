import { Context } from '@ohos.abilityAccessCtrl';
import { TXVodDownloadMediaInfo } from "../p3";
export declare class ThumbPlayerDownloader {
    private static readonly TAG;
    private static readonly BizId;
    private offlineTaskMgr;
    private headers?;
    private downloadPath;
    private downloadCallback;
    constructor(context: Context);
    setDownloadCallback(g30: OnDownloadCallback): void;
    setHeaders(headers: Map<string, string>): void;
    makePlayPath(url: string): string;
    stop(e30: TXVodDownloadMediaInfo): void;
    deleteDownloadFile(a30: TXVodDownloadMediaInfo): boolean;
    getResourceDownloadProgress(w29: TXVodDownloadMediaInfo): number;
    checkResourceExist(s29: TXVodDownloadMediaInfo): boolean;
    startDownload(e29: TXVodDownloadMediaInfo): number;
}
export interface OnDownloadCallback {
    downloadBegin(downloader: ThumbPlayerDownloader, downloadMediaInfo: TXVodDownloadMediaInfo): void;
    downloadStop(downloader: ThumbPlayerDownloader, downloadMediaInfo: TXVodDownloadMediaInfo): void;
    downloadFinish(downloader: ThumbPlayerDownloader, downloadMediaInfo: TXVodDownloadMediaInfo): void;
    downloadError(downloader: ThumbPlayerDownloader, downloadMediaInfo: TXVodDownloadMediaInfo, error: number, reason: string): void;
    downloadProgress(downloader: ThumbPlayerDownloader, downloadMediaInfo: TXVodDownloadMediaInfo): void;
}
