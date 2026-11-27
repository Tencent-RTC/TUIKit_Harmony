import { TXVodDownloadDataSource } from "./u3";
export declare class TXVodDownloadMediaInfo {
    static readonly STATE_INIT = 0;
    static readonly STATE_START = 1;
    static readonly STATE_STOP = 2;
    static readonly STATE_ERROR = 3;
    static readonly STATE_FINISH = 4;
    dataSource: TXVodDownloadDataSource | null;
    userName: string;
    duration: number;
    playableDuration: number;
    totalSize: number;
    playableSize: number;
    progress: number;
    segments: number;
    downloadSegments: number;
    playPath: string | null;
    url: string | null;
    tid: number;
    downloadState: number;
    preferredResolution: number;
    speed: number;
    isResourceBroken: boolean;
    /**
     * fileid下载对象
     * @return
     */
    getDataSource(): TXVodDownloadDataSource;
    /**
     * 总时长,单位ms
     * @return
     */
    getDuration(): number;
    /**
     * 已下载的可播放时长,单位ms
     * @return
     */
    getPlayableDuration(): number;
    /**
     * 文件总大小，单位byte。m3u8只针对以fileid视频源有效。
     * @return long
     */
    getSize(): number;
    /**
     * 已下载大小，单位byte。m3u8只针对以fileid视频源有效。
     * @return long
     */
    getDownloadSize(): number;
    /**
     * 下载进度
     * @return
     */
    getProgress(): number;
    /**
     * 播放路径，可传给TXVodPlayer播放
     * @return
     */
    getPlayPath(): string;
    /**
     * 任务id。可唯一表示下载任务
     * @return
     */
    getTaskId(): number;
    /**
     * 实际下载地址
     * @return
     */
    getUrl(): string;
    /**
     * 获取下载账户名称
     * @return
     */
    getUserName(): string;
    /**
     * 获取下载状态
     */
    getDownloadState(): number;
    /**
     * 获取偏好分辨率
     * @return
     */
    getPreferredResolution(): number;
    /**
     * 是否下载完成
     * @return
     */
    isDownloadFinished(): boolean;
    /**
     * 获取下载速度，单位：KByte/秒
     * @return
     */
    getSpeed(): number;
}
