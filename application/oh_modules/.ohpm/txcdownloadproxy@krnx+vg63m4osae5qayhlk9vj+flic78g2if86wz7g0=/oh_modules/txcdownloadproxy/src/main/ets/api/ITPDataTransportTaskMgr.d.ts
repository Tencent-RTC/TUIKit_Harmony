import { TPDataTransportTaskParam } from "./TPDataTransportTaskParam";
import { TPDataTransportResourceLoaderListener } from "./ITPDataTransportResourceLoaderMgr";
import { TPDataTransportTaskProxyUrlType, TPDataTransportTaskAccessibleNativeInfoType } from "./TPDataTransportEnum";
import { TPDataTransportMessageInfo, TPDataTransportMessageInfoType } from './ITPDataTransportCommonInfoListener';
export interface ITPDataTransportTaskMgr {
    /**
     * 普通下载任务
     *
     * @taskParam taskParam 下载任务相关参数
     * @param taskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createTask(taskParam: TPDataTransportTaskParam, taskListener: ITPDataTransportTaskListener): number;
    /**
     * 可以将多个不同 url 下载地址组合成一个任务调度，会将所有 url 关联起来调度，主要用做多个分片 mp4 的下载
     *
     * @param taskParams 多个下载任务参数集
     * @param taskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createMultiTask(taskParamList: Array<TPDataTransportTaskParam>, taskListener: ITPDataTransportTaskListener): number;
    /**
     * 停止任务，当前任务相关逻辑会完全停止，下载停止、数据内存会被逐渐淘汰、任务被淘汰
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     */
    stopTask(taskId: number): void;
    /**
     * 暂停任务，下载停止、内存不会淘汰，任务等待继续下载
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     */
    pauseTask(taskId: number): void;
    /**
     * 恢复任务，配合 pauseTask 接口，恢复被暂停的任务
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     */
    resumeTask(taskId: number): void;
    /**
     * 主动获取任务下载过程中的错误码
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @return 错误码格式化字符串 模块号;错误码  eg:231;1400015
     */
    getTaskErrorCode(taskId: number): string;
    /**
     * 任务创建成功后，获取代理 url 地址
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param taskProxyUrlType {@link TaskProxyUrlType} 代理 url 类型
     * @return 返回当前任务对应的代理 url 地址
     */
    getProxyUrl(taskId: number, taskProxyUrlType: TPDataTransportTaskProxyUrlType): string;
    /**
     * @param taskId {@link #createMultiTask} 创建组合任务返回的 id
     * @param taskProxyUrlType {@link TaskProxyUrlType} 代理 url 类型
     * @return 返回组合任务对应代理 url 地址
     */
    getMultiProxyUrlList(taskId: number, taskProxyUrlType: TPDataTransportTaskProxyUrlType): Array<string>;
    /**
     * 任务创建后，更新任务下载参数，如果在下载过程中 url、url header 等信息发生变化，可以动态更新
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param taskParamList 更新的参数内容
     */
    updateRunningTaskParam(taskId: number, taskParamList: Array<TPDataTransportTaskParam>): void;
    /**
     * 任务创建后，可以更新任务相关的配置参数
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param key {@link TaskOptionalConfigParam} 任务级更新相关参数信息
     * @param value 更新参数值
     */
    setTaskOptionalConfigParam(taskId: number, key: string, value: string): void;
    /**
     * 任务创建后，获取任务级相关信息
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param key {@link TaskAccessibleNativeInfo} 可获取的任务参数 key
     * @return 对应任务参数信息
     */
    getTaskAccessibleNativeInfo(taskId: number, key: TPDataTransportTaskAccessibleNativeInfoType): string;
    /**
     * 设置 ResourceLoader 接口通道
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param resourceLoaderListener 数据资源读取回调
     */
    setTaskResourceLoaderListener(taskId: number, resourceLoaderListener: TPDataTransportResourceLoaderListener): void;
}
export interface ITPDataTransportTaskListener {
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
     * @param exInfo 扩展信息
     */
    onDownloadError(taskId: number, moduleId: number, errorCode: number, exInfo: string): Promise<void>;
    /**
     * 通用回调接口
     *
     * @param taskId {@link #createTask} 返回的 id
     * @param meesageInfoType 消息类型
     * @param messageInfo 消息内容
     */
    onCommonInfoMessage(taskId: number, meesageInfoType: TPDataTransportMessageInfoType, messageInfo: TPDataTransportMessageInfo): Promise<void>;
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
