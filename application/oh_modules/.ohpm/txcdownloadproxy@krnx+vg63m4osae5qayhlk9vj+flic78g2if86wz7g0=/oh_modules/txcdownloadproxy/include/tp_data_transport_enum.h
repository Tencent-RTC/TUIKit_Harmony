#pragma once
#include "utils/tp_data_transport_common.h"

NAMESPACE_BEGIN(tpdlproxy)

/// 任务类型
enum TPTaskFileType {
  /// 不明确下载类型时默认值
  kTPTaskFileTypeAuto = 0,
  /// 整段 mp4
  kTPTaskFileTypeMp4Vod = 1,
  /// 分片 mp4
  kTPTaskFileTypeClipMp4Vod = 2,
  /// hls
  kTPTaskFileTypeHlsVod = 3,
  /// hls 轮播
  kTPTaskFileTypeHlsVodLoop = 4,
  /// hls 直播
  kTPTaskFileTypeHlsLive = 5,
  /// mp4 广告
  kTPTaskFileTypeMp4Adv = 6,
  /// hls 广告
  kTPTaskFileTypeHlsAdv = 7,
  /// hls 广告轮播
  kTPTaskFileTypeHlsAdvLoop = 8,
  /// 高铁模式
  kTPTaskFileTypeLan = 9,
  /// 文件下载
  kTPTaskFileTypeFileDownload = 10,
  /// 文件代理方式加载
  kTPTaskFileTypeFileVodProxyLoad = 11,
  /// 腾讯云 flv 直播
  kTPTaskFileTypeFlvLive = 12,
  /// hls 音频
  kTPTaskFileTypeHlsAudioVod = 13,
  /// srt 字幕
  kTPTaskFileTypeCaptionSrt = 14,
  /// webvtt 字幕
  kTPTaskFileTypeCaptionWebvtt = 15,
  /// http flv 直播
  kTPTaskFileTypeHttpFlvLive = 16,
  /// flv 直播预加载
  kTPTaskFileTypeHttpPreloadFlvLive = 17,
  /// HLS PROXY 加载数据方式点播
  kTPTaskFileTypeHlsVodProxyLoad = 18,
  /// dash 播放
  kTPTaskFileTypeDash = 19,
  /// MP4 批量任务
  kTPTaskFileTypeMp4Batch = 20,
  /// 分片 MP4批量任务
  kTPTaskFileTypeMp4ClipBatch = 21,
  /// HLS 批量任务
  kTPTaskFileTypeHlsBatch = 22,
  /// flv p2p 直播
  kTPTaskFileTypeP2pFlvLive = 23,
  /// 通用cgi请求，支持多网卡
  kTPTaskFileTypeCGI = 24,
};

/// 代理地址 url 类型
enum TPTaskProxyUrlType {
  /// 优先本地文件地址；自研播放器返回地址时，如果是离线下载完成的，优先返回本地文件地址，否则返回
  /// 127 本地代理地址
  kTPTaskProxyUrlTypeAbsoluteUrlPriority = 0,
  /// 仅使用本地代理地址；系统播放器返回地址时，默认只返回 127 本地代理地址
  kTPTaskProxyUrlTypeProxyUrlOnly = 1,
  /// 使用本地代理地址，只创建任务，但是不驱动下载，只有数据请求时才驱动下载
  kTPTaskProxyUrlTypeProxyUrlCreateTask = 2,
};

/// 任务相关的播放器状态信息
enum TPTaskPlayerState {
  /// 播放中
  kTPTaskPlayerStateOnPlaying = 0,
  /// 播放错误
  kTPTaskPlayerStateOnPlayError = 1,
  /// 播放暂停
  kTPTaskPlayerStateOnPause = 2,
};

/// 任务相关，播放器事件
enum TPTaskPlayerEvent {
  /// 播放器事件通知，seek 开始，用于替换之前的播放器状态 seeking
  kTPTaskPlayerEventSeekStart = 0,
  /// 播放器事件通知，seek 完成
  kTPTaskPlayerEventSeekComplete = 1,
  /// 播放器事件通知，二次缓冲开始
  kTPTaskPlayerEventSecondaryBufferingStart = 2,
  ///  播放器事件通知，二次缓冲结束
  kTPTaskPlayerEventSecondaryBufferingEnd = 3,
};

/// App 可以设置任务的实际运行状态，用于辅助下载任务调度
enum TPTaskRunningState {
  /// 预播放:主要用于多个播放器实例进行播放加速的case
  kTPTaskRunningStateOnPrePlay = 0,
  /// 真实播放:主要用于多个播放器实例进行播放加速的case
  kTPTaskRunningStateOnRealPlay = 1,
};

/// 音视频合流时，数据转码方式
enum kTPDataTransferMode {
  /// 无需特殊转码处理
  kTPDataTransferModeDefault = 0,
  /// 音视频合流转码
  kTPDataTransferModeAv = 1,
  /// fmp4 转 ts
  kTPDataTransferModeFmp4ToTs = 2,
};

/// 嵌套 m3u8 离线下载调度方式
enum TPDataOfflineScheduleLevel {
  /// 调度所有分片下载
  kTPDataOfflineScheduleLevelAll = 0,
  /// 只下载一路低码率流
  kTPDataOfflineScheduleLevelLowBitrate = 1,
  /// 只下载一路高码率流
  kTPDataOfflineScheduleLevelHighBitrate = 2,
  /// 嵌套离线下载直接抛错
  kTPDataOfflineScheduleLevelUnsupported = 3,
};

/// app 前后台状态
enum TPDataAppState {
  /// app 在前台
  kTPDataAppStateForeground = 0,
  /// app 在后台
  kTPDataAppStateBackground = 1,
  /// app 熄屏
  kTPDataAppStateScreenOff = 2,
  /// app 亮屏
  kTPDataAppStateScreenOn = 3,
  /// app 主进程中使用
  kTPDataAppStateMainProcess = 4,
  /// app 子进程中使用
  kTPDataAppStateSubProcess = 5,
  /// app 子进程中使用，主进程退出
  kTPDataAppStateSubProcessAndMainProcessExist = 6,
};

/// p2p 上传状态控制
enum TPDataP2pUploadState {
  /// 上传关闭
  kTPDataP2pUploadStateDisable = 0,
  /// 上传打开
  kTPDataP2pUploadStateEnable = 1,
  /// 隐私合规场景下，上传关闭，优先级最低
  kTPDataP2pUploadStatePrivacyDisable = 2,
  /// 隐私合规场景下，上传打开，优先级最低
  kTPDataP2pUploadStatePrivacyEnable = 3,
};

/// 预推状态控制
enum TPPrepushState {
  /// 关闭预推
  kTPPrepushStateDisable = 0,
  /// 开启预推
  kTPPrepushStateEnable = 1,
};

/// 预下载限速等级
enum TPPredownSpeedLevel {
  /// 普通预下载
  kTPPredownSpeedLevelNormal,
  /// 高峰期限速
  kTPPredownSpeedLevelPeak,
  /// 全速
  kTPPredownSpeedLevelFull,
};

/// 清晰度选择状态
enum TPDataDefinitionSelectionState {
  /// 没有选择清晰度
  kTPDataDefinitionSelectionStateNotSelected = 0,
  /// 已选择清晰度
  kTPDataDefinitionSelectionStateSelected = 1,
};

/// 网络状态
enum TPDataNetworkState {
  /// 无网络
  kTPDataNetworkStateOff = 0,
  /// wifi 网络
  kTPDataNetworkStateWifi = 1,
  /// 移动网络
  kTPDataNetworkStateMobile = 2,
};

/// quic 启用支持的类型
enum TPQuicEnableMode {
  /// 默认值，不开启quic，强制走http
  kTPQuicEnableModeDisable = 0,
  /// quic根据探测结果（header返回alt-svr字段）决定是否开启，推荐
  kTPQuicEnableModeDependOnProbe = 1,
  /// 忽略探测，强制走quic，保证后台对quic的支持，否则quic会失败
  kTPQuicEnableModeForceEnable = 2,
};

/// quic 拥塞控制算法选择 跟 tspdy_quic_request.h 定义保持一致
enum TPQuicCongestionType {
  kTPQuicCongestionTypeCubicBytes = 0,
  kTPQuicCongestionTypeRenoBytes = 1,
  kTPQuicCongestionTypeBbr = 2,
  kTPQuicCongestionTypePcc = 3,
  kTPQuicCongestionTypeGoogcc = 4,
};

/// 删除资源的类型
enum TPClearCacheMode {
  /// 删除单个资源磁盘文件
  kTPClearCacheModeStorage = 0x01,
  /// 移除单个资源离线属性
  kTPClearCacheModeOfflineProperty = 0x01 << 1,
  /// 清理单个资源内存和磁盘文件
  kTPClearCacheModeMemoryStorage = 0x01 << 2,
  /// 清理所有在线播放资源缓存
  kTPClearCacheModeAllOnlineStorage = 0x01 << 3,
};

/// 全局可获取的信息
enum TPGlobalAccessibleNativeInfoType {
  /// 建议码率
  kTPGlobalAccessibleNativeInfoTypeSuggestBitrate = 0,
  /// 建议清晰度，自适应的老逻辑，只有国际版还在用
  kTPGlobalAccessibleNativeInfoTypeSuggestDefn = 1,
  /// 获取蜂窝网卡累计流量
  kTPGlobalAccessibleNativeInfoTypeCellularFlow = 2,
  /// 获取所有累计流量
  kTPGlobalAccessibleNativeInfoTypeFlow = 3,
  /// 获取当前内存占用，字节
  kTPGlobalAccessibleNativeInfoTypeMemory = 5,
  /// 自适应策略，省带宽优先
  kTPGlobalAccessibleNativeInfoTypeAdaptiveStrategyBandwidthFirst = 6,
  /// 自适应策略，体验优先
  kTPGlobalAccessibleNativeInfoTypeAdaptiveStrategyQosFirst = 7,
  /// int 私有自研加密能力，通过 vinfo ckey 透传字段到后台
  kTPGlobalAccessibleNativeInfoTypeSelfEncryptionParamCapacityLevel = 8,
  /// int 自研加密能力，vinfo 透传 ssv
  kTPGlobalAccessibleNativeInfoTypeSelfEncryptionVinfoCapacityLevel = 9,
  /// string 自研加密 key，vinfo ckey 透传 ssk
  kTPGlobalAccessibleNativeInfoTypeSelfEncryptionKey = 10,
  // string 下载的通用策略，带到后台
  kTPGlobalAccessibleNativeInfoDownloadStragetyExtInfo = 11,
};

/// 业务级可获取的信息
enum TPBizAccessibleNativeInfoType {
  /// 暂时没有定义
  kTPBizAccessibleNativeInfoTypeUndefined = 0,
};

// 任务级可获取的信息
enum TPTaskAccessibleNativeInfoType {
  /// 暂时没有定义
  kTPTaskAccessibleNativeInfoTypeUndefined = 0,
};

enum TPCommonInfoType {
  /**
   * native 层配置信息
   */
  kTPCommonInfoTypeNativeConfig = 0,
  /**
   * QUIC质量上报信息回拋
   *
   * param reportInfo 上报信息
   */
  kTPCommonInfoTypeQuicQualityReportUpdate = 1,
  /**
   * 内存警告时，将要进行内存淘汰
   *
   * param extInfo 当前内存信息
   */
  kTPCommonInfoTypeWillReleaseMemory = 2,
  /**
   * 内存警告时，已经完成内存淘汰
   *
   * param extInfo 当前内存信息
   */
  kTPCommonInfoTypeDidReleaseMemory = 3,
};

enum TPCommonInfoCallbackMessage {
  /**
   * url 过期统一回调，把边下边播转在线播放、cdn url 过期处理逻辑相同
   *
   * @param ext1 Map<String,String> 透传参数信息
   */
  kTPCommonInfoCallbackMessageCdnUrlExpired = 1,
  /**
   * 通知播放器切换清晰度
   *
   * @param ext1 static const char*vid
   * @param ext2 static const char*format
   * @param ext3 int32_t bitrate
   */
  kTPCommonInfoCallbackMessageNotifyPlayerSwitchDefinition = 2,
  /**
   * HTTP请求头、响应头信息
   *
   * @param ext1 static const char*header info
   **/
  kTPCommonInfoCallbackMessageHttpHeader = 3,
  /**
   * M3U8内容回调
   */
  kTPCommonInfoCallbackMessageNotifyM3u8Content = 4,
  /**
   * http-flv预下载完成回调
   *
   * @param ext1 int32_t status
   * @param ext2 byte[] codec param
   * @param ext3 static const char*extraInfo
   * @param ext4 int32_t len
   */
  kTPCommonInfoCallbackMessageFlvPreloadStatus = 5,
  /**
   * QUIC下载状态回调
   *
   * @param ext1 static const char*extraInfo
   */
  kTPCommonInfoCallbackMessageQuicDownloadStatus = 6,
  /**
   * Quic 回调上报信息
   */
  kTPCommonInfoCallbackMessageQUICReportQuality = 7,
  /**
   * TAB 实验 ID
   *
   * @param ext1 static const char*tab test key
   * @param ext2 static const char*tab test id
   */
  kTPCommonInfoCallbackMessageTabTestId = 8,
  /**
   * 通知播放器刷新m3u8 buffer
   */
  kTPCommonInfoCallbackMessageM3u8Refresh = 9,
  /**
   * 多网卡命中低速
   *
   * @param ext1 static const char*extraInfo
   */
  kTPCommonInfoCallbackMessageMultiNetworkLowSpeed = 10,
  /**
   * 多网卡使用状态
   *
   * @param ext1 static const char*extraInfo
   */
  kTPCommonInfoCallbackMessageMultiNetworkStatus = 11,
  /**
   * 通知播放器读数据异常
   */
  kTPCommonInfoCallbackMessageReadInvalid = 12,
  /**
   * 开始请求 cdn url，请求的结果在 MESSAGEREQUESTCDNURLCOMPLETE 中回调
   *
   * @param ext1 static const char*cdn url
   */
  kTPCommonInfoCallbackMessageStartRequestCdnUrl = 13,
  /**
   * 完成 cdn 请求，成功、失败都会回调
   *
   * @param ext1 static const char*url cdn url
   * @param ext2 static const char*cdnIp cdn http header "X-ServerIp
   * @param ext3 static const char*uip cdn http header "Client-Ip"
   * @param ext4 static const char*errorCodeStr 获取不到时，上报错误码
   */
  kTPCommonInfoCallbackMessageRequestCdnUrlComplete = 14,
  /**
   * 数据下载状态更新，实时更新数据下载情况，可用于二次缓冲原因上报，非 0 表示具体异常原因 上报用
   *
   * @param ext1 int32_t statusCode 状态码
   */
  kTPCommonInfoCallbackMessageOnDownloadStatusUpdate = 15,
  /**
   * 下载协议相关信息回调，使用 quic/tcp 上报用
   *
   * @param ext1 static const char*protocol 协议类型
   * @param ext2 static const char*protocolVer 协议版本号
   */
  kTPCommonInfoCallbackMessageDownloadProtocolUpdate = 16,
  /**
   * 把边下边播转在线播放
   *
   * @param ext1 Map<String,String> 透传参数信息
   * @deprecated
   */
  kTPCommonInfoCallbackMessageNoMoreData = 17,
  /**
   * 跟 iOS 对齐，Android 目前没用
   * 回前台后，通知播放器本地代理初始化完毕。播放任务需要等本地代理初始化完后，才能发起播放请求
   */
  kTPCommonInfoCallbackMessageReinit = 18,
  /**
   * 跟 iOS 对齐，Android 目前没用
   * 正在播放任务退后台，下载组件调用析构前通知播放器
   */
  kTPCommonInfoCallbackMessageDeinit = 19,
  /**
   * 本地代理 token 校验失败
   *
   * @param ext1 int32_t 错误码
   */
  kTPCommonInfoCallbackMessageVerifyTokenFailed = 20,
  /**
   * 更新下一个分片信息，主要用在轮播场景
   */
  kTPCommonInfoCallbackMessageUpdateNextClip = 21,
  /**
   * 支持多网卡的通用CGI请求结果成功回调
   *
   * @param ext1 int http_status_code，http返回码
   * @param ext2 String http_response_header，http响应头
   * @param ext3 String content，返回内容
   * @param ext4 String extInfo，拓展信息，json格式字符串，目前包含实际请求的网卡信息
   *             网卡类型字段是"networkUse", 取值参考 {@link CgiResponseNetworkType}
   */
  kTPCommonInfoCallbackMessageMultiNetworkCgiSucc = 22,
  /**
   * 支持多网卡的通用CGI请求结果失败回调
   *
   * @param ext1 int error_code，错误码
   * @param ext2 String extInfo，拓展信息，json格式字符串，目前包含http状态码
   *             状态码字段是"httpStatusCode"
   */
  kTPCommonInfoCallbackMessageMultiNetworkCgiFail = 23,
  /**
   * 低清晰度策略，通知播放器无缝上切
   */
  kTPCommonInfoCallbackMessageLowDefnStartSwitchUp = 24,
};

/// biz id
enum TPBizIdDesc {
  /**
   * 非法id，需要检查传入的参数是否异常
   *
   */
  kTPBizIdDescInvalidBizId = -1,
  /**
   * 默认 bizid，通常情况下为离线下载对应的业务
   *
   */
  kTPBizIdDescDefaultBizId = 1000,
  /**
   * 业务自定义业务需要从 10000 往上，10000 以内保留不可以使用
   */
  kTPBizIdDescMaxSelfDefinedBizId = 10000,
};

enum ResourceLoaderResponseCode {
  // 数据读取成功
  kResourceLoaderResponseCodeSuccess = 0,
  // 数据读取重试
  kResourceLoaderResponseCodeTryAgain = -1,
  // 数据读取失败
  kResourceLoaderResponseCodeFailed = -2,
};

/// 全局相关参数枚举 key
/// int 用户的会员状态，0：非会员，1：会员
static const char* kGlobalOptionalConfigParamIntIsVip = "qq_is_vip";
/// 用户 guid
static const char* kGlobalOptionalConfigParamGuid = "guid";
/// bssid
static const char* kGlobalOptionalConfigParamBSSID = "bssid";
/// 平台号，主要用于区分数据上报
static const char* kGlobalOptionalConfigParamIntPlatform = "platform";
/// 外网 ip
static const char* kGlobalOptionalConfigParamExternalNetworkIp = "external_network_ip";
/// app 版本号，主要用于数据上报
static const char* kGlobalOptionalConfigParamAppVersion = "app_version_name";
/// app 系统版本号
static const char* kGlobalOptionalConfigParamOsVersion = "os_version";
/// 设备型号
static const char* kGlobalOptionalConfigParamDeviceModel = "device_model";
/// 联通免流标识
static const char* kGlobalOptionalConfigParamUpc = "carrier_pesudo_code";
/// int 联通免流状态码
static const char* kGlobalOptionalConfigParamIntUpcState = "carrier_pesudo_state";
/// int 最大使用内存上限，单位：mb
static const char* kGlobalOptionalConfigParamIntDeviceMaxUseMemoryMb = "max_use_memory";
/// int 系统保留内存，p2p在剩余内存的计算上要减去这个值，默认是0，单位:m，tv 使用
static const char* kGlobalOptionalConfigParamIntSystemReserveMemoryMb = "system_reserve_memory";
/// int 内存紧张等级 tv 使用
static const char* kGlobalOptionalConfigParamIntTrimMemoryLevel = "trim_memory_level";
/// 更新配置信息，目前应该主要 tv 使用
static const char* kGlobalOptionalConfigParamProxyConfig = "proxy_config";
/// tab 透传 userid
static const char* kGlobalOptionalConfigParamTabAbuserid = "abuserid";
/// tab tab_callback_ack
static const char* kGlobalOptionalConfigParamIntTabCallbackAck = "tab_callback_ack";
/// tab 透传 app 实验 id
static const char* kGlobalOptionalConfigParamTabAbTestId = "app_test_id";
/// 是否使用多网卡，0：不适用，1：使用
static const char* kGlobalOptionalConfigParamIntUseMultiNetwork = "use_multi_network";
/// todo: need to confirm 这个应该属于内部回调
/// 丢包信息回调
static const char* kGlobalOptionalConfigParamLossPackageInfo = "lose_package_check_info";
/// 蜂窝网卡id
static const char* kGlobalOptionalConfigParamLongCellularInterfaceId = "cellular_interface_id";
/// app 状态，前后台、熄屏、亮屏、进程状态
/// {@link appstate}
static const char* kGlobalOptionalConfigParamIntAppState = "app_state";
/// p2p 上传状态 TPDataP2pUploadState
static const char* kGlobalOptionalConfigParamIntP2PUploadState = "enable_p2p_upload";
/// app 清晰度选择状态 TPDataDefinitionSelectionState
static const char* kGlobalOptionalConfigParamIntDefinitionSelectionState =
    "definition_selection_state";
/// 网络状态 TPDataNetworkState
static const char* kGlobalOptionalConfigParamIntNetworkState = "network_state";
/// 离线下载加速状态开关，0：关闭 1：开启
static const char* kGlobalOptionalConfigParamIntOfflineAccelerateState = "offline_accelerate_state";
/// 内存警告通知，大于 0 收到内存警告
static const char* kGlobalOptionalConfigParamIntReceiveMemoryWarning = "receive_memory_warning";
/// 自适应策略，非自适应播放absinfo会传空
static const char* kGlobalOptionalConfigParamAdaptiveAbsInfo = "adaptive_abs_info";
/// 自适应模式，1:省流模式 2:流畅模式 3:画质模式
static const char* kGlobalOptionalConfigParamIntAdaptiveMode = "taskinfo_adaptive_mode";
/// 预推状态控制 TPPrepushState
static const char* kGlobalOptionalConfigParamIntPrepushState = "enable_prepush";
/// int 限制预推最大http下载速度，单位KB，> 0  为有效值
static const char* kGlobalOptionalConfigParamIntMaxPrepushHttpDownloadSpeedKB =
    "max_prepush_http_download_speed_kb";
/// 视频账号信息，主要用于上报
static const char* kGlobalOptionalConfigParamVuid = "vuid";
/// 最大上传速度，单位：KB
static const char* kGlobalOptionalConfigParamIntMaxUploadSpeedKb = "upload_speed_kb";
/// 代理端口
static const char* kGlobalOptionalConfigParamIntHttpProxyPort = "http_proxy_port";
/// 代理地址
static const char* kGlobalOptionalConfigParamHttpProxyHost = "http_proxy_host";
/// int 限制模式，用于区分是否在子进程模式下切换到了主进程
static const char* kGlobalOptionalConfigParamIntLimitMode = "limit_mode";
/// 离线校验失败，传入错误信息
static const char* kGlobalOptionalConfigParamOfflineCheckFailed = "offline_check_failed";

/// 业务相关参数枚举 key
/// 业务相关数据存储目录，可以在 {@link TPmgr#registerbizid} 之后更新
static const char* kBizOptionalConfigParamDataDir = "data_dir";
/// long long 业务相关存储大小，单位：MB
static const char* kBizOptionalConfigParamLongMaxCacheSizeMb = "max_cache_size_mb";

/// 任务相关参数枚举 key
/// long, 播放器播放偏移量, 单位:byte
static const char* kTaskOptionalConfigParamLongPlayOffsetByte = "taskinfo_play_offset";
/// float, 播放速度倍率
static const char* kTaskOptionalConfigParamFloatSpeedRatio = "taskinfo_speed_ratio";
/// long 自适应清晰度切换最高bitrate阈值
/// 和播放器开关保持一致，所以使用和播放器相同 key 的值定义
static const char* kTaskOptionalConfigParamIntMaxBitrate =
    "optional_id_global_long_adaptive_limit_bitrate_range_max";
/// int 自适应清晰度切换最高bitrate阈值，播放器的 key 值转成下载内部的值定义
static const char* kTaskOptionalConfigParamIntInnerMaxBitrate = "taskinfo_max_bitrate";
/// int 自适应清晰度动态切换开关 0：关闭  1：开启，和播放器开关保持一致，所以使用和播放器相同 key
/// 的值定义
static const char* kTaskOptionalConfigParamIntAdaptiveDynamicSwitch =
    "optional_id_global_int_enable_adaptive_switch_def";
/// int 自适应清晰度动态切换开关，播放器的 key 值转成下载内部的值定义
static const char* kTaskOptionalConfigParamIntInnerAdaptiveDynamicSwitch =
    "taskinfo_adaptive_dynamic_switch";
/// int 自适应清晰度控制策略
static const char* kTaskOptionalConfigParamIntAdaptiveControlStrategy =
    "taskinfo_adaptive_control_strategy";
/// int {@link TPTaskPlayerState} 播放器状态
static const char* kTaskOptionalConfigParamIntPlayerState = "task_player_state";
/// int {@link TPTaskPlayerEvent} 播放器事件
static const char* kTaskOptionalConfigParamIntPlayerEvent = "task_player_event";
/// string 播放器 1Hz 进度/缓冲，格式 "playPositionS;playerRemainTimeS;advRemainTimeS"
static const char* kTaskOptionalConfigParamStringPlayerPlayMsg = "task_player_play_msg";
/// int {@link TPTaskRunningState} 任务运行状态，这里逻辑通过 App 设置，单独提供 key
static const char* kTaskOptionalConfigParamIntRunningState = "task_running_state";

/// long 播放器最大缓冲区大小（字节）。底层 Scheduler::IsDownloadOverLimitSize 通过该值
/// 限制缓冲区下载量，0 表示由 safePlayTime*codeRate 自动估算。
/// 对应 Android: TPDownloadProxyEnum.TASKINFO_BUFFER_SIZE_BYTE
static const char* kTaskOptionalConfigParamLongBufferSizeByte = "taskinfo_buffer_size_byte";
/// long 头部 metadata 阶段的播放偏移标记。
///   value="0"：尚未拿到头部 metadata，但已知会从 0 偏移开始读取，dataproxy 据此放行 m3u8/ts 首批下载；
///   value="1"：onPrepared 后表示头部已就绪。
/// 对应 Android: TPDownloadProxyEnum.TASKINFO_GET_METADATA_PLAY_OFFSET
/// 注意：底层 Scheduler::UpdateTaskInfo 用 stricmp 不区分大小写匹配该 key。
static const char* kTaskOptionalConfigParamLongGetMetadataPlayOffset =
    "taskInfo_get_metadata_play_offset";
/// string 播放器是否已经开始播放，"true"/"false"。dataproxy 据此调度 ts 下载节奏。
/// 对应 Android: TPDownloadProxyEnum.TASKINFO_PLAYER_START
/// 注意：底层 Scheduler::UpdateTaskInfo 仅识别 "true"/"false" 字符串。
static const char* kTaskOptionalConfigParamStringPlayerStart = "taskInfo_player_start";
/// int 头部 metadata 阶段获取的码率，单位 kbps。
/// dataproxy 收到后会调用 CacheManager::SetCodeRate 覆盖 m3u8 解析得到的码率。
/// 对应 Android: TPDownloadProxyEnum.TASKINFO_GET_METADATA_BITRATE_KBPS
static const char* kTaskOptionalConfigParamIntGetMetadataBitrateKbps =
    "taskInfo_get_metadata_bitrate_kbps";
/// int 多网卡开关，0：关闭 1：开启。
/// 对应 Android: TPDownloadProxyEnum.DLPARAM_MULTI_NETWORK
static const char* kTaskOptionalConfigParamIntMultiNetwork = "dl_param_multi_network";

NAMESPACE_END
