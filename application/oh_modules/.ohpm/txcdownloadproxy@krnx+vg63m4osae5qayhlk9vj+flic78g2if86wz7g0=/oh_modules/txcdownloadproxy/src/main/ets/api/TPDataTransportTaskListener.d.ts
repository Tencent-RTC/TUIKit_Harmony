import { TPDataTransportMessageInfo } from './ITPDataTransportCommonInfoListener';
export interface TPDataTransportTaskListener {
    /**
     * 下载进程信息更新
     *
     * @param taskId {@link #createTask} 返回的 id
     * @param playableDurationMs 可播时长，单位：毫秒 hls 播放时可以返回准确的可播时长，其他格式不可用
     * @param downloadSpeedKBytes 下载速度 KB/s
     * @param currentDownloadSizeByte 当前下载字节数
     * @param totalFileSizeByte 总字节数，有 vinfo 时一般通过 vinfo 获取总文件大小，其他情况可能没有
     * @param exInfo 扩展信息
     */
    onDownloadProgressUpdate(taskId: number, playableDurationMs: number, downloadSpeedKBytes: number, currentDownloadSizeByte: number, totalFileSizeByte: number, exInfo: string): Promise<void>;
    /**
     * 视频数据全部下载完成
     *
     * @param taskId {@link #createTask} 返回的 id
     */
    onDownloadFinished(taskId: number): Promise<void>;
    /**
     * 错误回调
     *
     * @param taskId {@link #createTask} 返回的 id
     * @param moduleId 模块ID
     * @param errorCode 错误码
     * @param extInfo 扩展信息
     */
    onDownloadError(taskId: number, moduleId: number, errorCode: number, extInfo: string): Promise<void>;
    /**
     * 通用回调接口
     *
     * @param taskId {@link #createTask} 返回的 id
     * @param type 消息类型 {@link TPDataTransportCommonInfoMessageType}
     * @param info 消息内容
     */
    onCommonInfoMessage(taskId: number, type: number, info: TPDataTransportMessageInfo): Promise<void>;
    /*****************************获取播放信息接口************************************/
    /**
     * 获取播放器剩余缓冲数据长度。
     *
     * @param taskId {@link #createTask} 返回的 id
     * @return 缓存时长，单位毫秒
     */
    getPlayerBufferLength(taskId: number): number;
    /**
     * 获取当前的播放时间点
     *
     * @param taskId {@link #createTask} 返回的 id
     * @return 播放点，单位毫秒
     */
    getCurrentPosition(taskId: number): number;
    /**
     * 获取当前的播放偏移量
     *
     * @param taskId {@link #createTask} 返回的 id
     * @return 播放偏移量，单位byte
     */
    getCurrentPlayOffset(taskId: number): number;
    /**
     * 获取距离开始播放倒计时时间
     *
     * @param taskId {@link #createTask} 返回的 id
     * @return 倒计时时间，单位：ms
     */
    getRemainTimeBeforePlayMs(taskId: number): number;
}
