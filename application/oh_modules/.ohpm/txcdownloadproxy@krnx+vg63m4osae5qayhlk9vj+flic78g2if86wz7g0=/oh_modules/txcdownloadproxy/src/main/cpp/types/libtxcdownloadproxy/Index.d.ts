import { Context } from "@kit.AbilityKit";

export declare const UpdateContext: (context: Context) => void;

export declare const InitService: (bizId: number, cacheDir: string, dataDir: string, config: string) => number;

export declare const DeInitService: (bizId: number) => void;

export declare const UpdateStoragePath: (bizId: number, path: string) => number;

export declare const SetMaxStorageSizeMB: (bizId: number, maxStorageMb: number) => number;

export declare const GetVersion: () => string;

export declare const GetErrorCodeStr: (taskId: number) => string;

export declare const CheckResourceStatus: (diskPath: string, resourceId: string, fileFormat: number) => number;

export declare const GetResourceSize: (diskPath: string, resourceId: string) => number;

export declare const GetHLSOfflineExtTag: (vid: string, linkVid: string, formatId: number,
  encryptRandomNum: number) => string;

export declare const SetServiceConfig: (config: string) => void;

export declare const CreateDownloadTask: (bizId: number, keyId: string, fileType: number, clipCount: number) => number;

export declare const SetClipInfo: (taskId: number, clipNo: number, clipKeyId: string, fileType: number, urls: string,
  savePath: string, extraInfo: string) => number;

export declare const GetClipPlayUrl: (taskId: number, clipNo: number, urlType: number) => string;

export declare const StartTask: (taskId: number) => number;

export declare const StopTask: (taskId: number) => number;

export declare const StopAllDownload: (downloadMode: number) => number;

export declare const PauseTask: (taskId: number) => number;

export declare const ResumeTask: (taskId: number) => number;

export declare const DeleteCache: (diskPath: string, resourceId: string, preferredResolution: number) => number;

export declare const ClearCache: (diskPath: string, resourceId: string, mode: number, preferredResolution?: number) => number;

export declare const VerifyOfflineCacheSync: (diskPath: string, fileFormat: number, resourceId: string,
  keyId: string) => number;

export declare const SetPlayerState: (taskId: number, state: number) => void;

export declare const UpdateTaskInfo: (taskId: number, key: string, value: string) => void;

export declare const UpdatePlayerPlayMsg: (taskId: number, playPositionSec: number, playerRemainTimeSec: number,
  advRemainTimeSec: number) => void;

export declare const SetGlobalOptionalConfigParam: (key: string, value: string) => void;

export declare const SetBizOptionalConfigParam: (bizId: number, key: string, value: string) => void;

export declare const SetTaskAccessibleNativeInfo: (taskId: number, key: string, value: string) => void;

export declare const GetGlobalAccessibleNativeInfo: (key: number) => string;

export declare const GetBizAccessibleNativeInfo: (bizId: number, key: number) => string;

export declare const GetTaskAccessibleNativeInfo: (taskId: number, key: number) => string;

export declare const GenerateMD5: (buf: string) => string;

// yunxiao start
export declare const CheckResourceExist:(diskPath: string, resourceID: string, preferredResolution: number) => number;

export declare const GetResourceDownloadProgress:(diskPath: string, resourceID: string, preferredResolution: number) => number;
// yunxiao end

// ============================================================================
// 与 Android JNI 保持对齐的补齐接口
// ============================================================================
export declare const GetNativeInfo: (key: number) => string;

export declare const SetUserData: (key: string, value: string) => void;

export declare const PushEvent: (event: number) => void;

export declare const IsNativeReadyForWork: () => boolean;

export declare const GetPDTInfos: (playId: number) => Array<PDTInfo>;

export declare const SwitchToResolution: (playId: number, width: number, height: number) => void;

export declare const GetOfflineLicenseKeySetId: (saveDir: string, playUrl: string, licenseUrl: string) => Uint8Array | null;

export declare const DeleteOfflineLicenseKeySetId: (saveDir: string, playUrl: string, licenseUrl: string) => number;

/**
 * 与 Android TPDLProxyMsg.TPPDTInfo 对齐的 PDT 信息结构
 */
export interface PDTInfo {
  pdtTimeStartMS: number;
  pdtTimeEndMS: number;
  durationStart: number;
  durationEnd: number;
}

export interface Event {
  readonly type: (string & {}) | "native",
}

export interface NativeEvent extends Event {
  readonly messageType: number;
  readonly taskId: number;
  readonly playableTimeMs: number,
  readonly currentOffsetByte: number,
  readonly fileSizeByte: number,
  readonly moduleId: number,
  readonly errorCode: number,
  readonly currentCdnUrl?: string;
  readonly serverIp?: string;
  readonly clientIp?: string;
  readonly errorInfo?: string;
  readonly extraTag?: string;
  readonly encryptRandomNum?: number;
  readonly protocol?: string;
  readonly protocolVersion?: string;
  readonly vid?: string;
  readonly messageInfo?: string;
  readonly speedKBytes?: number;
  readonly sendPackageTotalCount?: number;
  readonly extraInfo?: string;
  readonly cgiHttpStatusCode?: number;
  readonly cgiHttpResponseHeader?: string;
  readonly cgiContent?: string;
  readonly cgiErrorCode?: number;
  readonly extraObjAddress?: Uint8Array  // 用于 FLV preload status 消息
}

export interface EventListener<T = Event> {
  (event: T): void;
}

/**
 * NativeCallback 在 native 层用 NAPI 实现，用于注册回调来接收传输组件的消息，同时支持自定义事件，
 * 消息在 JS 层以 Event 对象的形式表示，传输组件本身的事件类型恒为 "native"，自定义事件的类型为除了 "native" 之外的任意字符串
 */
export declare class NativeCallback {
  constructor()

  /**
   * 注册 native 事件的回调，native 事件为传输组件本身发起的事件
   * @param type 事件类型，恒为 "native"
   * @param listener native 事件回调
   */
  on(type: "native", listener: EventListener<NativeEvent>): void;

  /**
   * 注册自定义事件的回调
   * @param type 事件类型
   * @param listener 事件回调
   */
  on(type: string, listener: EventListener): void;

  /**
   * 注销 native 事件的回调，native 事件为传输组件本身发起的事件
   * @param type 事件类型，恒为 "native"
   * @param listener native 事件回调
   */
  off(type: "native", listener: EventListener<NativeEvent>): void;

  /**
   * 注销自定义事件的回调
   * @param type 事件类型
   * @param listener 事件回调
   */
  off(type: string, listener: EventListener): void;

  /**
   * 分发事件，触发对应的回调，NativeCallback 的使用方可调用该方法手动发起事件
   * @param event 事件对象
   */
  emit(event: Event): void;
}
