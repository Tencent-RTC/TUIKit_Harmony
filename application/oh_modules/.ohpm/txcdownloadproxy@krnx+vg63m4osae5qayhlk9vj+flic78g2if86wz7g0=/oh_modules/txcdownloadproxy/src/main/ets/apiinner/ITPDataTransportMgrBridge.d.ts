import { Context } from '@kit.AbilityKit';
import { TPDataTransportCommonInfoListener } from '../api/ITPDataTransportCommonInfoListener';
import { TPDataTransportBizAccessibleNativeInfoType, TPDataTransportBizOptionalConfigParam, TPDataTransportClearCacheMode, TPDataTransportGlobalAccessibleNativeInfoType, TPDataTransportGlobalOptionalConfigParam } from '../api/TPDataTransportEnum';
export interface ITPDataTransportMgrBridge {
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
     * @return 初始化是否成功
     */
    init(context: Context): boolean;
    /**
     * 如果使用了子进程模式，需要关注子进程的运行情况，如果子进程断开连接下载组件功能会不可用
     *
     * @param serviceListener 进程绑定回调
     */
    /**
     * 取消子进程的监听
     *
     * @param serviceListener 进程绑定回调
     */
    /**
     * 开始绑定子进程服务，需要主进程触发
     */
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
     * @return 如果返回值和业务方设置的 customizationBizId 一致表示注册成功，否则表示注册失败返回 -1
     */
    registerAssignedBizId(bizId: number, dataDir: string): number;
    /**
     * 取消相关业务实例，清除实例相关内存等信息
     *
     * @param bizId registerBizId 根据路径注册后返回
     */
    unregisterBizId(bizId: number): void;
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
     * @return 参数内容
     */
    getGlobalAccessibleNativeInfo(key: TPDataTransportGlobalAccessibleNativeInfoType): string;
    /**
     * 获取业务级相关信息
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param key {@link BizAccessibleNativeInfo} 可用的业务级信息定义
     * @return 参数内容
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
     * 更新离线下载缓存路径，更新后新的离线下载任务都会下载到新的目录
     *
     * @param bizId {@link #registerBizId} 生成的业务场景 id，用于索引对应业务的存储目录
     * @param savePath 新的离线下载缓存路径
     * @return 成功返回 0，失败返回 -1
     */
    updateOfflinePath(bizId: number, savePath: string): number;
    /**
     * 删除离线下载任务和对应的缓存数据
     *
     * @param bizId 业务 id，用于关联存储路径
     * @param fileId 文件唯一 id
     * @param preferredResolution 偏好清晰度 yunxiao
     */
    removeOfflineTask(bizId: number, fileId: string, preferredResolution: number): number;
    /**
     * 腾讯视频业务独有接口
     * hls 续下载时需要确保获取指定 formatid 清晰度，需要一个加密字段传递给播放后台
     *
     * @param vid 视频请求的原始 vid
     * @param linkVid vinfo 中的 link vid
     * @param formatId 视频清晰度 id，320001等
     * @param encryptRandomNum 随机数
     * @return 加密串 ext tag
     */
    getHLSOfflineExtTag(vid: string, linkVid: string, formatId: number, encryptRandomNum: number): string;
    /**
     * 腾讯视频业务独有接口
     * 校验离线数据完整性
     *
     * @param diskPath 离线存储路径
     * @param fileFormat 文件类型, 1 - 整段 mp4, 2 - 分片 mp4, 3 - hls
     * @param resourceId 存储 id
     * @param keyId 分片 mp4 拼接路径使用，分片文件中的 keyid 前面部分
     * @return 本地已下载大小
     */
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
}
