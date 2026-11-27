import { Context } from '@kit.AbilityKit';
import { ITPDataTransportOfflineVinfoAdapter } from './ITPDataTransportOfflineVinfoAdapter';
import { ITPDataTransportTaskMgr } from './ITPDataTransportTaskMgr';
import { ITPDataTransportOfflineTaskMgr } from './ITPDataTransportOfflineTaskMgr';
import { ITPDataTransportPreloadTaskMgr } from './ITPDataTransportPreloadTaskMgr';
import { TPDataTransportBizAccessibleNativeInfoType, TPDataTransportBizOptionalConfigParam, TPDataTransportClearCacheMode, TPDataTransportGlobalAccessibleNativeInfoType, TPDataTransportGlobalOptionalConfigParam } from './TPDataTransportEnum';
import { TPDataTransportCommonInfoListener } from './ITPDataTransportCommonInfoListener';
import { ITPDataTransportLogListener } from './ITPDataTransportLogListener';
export declare class TPDataTransportMgr {
    private static _instance;
    /**
     * 离线 vinfo 桥接接口
     */
    private sOfflineVinfoAdapter;
    private constructor();
    static getInstance(): TPDataTransportMgr;
    /**
     * 日志接口，优先设置
     *
     * @param logListener 日志回调接口
     */
    setLogListener(logListener: ITPDataTransportLogListener): void;
    /**
     * 通用信息回调
     *
     * @param commonInfoListener 通用消息
     */
    registerCommonInfoListener(commonInfoListener: TPDataTransportCommonInfoListener): void;
    /**
     * 取消注册
     *
     * @param commonInfoListener 通用消息
     */
    unregisterCommonInfoListener(commonInfoListener: TPDataTransportCommonInfoListener): void;
    /**
     * 获取 native 版本号
     *
     * @return 如果 native 加载成功，返回版本号 eg: x.x.x.x，否则为空
     */
    getNativeLibVersion(): string;
    /**
     * native 是否加载成功，so 可能加载失败，如果使用子进程需要等待子进程绑定后才能加载 so
     *
     * @return 失败表示下载组件不可用
     */
    isNativeInit(): boolean;
    /**
     * 初始化入口
     *
     * @param context HarmonyOS 上下文
     * @return 初始化是否成功
     */
    init(context: Context): boolean;
    /**
     * 如果业务需要独立存储、配置逻辑，需要通过存储路径注册业务 id，后续业务相关的播放、预下载、离线等业务都需要带上业务 id 进行关联
     *
     * @param dataDir 数据存储目录
     * @return 业务 id 大于 0，如果 native 没有加载成功会注册失败返回 -1
     */
    registerBizId(dataDir: string): number;
    /**
     * 业务方可以自定义业务 id，这种情况下业务 id 的路径可以为空
     *
     * @param assignedBizId 业务方自己指定的业务 id，需要大于 10000，10000 及以内内部预留避免冲突
     * @param dataDir 数据存储目录
     * @return 如果返回和业务方设置的 assignedBizId 一致表示注册成功，否则表示注册失败返回 -1
     */
    registerAssignedBizId(assignedBizId: number, dataDir: string): number;
    /**
     * 取消相关业务实例，清除实例相关内存等信息
     *
     * @param bizId {@link #registerBizId} 根据路径注册后返回
     */
    unregisterBizId(bizId: number): void;
    /**
     * 获取常规任务实例
     *
     * @return 常规任务实例，初始化失败、子进程实例绑定失败时会返回空
     */
    getTaskMgr(): ITPDataTransportTaskMgr;
    /**
     * 获取预下载任务创建实例
     *
     * @return 预加载任务实例，初始化失败、子进程实例绑定失败时会返回空
     */
    getPreloadTaskMgr(): ITPDataTransportPreloadTaskMgr;
    /**
     * 获取离线下载任务创建实例
     *
     * @return 离线下载任务实例，初始化失败、子进程实例绑定失败时会返回空
     */
    getOfflineTaskMgr(): ITPDataTransportOfflineTaskMgr;
    /**
     * 设置配置参数信息，全局生效
     *
     * @param key {@link GlobalOptionalConfigParam} 可全局配置参数
     * @param value 可全局配置参数值
     * @return 可能设置失败，底层未初始化
     */
    setGlobalOptionalConfigParam(key: TPDataTransportGlobalOptionalConfigParam, value: string): boolean;
    /**
     * 设置实例相关的参数信息，实例相关场景生效
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param key {@link BizOptionalConfigParam} 业务相关可配置参数
     * @param value 业务相关可配置参数值
     * @return 可能设置失败，业务未初始化成功
     */
    setBizOptionalConfigParam(bizId: number, key: TPDataTransportBizOptionalConfigParam, value: string): boolean;
    /**
     * 获取全局相关信息
     *
     * @param key {@link GlobalAccessibleNativeInfo} 可用的全局信息定义
     * @return
     */
    getGlobalAccessibleNativeInfo(key: TPDataTransportGlobalAccessibleNativeInfoType): string;
    /**
     * 获取业务级相关信息
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param key {@link BizAccessibleNativeInfo} 可用的业务级信息定义
     * @return
     */
    getBizAccessibleNativeInfo(bizId: number, key: TPDataTransportBizAccessibleNativeInfoType): string;
    /**
     * 删除特定内存数据、缓存数据、离线属性，以及清理所有缓存
     * 接口涉及数据复用和管理，由业务方保障调用的准确性
     * 场景说明：
     * 1. 在线播放开启缓存（只具有在线属性）
     * 2. 离线下载（只具有离线属性）
     * 3. 下载 + 在线播放（同时具有在线和离线属性）
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param fileId 任务创建时传的 {@link TPDataTransportTaskParam#TASK_PARAM_FILE_ID}，在删除所有在线缓存时可以传空
     * @param mode {@link ClearCacheMode} 删除资源的类型
     * @return 是否成功
     */
    clearCache(bizId: number, fileId: string, mode: TPDataTransportClearCacheMode): boolean;
    /**
     * 查询资源状态
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param fileId 任务创建时传的 {@link TPDataTransportTaskParam#TASK_PARAM_FILE_ID}，在删除所有在线缓存时可以传空
     * @param fileFormat {@link CacheFileFormat} 文件类型
     * @return 资源状态信息，-1：未知；0：未完成；1：完成
     */
    checkResourceStatus(bizId: number, fileId: string, fileFormat: number): number;
    /**
     * 获取类型所占缓存大小
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param fileId 任务创建时传的 {@link TPDataTransportTaskParam#TASK_PARAM_FILE_ID}，在删除所有在线缓存时可以传空
     * @return 资源所占缓存大小
     */
    getResourceSize(bizId: number, fileId: string): number;
    /**
     * 腾讯视频业务独有接口
     * 腾讯视频离线播放时，需要从另一个模块获取 vinfo，通过接口桥接来实现，避免多个模块引用耦合
     *
     * @param vinfoAdapter
     */
    setOfflineVinfoAdapter(vinfoAdapter: ITPDataTransportOfflineVinfoAdapter): void;
    /**
     * 腾讯视频业务独有接口
     * 判断某个 vid、format 是否有离线记录，主要用来做离线
     *
     * @param vid 视频 vid
     * @param format 视频清晰度，sd、hd、shd、fhd 等
     * @return 如果有离线记录，直接返回 vinfo xml，否则返回空字符串
     */
    checkVideoStatus(vid: string, format: string): string;
    /**
     * 腾讯视频业务独有接口
     * 获取离线视频时长，有就大于 0，没有结果等于 0
     *
     * @param vid 视频 vid
     * @param format 视频清晰度，sd、hd、shd、fhd 等
     * @return 离线视频时长
     */
    getRecordDuration(vid: string, format: string): number;
}
