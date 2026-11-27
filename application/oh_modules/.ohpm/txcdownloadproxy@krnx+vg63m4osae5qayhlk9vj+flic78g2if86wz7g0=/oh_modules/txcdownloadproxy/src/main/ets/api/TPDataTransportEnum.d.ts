/**
 * 任务类型
 */
export declare enum TPDataTransportTaskFileType {
    /**
     * 不明确下载类型时默认值
     */
    Auto = 0,
    /**
     * 整段 mp4
     */
    Mp4Vod = 1,
    /**
     * 分片 mp4
     */
    ClipMp4Vod = 2,
    /**
     * hls
     */
    HlsVod = 3,
    /**
     * hls 轮播
     */
    HlsVodLoop = 4,
    /**
     * hls 直播
     */
    HlsLive = 5,
    /**
     * mp4 广告
     */
    Mp4Adv = 6,
    /**
     * hls 广告
     */
    HlsAdv = 7,
    /**
     * hls 广告轮播
     */
    HlsAdvLoop = 8,
    /**
     * 高铁模式
     * @deprecated
     */
    Lan = 9,
    /**
     * 文件下载
     */
    FileDownload = 10,
    /**
     * 文件代理方式加载
     */
    FileVodProxyLoad = 11,
    /**
     * 腾讯云 flv 直播
     */
    FlvLive = 12,
    /**
     * hls 音频
     */
    HlsAudioVod = 13,
    /**
     * srt 字幕
     */
    CaptionSrt = 14,
    /**
     * webvtt 字幕
     */
    CaptionWebvtt = 15,
    /**
     * http flv 直播
     */
    HttpFlvLive = 16,
    /**
     * flv 直播预加载
     */
    HttpPreloadFlvLive = 17,
    /**
     * HLS PROXY 加载数据方式点播
     */
    HlsVodProxyLoad = 18,
    /**
     * dash 播放
     */
    Dash = 19,
    /**
     * MP4 批量任务
     */
    Mp4Batch = 20,
    /**
     * 分片 MP4批量任务
     */
    Mp4ClipBatch = 21,
    /**
     * HLS 批量任务
     */
    HlsBatch = 22,
    /**
     * flv p2p 直播
     */
    P2pFlvLive = 23,
    /**
     * 多网卡CGI请求任务
     */
    Cgi = 24
}
/**
 * 代理地址 url 类型
 */
export declare enum TPDataTransportTaskProxyUrlType {
    /**
     * 优先本地文件地址；自研播放器返回地址时，如果是离线下载完成的，优先返回本地文件地址，否则返回 127 本地代理地址
     */
    AbsoluteUrlPriority = 0,
    /**
     * 仅使用本地代理地址；系统播放器返回地址时，默认只返回 127 本地代理地址
     */
    ProxyUrlOnly = 1,
    /**
     * 使用本地代理地址，只创建任务，但是不驱动下载，只有数据请求时才驱动下载
     */
    ProxyUrlCreateTask = 2
}
/**
 * 任务相关的播放器状态信息
 */
export declare enum TPDataTransportTaskPlayerState {
    /**
     * 播放中
     */
    OnPlaying = 0,
    /**
     * 播放错误
     */
    OnPlayError = 1,
    /**
     * 播放暂停
     */
    OnPause = 2,
    /**
     * 准备播放
     */
    OnPrepare = 3
}
/**
 * 任务相关，播放器事件
 */
export declare enum TPDataTransportTaskPlayerEvent {
    /**
     * 播放器事件通知，seek 开始，用于替换之前的播放器状态 seeking
     */
    SeekStart = 0,
    /**
     * 播放器事件通知，seek 完成
     */
    SeekComplete = 1,
    /**
     * 播放器事件通知，二次缓冲开始
     */
    SecondaryBufferingStart = 2,
    /**
     * 播放器事件通知，二次缓冲结束
     */
    SecondaryBufferingEnd = 3
}
/**
 * App 可以设置任务的实际运行状态，用于辅助下载任务调度
 *
 */
export declare enum TPDataTransportTaskRunningState {
    /**
     * 预播放:主要用于多个播放器实例进行播放加速的case
     */
    OnPrePlay = 0,
    /**
     * 真实播放:主要用于多个播放器实例进行播放加速的case
     */
    OnRealPlay = 1
}
/**
 * 音视频合流时，数据转码方式
 */
export declare enum TPDataTransportDataTransferMode {
    /**
     * 无需特殊转码处理
     */
    Default = 0,
    /**
     * 音视频合流转码
     */
    Av = 1,
    /**
     * fmp4 转 ts
     */
    Fmp4ToTs = 2
}
/**
 * 嵌套 m3u8 离线下载调度方式
 */
export declare enum TPDataTransportDataOfflineScheduleLevel {
    /**
     * 调度所有分片下载
     */
    All = 0,
    /**
     * 只下载一路低码率流
     */
    LowBitrate = 1,
    /**
     * 只下载一路高码率流
     */
    HighBitrate = 2,
    /**
     * 嵌套离线下载直接抛错
     */
    Unsupported = 3,
    /**
     * 下载偏好清晰度流 yunxiao
     */
    PreferredResolution = 4
}
/**
 * app 前后台状态
 */
export declare enum TPDataTransportDataAppState {
    /**
     * app 在前台
     */
    Foreground = 0,
    /**
     * app 在后台
     */
    Background = 1,
    /**
     * app 熄屏
     */
    ScreenOff = 2,
    /**
     * app 亮屏
     */
    ScreenOn = 3,
    /**
     * app 主进程中使用
     */
    MainProcess = 4,
    /**
     * app 子进程中使用
     */
    SubProcess = 5,
    /**
     * app 子进程中使用，主进程退出
     */
    SubProcessAndMainProcessExist = 6
}
/**
 * p2p 上传状态控制
 */
export declare enum TPDataTransportDataP2pUploadState {
    /**
     * 上传关闭
     */
    Disable = 0,
    /**
     * 上传打开
     */
    Enable = 1,
    /**
     * 隐私合规场景下，上传关闭，优先级最低
     */
    PrivacyDisable = 2,
    /**
     * 隐私合规场景下，上传打开，优先级最低
     */
    PrivacyEnable = 3
}
/**
 * 预推状态控制
 */
export declare enum TPDataTransportPrePushState {
    /**
     * 关闭预推
     */
    Disable = 0,
    /**
     * 开启预推
     */
    Enable = 1
}
/**
 * 清晰度选择状态
 */
export declare enum TPDataTransportDataDefinitionSelectionState {
    /**
     * 没有选择清晰度
     */
    NotSelected = 0,
    /**
     * 已选择清晰度
     */
    Selected = 1
}
/**
 * 网络状态
 */
export declare enum TPDataTransportDataNetworkState {
    /**
     * 无网络
     */
    Off = 0,
    /**
     * wifi 网络
     */
    Wifi = 1,
    /**
     * 移动网络
     */
    Mobile = 2
}
/**
 * quic 启用支持的类型
 */
export declare enum TPDataTransportQuicEnableMode {
    /**
     * 默认值，不开启quic，强制走http
     */
    Disable = 0,
    /**
     * quic根据探测结果（header返回alt-svr字段）决定是否开启，推荐
     */
    DependOnProbe = 1,
    /**
     * 忽略探测，强制走quic，保证后台对quic的支持，否则quic会失败
     */
    ForceEnable = 2
}
/**
 * quic 拥塞控制算法选择 跟 tspdy_quic_request.h 定义保持一致
 */
export declare enum TPDataTransportQuicCongestionType {
    CubicBytes = 0,
    RenoBytes = 1,
    Bbr = 2,
    Pcc = 3,
    Googcc = 4
}
/**
 * 通用多网卡CGI优先请求的网卡类型
 */
export declare enum TPDataTransportCgiRequestNetworkTypePriority {
    /**
     * cgi请求不强制指定使用的网卡模式，默认 WI-FI
     */
    None = 0,
    /**
     * cgi请求指定优先使用 WI-FI 请求
     */
    Wifi = 1,
    /**
     * cgi请求指定优先使用 蜂窝网络 请求
     */
    Celluar = 2
}
/**
 * 通用多网卡CGI请求的连接方式
 */
export declare enum TPDataTransportCgiRequestLinkMethod {
    Http = 0,
    Https = 1,
    Quic = 2
}
/**
 * 通用多网卡CGI实际请求的网卡类型
 */
export declare enum TPDataTransportCgiResponseNetworkType {
    Wifi = 0,
    Celluar = 1
}
/**
 * 删除资源的类型
 */
export declare enum TPDataTransportClearCacheMode {
    /**
     * 删除单个资源磁盘文件
     */
    Storage = 1,
    /**
     * 移除单个资源离线属性
     */
    OfflineProperty = 2,
    /**
     * 清理单个资源内存和磁盘文件
     */
    MemoryStorage = 4,
    /**
     * 清理所有在线播放资源缓存
     */
    AllOnlineStorage = 8
}
/**
 * 全局可获取的信息
 */
export declare enum TPDataTransportGlobalAccessibleNativeInfoType {
    /**
     * 建议码率
     */
    SuggestBitrate = 0,
    /**
     * 建议清晰度，自适应的老逻辑，只有国际版还在用
     */
    SuggestDefn = 1,
    /**
     * 获取蜂窝网卡累计流量
     */
    CellularFlow = 2,
    /**
     * 获取所有累计流量
     */
    Flow = 3,
    /**
     * 获取当前内存占用，字节
     */
    Memory = 5,
    /**
     * 自适应策略，省带宽优先
     */
    AdaptiveStrategyBandwidthFirst = 6,
    /**
     * 自适应策略，体验优先
     */
    AdaptiveStrategyQosFirst = 7,
    /**
     * int 私有自研加密能力，通过 vinfo ckey 透传字段到后台
     */
    SelfEncryptionParamCapacityLevel = 8,
    /**
     * int 自研加密能力，vinfo 透传 ssv
     */
    SelfEncryptionVinfoCapacityLevel = 9,
    /**
     * string 自研加密 key，vinfo ckey 透传 ssk
     */
    SelfEncryptionKey = 10,
    /**
     * string 下载的通用策略，带到后台
     */
    DownloadStragetyExtInfo = 11
}
/**
 * 业务级可获取的信息
 */
export declare enum TPDataTransportBizAccessibleNativeInfoType {
    /**
     * 暂时没有定义
     */
    Undefined = 0
}
/**
 * 任务级可获取的信息
 */
export declare enum TPDataTransportTaskAccessibleNativeInfoType {
    /**
     * 暂时没有定义
     */
    Undefined = 0
}
/**
 * 全局可配置参数，默认所有业务实例生效，可以随时设置
 */
export declare enum TPDataTransportGlobalOptionalConfigParam {
    /**
     * int 用户的会员状态，0：非会员，1：会员
     */
    IntIsVip = "qq_is_vip",
    /**
     * 用户 guid
     */
    Guid = "guid",
    /**
     * bssid
     */
    BSSID = "bssid",
    /**
     * 平台号，主要用于区分数据上报
     */
    Platform = "platform",
    /**
     * 外网 ip
     */
    ExternalNetworkIp = "external_network_ip",
    /**
     * app 版本号，主要用于数据上报
     */
    AppVersion = "app_version_name",
    /**
     * app 系统版本号
     */
    OsVersion = "os_version",
    /**
     * 设备型号
     */
    DeviceModel = "device_model",
    /**
     * 联通免流标识
     */
    Upc = "carrier_pesudo_code",
    /**
     * int 联通免流状态码
     */
    IntUpcState = "carrier_pesudo_state",
    /**
     * int 最大使用内存上限，单位：MB
     */
    IntDeviceMaxUseMemoryMb = "max_use_memory",
    /**
     * int 系统保留内存，p2p在剩余内存的计算上要减去这个值，默认是0，单位:M，tv 使用
     */
    IntSystemReserveMemoryMb = "system_reserve_memory",
    /**
     * int 内存紧张等级 tv 使用
     */
    IntTrimMemoryLevel = "trim_memory_level",
    /**
     * 更新配置信息，目前应该主要 tv 使用
     */
    ProxyConfig = "proxy_config",
    /**
     * tab 透传 userid
     */
    TabAbUserid = "abuserid",
    /**
     * tab tab_callback_ack
     */
    IntTabCallbackAck = "tab_callback_ack",
    /**
     * tab 透传 app 实验 id
     */
    TabAbTestId = "app_test_id",
    /**
     * 是否使用多网卡，0：不适用，1：使用
     */
    IntUseMultiNetwork = "use_multi_network",
    /**
     * 丢包信息回调
     */
    LossPackageInfo = "lose_package_check_info",
    /**
     * 蜂窝网卡ID
     */
    CellularInterfaceId = "cellular_interface_id",
    /**
     * App 状态，前后台、熄屏、亮屏、进程状态
     * {@enum TPDataTransportDataAppState}
     */
    IntAppState = "app_state",
    /**
     * p2p 上传状态
     * {@enum TPDataTransportDataP2pUploadState}
     */
    IntP2pUploadState = "enable_p2p_upload",
    /**
     * App 清晰度选择状态
     * {@enum TPDataTransportDataDefinitionSelectionState}
     */
    IntDefinitionSelectionState = "definition_selection_state",
    /**
     * 网络状态
     * {@enum TPDataTransportDataNetworkState}
     */
    IntNetworkState = "network_state",
    /**
     * 离线下载加速状态开关，0：关闭 1：开启
     */
    IntOfflineAccelerateState = "offline_accelerate_state",
    /**
     * 内存警告通知，大于 0 收到内存警告
     */
    IntReceiveMemoryWarning = "receive_memory_warning",
    /**
     * 自适应策略，非自适应播放absinfo会传空
     */
    AdaptiveAbsInfo = "adaptive_abs_info",
    /**
     * 预推状态控制，0：关闭预推，1：打开预推
     * {@enum TPDataTransportPrePushState}
     */
    IntPrePushState = "enable_prepush",
    /**
     * int 预推最大HTTP下载速度，单位：KB， > 0 为有效值
     */
    IntMaxPrePushHttpDownloadSpeedKB = "max_prepush_http_download_speed_kb",
    /**
     * 视频账号信息，主要用于上报
     */
    VUid = "vuid",
    /**
     * 最大上传速度，单位：KB
     */
    IntMaxUploadSpeedKb = "upload_speed_kb",
    /**
     * 代理端口
     */
    IntHttpProxyPort = "http_proxy_port",
    /**
     * 代理地址
     */
    HttpProxyHost = "http_proxy_host",
    /**
     * int 限制模式，子进程不可用时切换到主进程时使用限制模式
     */
    LimitMode = "limit_mode",
    /**
     * 离线校验失败，传入错误
     */
    OfflineCheckFailed = "offline_check_failed"
}
/**
 * 业务级可配置参数，只有对应业务相关参数生效，可以随时配置
 */
export declare enum TPDataTransportBizOptionalConfigParam {
    /**
     * 业务相关数据存储目录，可以在 {@link TPDataTransportMgr#registerBizId} 之后更新
     */
    DataDir = "data_dir",
    /**
     * long 设置最大缓存大小(如果不设置，会根据剩余空间大小进行自动设置)，单位：MB
     */
    LongMaxCacheSizeMb = "max_cache_size_mb"
}
/**
 * 任务级可配置参数，针对某个任务的配置项
 */
export declare enum TPDataTransportTaskOptionalConfigParam {
    /**
     * long, 播放器播放偏移量, 单位:byte
     */
    LongPlayOffsetByte = "taskinfo_play_offset",
    /**
     * float, 播放速度倍率
     */
    FloatSpeedRatio = "taskinfo_speed_ratio",
    /**
     * long 自适应清晰度切换最高bitrate阈值
     * 和播放器开关保持一致，所以使用和播放器相同 key 的值定义
     */
    MaxBitrate = "optional_id_global_long_adaptive_limit_bitrate_range_max",
    /**
     * long 自适应清晰度切换最高bitrate阈值
     * 播放器的 key 值转成下载内部的值定义
     */
    InnerMaxBitrate = "taskinfo_max_bitrate",
    /**
     * int 自适应清晰度动态切换开关 0：关闭  1：开启
     * 和播放器开关保持一致，所以使用和播放器相同 key 的值定义
     */
    AdaptiveDynamicSwitch = "optional_id_global_int_enable_adaptive_switch_def",
    /**
     * int 自适应清晰度动态切换开关 0：关闭  1：开启
     * 播放器的 key 值转成下载内部的值定义
     */
    InnerAdaptiveDynamicSwitch = "taskinfo_adaptive_dynamic_switch",
    /**
     * string 自适应清晰度控制策略
     */
    AdaptiveControlStrategy = "taskinfo_adaptive_control_strategy",
    /**
     * int {@enum TPDataTransportTaskPlayerState} 播放器状态
     */
    IntPlayerState = "task_player_state",
    /**
     * int {@enum TPDataTransportTaskPlayerEvent} 播放器事件
     */
    IntPlayerEvent = "task_player_event",
    /**
     * int {@enum TPDataTransportTaskRunningState} 任务运行状态，这里逻辑通过 App 设置，单独提供 key
     */
    IntRunningState = "task_running_state",
    /**
     * long 播放器最大缓冲区大小（字节）。底层 Scheduler::IsDownloadOverLimitSize 通过该值
     * 限制缓冲区下载量，0 表示由 safePlayTime*codeRate 自动估算。
     * 对应 Android: TPDownloadProxyEnum.TASKINFO_BUFFER_SIZE_BYTE
     */
    LongBufferSizeByte = "taskinfo_buffer_size_byte",
    /**
     * long 头部 metadata 阶段的播放偏移标记。
     *   value="0"：尚未拿到头部 metadata，但已知会从 0 偏移开始读取，dataproxy 据此放行 m3u8/ts 首批下载；
     *   value="1"：onPrepared 后表示头部已就绪。
     * 对应 Android: TPDownloadProxyEnum.TASKINFO_GET_METADATA_PLAY_OFFSET
     * 注意：底层 Scheduler::UpdateTaskInfo 用 stricmp 不区分大小写匹配该 key。
     */
    LongGetMetadataPlayOffset = "taskInfo_get_metadata_play_offset",
    /**
     * string 播放器是否已经开始播放，"true"/"false"。dataproxy 据此调度 ts 下载节奏。
     * 对应 Android: TPDownloadProxyEnum.TASKINFO_PLAYER_START
     * 注意：底层 Scheduler::UpdateTaskInfo 仅识别 "true"/"false" 字符串。
     */
    StringPlayerStart = "taskInfo_player_start",
    /**
     * int 头部 metadata 阶段获取的码率，单位 kbps。
     * dataproxy 收到后会调用 CacheManager::SetCodeRate 覆盖 m3u8 解析得到的码率。
     * 对应 Android: TPDownloadProxyEnum.TASKINFO_GET_METADATA_BITRATE_KBPS
     */
    IntGetMetadataBitrateKbps = "taskInfo_get_metadata_bitrate_kbps",
    /**
     * int 多网卡开关，0：关闭 1：开启。
     * 对应 Android: TPDownloadProxyEnum.DLPARAM_MULTI_NETWORK
     */
    IntMultiNetwork = "dl_param_multi_network"
}
