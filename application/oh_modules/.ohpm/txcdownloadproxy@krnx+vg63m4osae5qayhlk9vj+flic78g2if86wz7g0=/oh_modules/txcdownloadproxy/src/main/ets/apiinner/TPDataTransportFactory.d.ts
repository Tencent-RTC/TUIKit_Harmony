import { ITPDataTransportOfflineTaskMgr } from '../api/ITPDataTransportOfflineTaskMgr';
import { ITPDataTransportPreloadTaskMgr } from '../api/ITPDataTransportPreloadTaskMgr';
import { ITPDataTransportTaskMgr } from '../api/ITPDataTransportTaskMgr';
import { ITPDataTransportMgrBridge } from './ITPDataTransportMgrBridge';
import { ITPDataTransportTask } from './ITPDataTransportTask';
import { TPDataTransportBizIdCreator } from './TPDataTransportBizIdCreator';
export declare class TPDataTransportFactory {
    private static _instance;
    private taskMgr;
    private preloadTaskMgr;
    private offlineTaskMgr;
    private taskImpl;
    private taskWrapper;
    private bizIdCreator;
    private constructor();
    static getInstance(): TPDataTransportFactory;
    getTaskMgr(): ITPDataTransportTaskMgr;
    getPreloadTaskMgr(): ITPDataTransportPreloadTaskMgr;
    getOfflineTaskMgr(): ITPDataTransportOfflineTaskMgr;
    getTaskImpl(): ITPDataTransportTask;
    getTaskWrapper(): ITPDataTransportMgrBridge;
    getBizIdCreator(): TPDataTransportBizIdCreator;
}
