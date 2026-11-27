import { TPDataTransportTaskParam } from '../api/TPDataTransportTaskParam';
import { ITPDataTransportTaskListener } from '../api/ITPDataTransportTaskMgr';
import { TPDataTransportPreloadTaskListener } from '../api/ITPDataTransportPreloadTaskMgr';
import { TPDataTransportOfflineTaskListener } from '../api/ITPDataTransportOfflineTaskMgr';
import { TPDataTransportResourceLoaderListener } from '../api/ITPDataTransportResourceLoaderMgr';
import { TPDataTransportTaskAccessibleNativeInfoType, TPDataTransportTaskOptionalConfigParam, TPDataTransportTaskProxyUrlType } from '../api/TPDataTransportEnum';
export interface ITPDataTransportTask {
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
     * @param taskParamList 多个下载任务参数集
     * @param taskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createMultiTask(taskParamList: Array<TPDataTransportTaskParam>, taskListener: ITPDataTransportTaskListener): number;
    /**
     * 普通预下载下载任务
     *
     * @taskParam taskParam 下载任务相关参数
     * @param preloadTaskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createPreloadTask(taskParam: TPDataTransportTaskParam, preloadTaskListener: TPDataTransportPreloadTaskListener): number;
    /**
     * 普通离线下载任务，数据会默认缓存到磁盘
     *
     * @taskParam taskParam 下载任务相关参数
     * @param offlineTaskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createOfflineTask(taskParam: TPDataTransportTaskParam, offlineTaskListener: TPDataTransportOfflineTaskListener): number;
    /**
     * 多分片任务离线下载，所有任务 url 将看被作互相关联在一起
     *
     * @param taskParamList 多个下载任务参数集
     * @param offlineTaskListener 任务信息回调
     * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
     */
    createMultiOfflineTask(taskParamList: Array<TPDataTransportTaskParam>, offlineTaskListener: TPDataTransportOfflineTaskListener): number;
    /**
     * 主动开始任务下载
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     */
    startTask(taskId: number): void;
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
    setTaskOptionalConfigParam(taskId: number, key: TPDataTransportTaskOptionalConfigParam, value: string): void;
    /**
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param key {@link TaskAccessibleNativeInfo} 任务级可获取信息参数
     * @return
     */
    getTaskAccessibleNativeInfo(taskId: number, key: TPDataTransportTaskAccessibleNativeInfoType): string;
    /**
     * 设置 ResourceLoader 接口通道
     *
     * @param taskId {@link #createTask} 创建任务返回的 id
     * @param resourceLoaderListener 数据资源读取
     */
    setTaskResourceLoaderListener(taskId: number, resourceLoaderListener: TPDataTransportResourceLoaderListener): void;
}
