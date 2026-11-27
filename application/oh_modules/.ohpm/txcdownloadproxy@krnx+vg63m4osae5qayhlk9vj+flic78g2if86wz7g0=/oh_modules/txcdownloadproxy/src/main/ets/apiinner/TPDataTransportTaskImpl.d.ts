import { TPDataTransportTaskListener } from '../api/TPDataTransportTaskListener';
import { TPDataTransportTaskParam } from '../api/TPDataTransportTaskParam';
import { ITPDataTransportTask } from './ITPDataTransportTask';
import { TPDataTransportPreloadTaskListener } from '../api/ITPDataTransportPreloadTaskMgr';
import { TPDataTransportOfflineTaskListener } from '../api/ITPDataTransportOfflineTaskMgr';
import { TPDataTransportResourceLoaderListener } from '../api/ITPDataTransportResourceLoaderMgr';
import { TPDataTransportTaskAccessibleNativeInfoType, TPDataTransportTaskOptionalConfigParam, TPDataTransportTaskProxyUrlType } from '../api/TPDataTransportEnum';
export declare class TPDataTransportTaskImpl implements ITPDataTransportTask {
    createTask(taskParam: TPDataTransportTaskParam, taskListener: TPDataTransportTaskListener): number;
    createPreloadTask(taskParam: TPDataTransportTaskParam, preloadTaskListener: TPDataTransportPreloadTaskListener): number;
    createOfflineTask(taskParam: TPDataTransportTaskParam, offlineTaskListener: TPDataTransportOfflineTaskListener): number;
    createMultiTask(taskParamList: Array<TPDataTransportTaskParam>, taskListener: TPDataTransportTaskListener): number;
    createMultiOfflineTask(taskParamList: Array<TPDataTransportTaskParam>, offlineTaskListener: TPDataTransportOfflineTaskListener): number;
    startTask(taskId: number): void;
    stopTask(taskId: number): void;
    pauseTask(taskId: number): void;
    resumeTask(taskId: number): void;
    getTaskErrorCode(taskId: number): string;
    getProxyUrl(taskId: number, taskProxyUrlType: TPDataTransportTaskProxyUrlType): string;
    getMultiProxyUrlList(taskId: number, taskProxyUrlType: TPDataTransportTaskProxyUrlType): Array<string>;
    updateRunningTaskParam(taskId: number, updateTaskParamList: Array<TPDataTransportTaskParam>): void;
    setTaskOptionalConfigParam(taskId: number, key: TPDataTransportTaskOptionalConfigParam, value: string): void;
    getTaskAccessibleNativeInfo(taskId: number, key: TPDataTransportTaskAccessibleNativeInfoType): string;
    setTaskResourceLoaderListener(taskId: number, resourceLoaderListener: TPDataTransportResourceLoaderListener): void;
}
