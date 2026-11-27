import { TPDataTransportTaskParam } from '../api/TPDataTransportTaskParam';
import { TPDataTransportTaskOptionalConfigParam } from '../api/TPDataTransportEnum';
import { ITPDataTransportPreloadTaskMgr, TPDataTransportPreloadTaskListener } from '../api/ITPDataTransportPreloadTaskMgr';
export declare class TPDataTransportPreloadTaskMgrImpl implements ITPDataTransportPreloadTaskMgr {
    createPreloadTask(taskParam: TPDataTransportTaskParam, preloadTaskListener: TPDataTransportPreloadTaskListener): number;
    stopPreloadTask(taskId: number): void;
    startPreloadTask(taskId: number): void;
    setPreloadTaskOptionalConfigParam(taskId: number, key: TPDataTransportTaskOptionalConfigParam, value: string): void;
}
