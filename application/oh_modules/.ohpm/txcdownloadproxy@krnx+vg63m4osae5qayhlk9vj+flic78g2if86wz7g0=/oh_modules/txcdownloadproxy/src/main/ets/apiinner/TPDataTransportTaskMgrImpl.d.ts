import { TPDataTransportTaskParam } from '../api/TPDataTransportTaskParam';
import { ITPDataTransportTaskMgr } from '../api/ITPDataTransportTaskMgr';
import { TPDataTransportTaskListener } from '../api/TPDataTransportTaskListener';
import { TPDataTransportResourceLoaderListener } from '../api/ITPDataTransportResourceLoaderMgr';
import { TPDataTransportTaskAccessibleNativeInfoType, TPDataTransportTaskOptionalConfigParam, TPDataTransportTaskProxyUrlType } from '../api/TPDataTransportEnum';
export declare class TPDataTransportTaskMgrImpl implements ITPDataTransportTaskMgr {
    createTask(taskParam: TPDataTransportTaskParam, taskListener: TPDataTransportTaskListener): number;
    createMultiTask(taskParamList: Array<TPDataTransportTaskParam>, taskListener: TPDataTransportTaskListener): number;
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
