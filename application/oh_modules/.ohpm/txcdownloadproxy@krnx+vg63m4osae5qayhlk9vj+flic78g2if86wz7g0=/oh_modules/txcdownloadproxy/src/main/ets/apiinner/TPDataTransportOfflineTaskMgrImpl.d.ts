import { TPDataTransportTaskParam } from '../api/TPDataTransportTaskParam';
import { ITPDataTransportOfflineTaskMgr, TPDataTransportOfflineTaskListener } from '../api/ITPDataTransportOfflineTaskMgr';
export declare class TPDataTransportOfflineTaskMgrImpl implements ITPDataTransportOfflineTaskMgr {
    private logger;
    createOfflineTask(taskParam: TPDataTransportTaskParam, offlineTaskListener: TPDataTransportOfflineTaskListener): number;
    createMultiOfflineTask(taskParam: Array<TPDataTransportTaskParam>, offlineTaskListener: TPDataTransportOfflineTaskListener): number;
    startOfflineTask(taskId: number): void;
    stopOfflineTask(taskId: number): void;
    updateOfflinePath(bizId: number, savePath: string): void;
    removeOfflineTask(bizId: number, fileId: string, preferredResolution: number): number;
    getHLSOfflineExtTag(vid: string, linkVid: string, formatId: number, encryptRandomNum: number): string;
    verifyOfflineCacheSync(diskPath: string, fileFormat: number, resourceId: string, keyId: string): number;
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
