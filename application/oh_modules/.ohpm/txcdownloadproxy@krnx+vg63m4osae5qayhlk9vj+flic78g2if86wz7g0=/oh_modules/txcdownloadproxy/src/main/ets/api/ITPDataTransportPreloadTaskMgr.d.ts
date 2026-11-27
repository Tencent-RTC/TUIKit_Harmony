import { TPDataTransportTaskParam } from './TPDataTransportTaskParam';
import { TPDataTransportTaskOptionalConfigParam } from './TPDataTransportEnum';
export interface ITPDataTransportPreloadTaskMgr {
    /**
     * 普通预下载下载任务
     *
     * @taskParam taskParam 下载任务相关参数
     * @param preloadTaskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createPreloadTask(taskParam: TPDataTransportTaskParam, preloadTaskListener: TPDataTransportPreloadTaskListener): number;
    /**
     * 启动预下载任务 yunxiao
     * @param taskId {@link #createPreloadTask} 创建的预下载任务 id
     * @param taskId
     */
    startPreloadTask(taskId: number): void;
    /**
     * @param taskId {@link #createPreloadTask} 创建的预下载任务 id
     */
    stopPreloadTask(taskId: number): void;
    /**
     * 任务创建后，可以更新任务相关的配置参数
     *
     * @param taskId {@link #createPreloadTask} 创建的预下载任务 id
     * @param key {@link TaskOptionalConfigParam}
     * @param value
     */
    setPreloadTaskOptionalConfigParam(taskId: number, key: TPDataTransportTaskOptionalConfigParam, value: string): void;
}
export interface TPDataTransportPreloadTaskListener {
    /**
     * 预下载进度
     *
     * @param taskId {@link #createPreloadTask} 创建任务返回的 id
     * @param playableDurationMs 可播时长，单位：毫秒 hls 播放时可以返回准确的可播时长，其他格式不可用
     * @param downloadSpeedKBytes 下载速度 KB/s
     * @param currentDownloadSizeByte 当前下载字节数
     * @param totalFileSizeByte 总字节数，有 vinfo 时一般通过 vinfo 获取总文件大小，其他情况可能没有
     * @param exInfo 扩展信息
     */
    onDownloadProgressUpdate(taskId: number, playableDurationMs: number, downloadSpeedKBytes: number, currentDownloadSizeByte: number, totalFileSizeByte: number, exInfo: string): Promise<void>;
    /**
     * 预下载完成
     *
     * @param taskId {@link #createPreloadTask} 创建任务返回的 id
     */
    onDownloadFinished(taskId: number): Promise<void>;
    /**
     * 预下载失败
     *
     * @param taskId {@link #createPreloadTask} 创建任务返回的 id
     * @param moduleId 模块ID
     * @param errorCode 错误码
     * @param extraInfo 扩展信息
     */
    onDownloadError(taskId: number, moduleId: number, errorCode: number, extraInfo: string): Promise<void>;
}
