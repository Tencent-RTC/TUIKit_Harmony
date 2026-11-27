import { TPDataTransportMessageInfo, TPDataTransportCommonInfoListener, TPDataTransportMessageInfoType } from '../api/ITPDataTransportCommonInfoListener';
import { TPDataTransportBizAccessibleNativeInfoType, TPDataTransportBizOptionalConfigParam, TPDataTransportClearCacheMode, TPDataTransportGlobalAccessibleNativeInfoType, TPDataTransportGlobalOptionalConfigParam } from '../api/TPDataTransportEnum';
import { ITPDataTransportMgrBridge } from './ITPDataTransportMgrBridge';
import { Context } from '@kit.AbilityKit';
/**
 * NOTE: TPDataTransportNative 的所有方法都封装在这个 TPDataTransportMgrWrapper 类里面，
 * 其他类不直接调用 native 里面的接口，再通过这个类往其他 mgr 里面分发
 */
export declare class TPDataTransportMgrWrapper implements ITPDataTransportMgrBridge, TPDataTransportCommonInfoListener {
    private commonInfoListenerSet;
    private logger;
    constructor();
    registerCommonInfoListener(commonInfoListener: TPDataTransportCommonInfoListener): void;
    unregisterCommonInfoListener(commonInfoListener: TPDataTransportCommonInfoListener): void;
    getNativeLibVersion(): string;
    isNativeInit(): boolean;
    registerBizId(dataDir: string): number;
    registerAssignedBizId(assignedBizId: number, dataDir: string): number;
    unregisterBizId(bizId: number): void;
    init(context: Context): boolean;
    setGlobalOptionalConfigParam(key: TPDataTransportGlobalOptionalConfigParam, value: string): boolean;
    setBizOptionalConfigParam(bizId: number, key: TPDataTransportBizOptionalConfigParam, value: string): boolean;
    getGlobalAccessibleNativeInfo(key: TPDataTransportGlobalAccessibleNativeInfoType): string;
    getBizAccessibleNativeInfo(bizId: number, key: TPDataTransportBizAccessibleNativeInfoType): string;
    clearCache(bizId: number, fileId: string, mode: TPDataTransportClearCacheMode): boolean;
    checkResourceStatus(bizId: number, fileId: string, fileFormat: number): number;
    getResourceSize(bizId: number, fileId: string): number;
    updateOfflinePath(bizId: number, savePath: string): number;
    removeOfflineTask(bizId: number, fileId: string, preferredResolution: number): number;
    getHLSOfflineExtTag(vid: string, linkVid: string, formatId: number, encryptRandomNum: number): string;
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
    onCommonInfoUpdate(messageInfoType: TPDataTransportMessageInfoType, messageInfo: TPDataTransportMessageInfo): Promise<void>;
}
