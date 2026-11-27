import { TPDataTransportTaskFileType } from './TPDataTransportEnum';
export declare enum TPDataTransportTaskParamKey {
    /**
     * int 文件类型，参考 {@enum TPDataTransportTaskFileType}，如果明确知道文件的类型可以加快任务调度速度，没有时需要先判断文件类型
     */
    IntFileType = "task_file_type",
    /**
     * int 业务 id，{@link TPDataTransportMgr#registerBizId(java.lang.String)}
     * 如果任务需要用到业务独立的配置项，创建任务时需要同时传递业务注册返回的业务 id，内部会根据业务 id 将相关逻辑关联起来
     */
    IntBizId = "task_biz_id",
    /**
     * 文件唯一标识 id，用做同一文件索引 id，普通任务、预下载、离线下载，只要 fileid 保持一致，已下载的数据可以被复用，
     * 同一个文件可能有不同 cdn url，通过该 id 可以将不同 cdn 下载的数据数据关联起来
     * 如果不传该参数，默认使用 cdn url md5 做为唯一标识 id
     * <p>有 vinfo 时，按照 vinfo 逻辑拼接</p>
     */
    FileId = "dl_param_play_keyid",
    /**
     * 分片 MP4 播放是，需要每个分片的文件索引 id
     */
    ClipFileId = "dl_param_play_clip_keyid",
    /**
     * ArrayList<Map<String,String>> 请求CDN URL header, 多个 url 对应多个 header, 按照下标一一对应.注意:range的设置不生效，以组件内部计算生成的为准
     * 例:
     * {"dl_param_url_header":[{"Host":"vv.video.qq.com","Cookie":"xx1","ExampleA":"xxExample"},{"Host":"testvv.video.qq.com","Cookie":"xx2","ExampleA":"xxExample"}]}
     */
    JsonUrlHeader = "dl_param_url_header",
    /**
     * int url 过期时间，单位：秒
     * 有 vinfo 时取 vl.vi.ct
     */
    IntUrlExpireDurationSec = "dl_param_url_expire_time",
    /**
     * int 当前任务分片数，有多个播放分片时传递分片总数，单个分片或者 hls 播放传 1 即可
     */
    IntPlayClipCount = "dl_param_play_clip_count",
    /**
     * int 当前播放的分片序号，从 1 开始，多分片如果不从第一个分片起播需要指定当前播放分片序号，其他情况默认第一分片
     */
    IntPlayClipNo = "dl_param_play_clip_no",
    /**
     * long 文件大小字节数
     */
    LongFileSizeByte = "dl_param_file_size",
    /**
     * long 文件时长，单位:毫秒
     */
    LongFileDurationMs = "dl_param_file_duration",
    /**
     * 文件 md5，用于数据下载校验
     */
    FileMd5 = "dl_param_file_md5",
    /**
     * boolean 是否离线播放
     */
    BooleanIsOffline = "dl_param_is_offline",
    /**
     * 腾讯视频 vid
     */
    VinfoVid = "dl_param_vid",
    /**
     * 腾讯视频 cid
     */
    VinfoCid = "dl_param_cid",
    /**
     * App 播放的时候传的清晰度，整段的时候可能和 vinfo 里面的不一样，需要用这个播离线
     */
    PlayDefinition = "dl_param_play_definition",
    /**
     * string 当前清晰度：对应下面formatInfo里面的清晰度描述，如sd
     */
    CurrentFormat = "dl_param_current_format",
    /**
     * int 当前清晰度 id 与 format 对应
     */
    IntCurrentFormatId = "dl_param_current_formatid",
    /**
     * string 用户选择清晰度：如sd
     */
    UserFormat = "dl_param_user_format",
    /**
     * int 后台天秤自适应清晰度切换最高清晰度：maxbitrate
     */
    IntMaxBitrate = "dl_param_max_bitrate",
    /**
     * int 后台天秤下载策略字段：bandwidthlevel
     */
    IntBandWidthLevel = "dl_param_band_width_level",
    /**
     * string 下载策略相关的扩展字段：extinfo
     */
    StrategyExtInfo = "dl_param_strategy_ext_info",
    /**
     * boolean 是否是付费视频，特定业务对付费视频有特殊下载调度逻辑
     */
    BooleanSourceIsCharge = "dl_param_source_is_charge",
    /**
     * boolean 指示是否需要进行缓存加密
     */
    BooleanCacheNeedEncrypt = "dl_param_cache_need_encrypt",
    /**
     * long 预下载字节数
     */
    LongPreloadSizeByte = "dl_param_preload_size",
    /**
     * long 预下载时长，单位:毫秒
     */
    LongPreloadDurationMs = "dl_param_preload_duration",
    /**
     * int 安全时间, 单位: 秒
     */
    IntSafePlayTimeSec = "dl_param_safe_play_time",
    /**
     * int 紧急时间, 单位: 秒
     */
    IntEmergencyTimeSec = "dl_param_emergency_time",
    /**
     * long 缓冲区大小, 单位: byte
     */
    LongBufferSizeByte = "dl_param_buffer_size",
    /**
     * string 业务层可以指定单个视频的存储路径，注意，必须是绝对路径并且目录必须保证存在
     * 注：HLS 类型传参为指定目录路径，例如 /xxx/save_dir；mp4及其他类型传参为指定目录目标文件路径，例如 /xxx/save_dir/xxx.mp4
     * 每个分片文件需保证下载完，整段文件未分片则需保证整段下载完，否则会缓存在默认路径，直到下载完后移动到指定目录
     */
    SavePath = "dl_param_save_path",
    /**
     * int 跳过片头时间点，单位：毫秒
     */
    IntPlayStartTimeMs = "dl_param_play_start_time",
    /**
     * int 跳过片尾时间点，单位：毫秒
     */
    IntPlayEndTimeMs = "dl_param_play_end_time",
    /**
     * string vinfo link vid vl.vi.lnk
     */
    VinfoLinkVid = "dl_param_vinfo_link_vid",
    /**
     * string  vinfo base 用与加密视频解密 vl.vi.base
     */
    VinfoBase = "dl_param_vinfo_base",
    /**
     * int32_t 加密视频解密业务，对应vinfo请求时传入的platform
     */
    VinfoRequestPlatform = "dl_param_vinfo_request_platform",
    /**
     * string 加密视频解密业务，对应vinfo请求时传入的appVer
     */
    VinfoRequestAppVer = "dl_param_vinfo_request_app_ver",
    /**
     * long vinfo tm
     */
    LongVinfoTimestamp = "dl_param_vinfo_tm",
    /**
     * 一级 m3u8 内容，如果可以提前拿到一级 m3u8 内容，可以减少一次一级 m3u8 请求，加快起播速度
     */
    MasterM3u8Content = "dl_param_vinfo_m3u8",
    /**
     * 新接口播放器直接拼装 json 字符串传过来
     */
    JsonSecondaryM3u8Content = "dl_param_vinfo_secondary_m3u8",
    /**
     *  TP_DATA_TRANSPORT_TASK_PARAM_JSON_SECONDARY_M3U8_CONTENT key keyid
     */
    SecondaryM3u8ContentKeyFileId = "keyid",
    /**
     *  TP_DATA_TRANSPORT_TASK_PARAM_JSON_SECONDARY_M3U8_CONTENT key m3u8
     */
    SecondaryM3u8ContentKeyM3u8 = "m3u8",
    /**
     * int 是否开启 p2p 下载  fp2p
     */
    IntVinfoFp2p = "dl_param_vinfo_fp2p",
    /**
     * int a/b test 字段用于上报 tstid
     */
    IntVinfoTestId = "dl_param_vinfo_testid",
    /**
     * string 在线播放的flowId
     */
    PlayFlowId = "dl_param_play_flowid",
    /**
     * 用于离线播放兼容
     */
    OfflinePlayExtraInfo = "dl_param_play_extra_info",
    /**
     * boolean 是否可以在下载地址里面添加扩展参数
     */
    BooleanEnableExpandDownloadUrl = "dl_param_enable_expand_download_url",
    /**
     * int 是否做自适应【自适应切换类型，枚举值{0:非自适应播放, 1:无限制自适应, 2:自适应不超过起播清晰度】
     */
    IntAdaptiveType = "dl_param_adaptive_type",
    /**
     * ArrayList< Map<String, String> > 所有清晰度信息节点列表，可续可拓展map信息，list[{"dl_param_name":"%s", "dl_param_bitrate":"%s" },
     * {"dl_param_name":"%s", "dl_param_bitrate":"%s" },...]
     */
    JsonFormatNodes = "dl_param_format_nodes",
    /**
     *  TP_DATA_TRANSPORT_TASK_PARAM_JSON_FORMAT_NODES json 字符 key name
     */
    FormatNodesKeyName = "dl_param_name",
    /**
     *  TP_DATA_TRANSPORT_TASK_PARAM_JSON_FORMAT_NODES json 字符 key bitrate
     */
    FormatNodesKeyBitratePbs = "dl_param_bitrate",
    /**
     * int {@enum TPDataTransportDataTransferMode} 视频数据转码方式，目前用于 tv 音频与视频合流
     */
    IntDataTransferMode = "dl_param_data_transfer_mode",
    /**
     * pcdn url list
     */
    PcdnUrls = "dl_param_pcdn_urls",
    /**
     * pcdn vt list
     */
    PcdnsVts = "dl_param_pcdn_vts",
    /**
     * int 直播流预期的低延时时间，单位：ms
     */
    IntLiveExpectDelayTimeMs = "dl_param_expect_delay_time",
    /**
     * int {@enum TPDataTransportQuicEnableMode} QUIC 启用支持的类型
     */
    IntQuicEnableMode = "dl_param_quic_enable_mode",
    /**
     * int {@enum TPDataTransportQuicCongestionType} quic 拥塞控制算法选择 跟tspdy_quic_request.h定义保持一致
     */
    IntQuicCongestionType = "dl_param_quic_congestion_type",
    /**
     * boolean quic 明文传输开关
     */
    BooleanEnableQuicPlaintext = "dl_param_is_enable_quic_plaintext",
    /**
     * boolean quic 连接迁移开关
     */
    BooleanEnableQuicConnectionMigration = "dl_param_is_enable_quic_connection_migration",
    /**
     * int 实际开始播放倒计时，单位：秒
     */
    IntRemainDurationBeforeRealPlaySec = "dl_param_adv_remain_time",
    /**
     * int 多网卡开关，0：关闭 1：开启
     */
    IntEnableMultiNetwork = "dl_param_multi_network",
    /**
     * boolean 是否下载 0.ts
     */
    BooleanDownloadFirstClip = "dl_param_first_clip",
    /**
     * int 源站标识，0自建，1腾讯云
     */
    IntVinfoCdnOrigin = "dl_param_vinfo_cdn_origin",
    /**
     * int cdn 播放体验等级 vinfo 返回
     */
    IntPlayExperienceLevel = "dl_param_vinfo_play_experience_level",
    /**
     * xp2p app id
     */
    Xp2pId = "xp2p_id",
    /**
     * xp2p app key
     */
    Xp2pKey = "xp2p_key",
    /**
     * xp2p app secret key
     */
    Xp2pSecretKey = "xp2p_secretKey",
    /**
     * package name
     */
    PackageName = "package",
    /**
     * enable teg pcdn
     */
    EnableTegPcen = "dl_param_enable_teg_pcdn",
    /**
     * nonce 透传, base 通过 TPDownloadProxyParamVinfoBase 透传
     */
    Nonce = "dl_param_nonce",
    /**
     * string 用于加密视频解密,需配合nonce使用
     */
    EncryptStreamKey = "dl_param_encrypt_stream_key",
    /**
     * string 用于 TP_DATA_TRANSPORT_TASK_PARAM_ENCRYPT_STREAM_KEY解密
     */
    EncryptStreamRandoms = "dl_param_encrypt_stream_randoms",
    /**
     * int {@link OfflineScheduleLevel}  嵌套 m3u8 离线下载的调度方式
     */
    IntOfflineSchedulerLevel = "dl_param_offline_schedule_level",
    /**
     * string app test id用于关联app TAB实验平台AB上报
     */
    AppTestId = "dl_param_app_testid",
    /**
     * boolean 用于外部控制是否优先使用内部的dns缓存，再使用原始的url顺序
     */
    BooleanDnsCacheFirst = "dl_param_dns_cache_first",
    /**
     * string 用于外部控制是否使用http代理地址
     */
    HttpProxyHost = "dl_param_http_proxy_host",
    /**
     * int 用于外部控制是否使用http代理端口
     */
    IntHttpProxyPort = "dl_param_http_proxy_port",
    /**
     * boolean 指定下载绝对路径下优先使用拷贝的, 用于本地上传(P2P)
     */
    BooleanCacheCopyFirst = "dl_param_cache_copy_first",
    /**
     * string 用于统计各场景下数据，业务方自定义
     */
    SceneId = "dl_param_scene_id",
    /**
     * string 任务级pcdn charge id，用于pcdn 带宽统计与结算
     **/
    PcdnChargeId = "dl_param_pcdn_charge_id",
    /**
     * boolean 是否需要流量控制
     **/
    BooleanNeedFlowControl = "dl_param_need_flow_control",
    /**
     * boolean 是否需要缓存到磁盘文件
     **/
    BooleanNeedCache = "dl_param_need_cache",
    /**
     * long 单位: 毫秒，预下载启动时间超过该值则使用HTTP下载，之前使用P2P/PCDN
     **/
    LongPrepareHttpStartTimeMs = "dl_param_prepare_http_start_time",
    /**
     * long 单位: 毫秒，预下载超时时间，运行超过阈值时间则回调预下载超时出错
     **/
    LongPrepareRunningTimeoutMs = "dl_param_prepare_running_timeout",
    /**
     * boolean，标识数据如果需要缓存到磁盘，由调用方管理数据的淘汰
     **/
    BooleanPrepareAttachPersistentProperty = "dl_param_attach_persistent_property",
    /**
     * string 本地代理 token 密钥，随机数
     */
    CheckAuthenticationTokenKey = "dl_param_authentication_token_key",
    /**
     * string 本地代理交互加解密key
     */
    CheckEncryptTokenKey = "dl_param_authentication_encrypt_key",
    /**
     * boolean, 表示数据是否可以复用，对不可复用的进行fileid的时间戳拼接处理
     */
    BooleanDownloadDataReusable = "dl_param_download_data_reusable",
    /**
     * int vinfo来源，0默认，1多网卡
     */
    IntVinfoFromType = "dl_param_vinfo_from_type",
    /**
     * string vinfo 下发 cdn 私有拼接参数
     */
    VinfoSelfCdnParam = "dl_param_vinfo_self_cdn_param",
    /**
     * string vinfo 下发 ts 打点上报序号列表，eg "1,3,5,7"
     */
    VinfoTsReportSequenceList = "dl_param_vinfo_ts_report_sequence_list",
    /**
     * boolean 是否是试看视频
     */
    BooleanIsPreview = "dl_param_is_preview",
    /**
     * string 请求cdn url method，GET/POST等，一般传全大写模式，但内部判断时不区分大小写
     */
    UrlMethod = "dl_param_url_method",
    /**
     * string 请求cdn url post body。需对其进行标准的Base64编码后再传入
     */
    UrlPostBody = "dl_param_url_post_body",
    /**
     * int {@link CgiRequestNetworkTypePriority} 多网卡cgi请求优先指定的网卡模式，默认使用 WI-FI 请求
     */
    IntCgiRequestNetworkTypePriority = "dl_param_cgi_network_priority",
    /**
     * int {@link CgiRequestLinkMethod}  多网卡CGI请求的连接方式，http/https等，默认使用 https
     */
    IntCgiRequestLinkMethod = "dl_param_cgi_link_method",
    /**
     * int 多网卡CGI超时回调时长，单位：毫秒
     */
    IntCgiTimeoutMs = "dl_param_cgi_timeout_ms",
    /**
     * boolean 是否低清晰度启播
     */
    BooleanLowDefinitionStart = "dl_param_low_defn_start",
    /**
     * string vinfo 下发备选url
     */
    MultiNetUrl = "dl_param_multi_net_url",
    /**
     * string vinfo 下发的新版 chacha20 密钥字符串
     */
    VinfoSelfEncryptionCiphertext = "dl_param_vinfo_data_processor_text",
    /**
     * long 偏好清晰度 yunxiao
     */
    LongPreferredResolution = "dl_param_preferred_resolution"
}
export type TPDataTransportTaskExtraParam = Record<string, string>;
export declare class TPDataTransportTaskParam {
    private urls;
    private extraParams;
    constructor(urls: Array<string>, extraParams?: TPDataTransportTaskExtraParam);
    private getExtraTaskParamsValueInt;
    private getExtraTaskParamsValueBoolean;
    getFileType(): TPDataTransportTaskFileType;
    getPreloadFileType(): TPDataTransportTaskFileType;
    getOfflineFileType(): TPDataTransportTaskFileType;
    getOfflinePlayFileType(): TPDataTransportTaskFileType;
    getAdaptivePlayFileType(): TPDataTransportTaskFileType;
    getBizId(defaultBizId?: number): number;
    getFileId(): string;
    getClipFileId(): string;
    getClipNo(): number;
    getUrls(): string;
    getSavePath(): string;
    getExtraJsonInfo(): string;
    isOffline(): boolean;
    isAdaptive(): boolean;
}
