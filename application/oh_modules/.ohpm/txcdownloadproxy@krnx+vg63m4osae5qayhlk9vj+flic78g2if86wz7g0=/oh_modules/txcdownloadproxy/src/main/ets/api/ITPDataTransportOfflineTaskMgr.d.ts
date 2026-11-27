import { TPDataTransportTaskParam } from './TPDataTransportTaskParam';
export interface ITPDataTransportOfflineTaskMgr {
    /**
     * 普通离线下载任务，数据会默认缓存到磁盘
     *
     * @taskParam taskParam 下载任务相关参数
     * @param taskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createOfflineTask(taskParam: TPDataTransportTaskParam, taskListener: TPDataTransportOfflineTaskListener): number;
    /**
     * 多分片任务离线下载，所有任务 url 将看被作互相关联在一起
     *
     * @taskParam taskParam 多个下载任务参数集
     * @param taskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createMultiOfflineTask(taskParam: Array<TPDataTransportTaskParam>, taskListener: TPDataTransportOfflineTaskListener): number;
    /**
     * 开始离线下载任务
     *
     * @param taskId {@link #createOfflineTask} 创建返回的任务 id
     */
    startOfflineTask(taskId: number): void;
    /**
     * 停止离线任务下载，已缓存的数据不会删除，重新创建任务可以继续下载
     *
     * @param taskId {@link #createOfflineTask} 创建返回的任务 id
     */
    stopOfflineTask(taskId: number): void;
    /**
     * 更新离线缓存路径，更新后新的离线下载任务都会下载到新的目录
     *
     * @param bizId 业务 id，用于关联存储路径
     * @param savePath 新的离线缓存路径
     */
    updateOfflinePath(bizId: number, savePath: string): void;
    /**
     * 删除已经下载过的离线任务，会删除本地已存储的数据
     *
     * @param bizId 业务 id，用于关联存储路径
     * @param fileId 文件唯一 id
     * @param preferredResolution 偏好清晰度 yunxiao
     */
    removeOfflineTask(bizId: number, fileId: string, preferredResolution: number): number;
    /**
     * 腾讯视频业务独有接口
     * hls 续下载时需要确保获取指定 formatid 清晰度，需要一个加密字段传递给播放后台
     *
     * @param vid 视频请求的原始 vid
     * @param linkVid vinfo 中的 link vid
     * @param formatId 视频清晰度 id，320001等
     * @param encryptRandomNum 随机数
     * @return 加密串 ext tag
     */
    getHLSOfflineExtTag(vid: string, linkVid: string, formatId: number, encryptRandomNum: number): string;
    /**
     * 腾讯视频业务独有接口
     * 校验离线数据完整性
     *
     * @param diskPath 离线存储路径
     * @param fileFormat 文件类型, 1-整段 mp4 2- 分片mp4 3- hls
     * @param resourceId 存储 id
     * @param keyId 分片 mp4 拼接路径使用，分片文件中的 keyid 前面部分
     * @return 本地已下载大小
     */
    verifyOfflineCacheSync(diskPath: string, fileFormat: number, resourceId: string, keyId: string): number;
    /**
     * 检查资源是否存在
     * @param diskPath 离线存储路径
     * @param resourceID 存储id
     * @param preferredResolution 偏好清晰度
     * @return
     */
    checkResourceExist(diskPath: string, resourceID: string, preferredResolution: number): boolean;
    /**
     * 获取资源的下载进度
     * @param diskPath 离线存储路径
     * @param resourceID 存储id
     * @param preferredResolution 偏好清晰度
     * @return
     */
    getResourceDownloadProgress(diskPath: string, resourceID: string, preferredResolution: number): number;
}
export interface TPDataTransportOfflineTaskListener {
    /**
     * 进度回调
     *
     * @param taskId {@link ITPDataTransportOfflineTaskMgr#createOfflineTask} 创建任务返回的 id
     * @param playableDurationMS 可播时长，单位：毫秒 hls 播放时可以返回准确的可播时长，其他格式不可用
     * @param downloadSpeedKBytes 下载速度 KB/s
     * @param currentDownloadSizeByte 当前下载字节数
     * @param totalFileSizeByte 总字节数，有 vinfo 时一般通过 vinfo 获取总文件大小，其他情况可能没有
     * @param exInfo 扩展信息
     */
    onDownloadProgressUpdate(taskId: number, playableDurationMs: number, downloadSpeedKBytes: number, currentDownloadSizeByte: number, totalFileSizeByte: number, exInfo: string): Promise<void>;
    /**
     * 视频数据全部下载完成
     *
     * @param taskId {@link ITPDataTransportOfflineTaskMgr#createOfflineTask} 创建任务返回的 id
     */
    onDownloadFinished(taskId: number): Promise<void>;
    /**
     * 错误回调
     *
     * @param taskId {@link ITPDataTransportOfflineTaskMgr#createOfflineTask} 创建任务返回的 id
     * @param moduleID 模块ID
     * @param errorCode 错误码
     * @param exInfo 扩展信息
     */
    onDownloadError(taskId: number, moduleId: number, errorCode: number, exInfo: string): Promise<void>;
}
