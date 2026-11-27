#pragma once
#include "utils/itp_array_interface.h"
#include "utils/itp_map_interface.h"

NAMESPACE_BEGIN(tpdlproxy)

/// int 文件类型，参考 {@link
/// taskfiletype}，如果明确知道文件的类型可以加快任务调度速度，没有时需要先判断文件类型
static const char* kTaskParamIntFileType = "task_file_type";
/// int 业务 id，{@link TPmgr#registerbizid(java.lang.string)}
/// 如果任务需要用到业务独立的配置项，创建任务时需要同时传递业务注册返回的业务 id，内部会根据业务 id
/// 将相关逻辑关联起来
static const char* kTaskParamIntBizId = "task_biz_id";
/// 文件唯一标识 id，用做同一文件索引 id，普通任务、预下载、离线下载，只要 fileid
/// 保持一致，已下载的数据可以被复用， 同一个文件可能有不同 cdn url，通过该 id 可以将不同 cdn
/// 下载的数据数据关联起来 如果不传该参数，默认使用 cdn url md5 做为唯一标识 id <p>有 vinfo 时，按照
/// vinfo 逻辑拼接</p>
static const char* kTaskParamFileId = "dl_param_play_keyid";
/// 分片 mp4 播放是，需要每个分片的文件索引 id
static const char* kTaskParamClipFileId = "dl_param_play_clip_keyid";
/// arraylist<map<string,string>> 请求cdn url header, 多个 url 对应多个 header,
/// 按照下标一一对应.注意:range的设置不生效，以组件内部计算生成的为准
/// dl_param_url_header 的 value 值可以是json string，也可以是数组
/// 例:
/// {"dl_param_url_header":[{"Host":"vv.video.qq.com","Cookie":"xx1","ExampleA":"xxExample"},{"Host":"testvv.video.qq.com","Cookie":"xx2","ExampleA":"xxExample"}]}
static const char* kTaskParamJsonUrlHeader = "dl_param_url_header";
/// int url 过期时间，单位：秒
/// 有 vinfo 时取 vl.vi.ct
static const char* kTaskParamIntUrlExpireDurationSec = "dl_param_url_expire_time";
/// int 当前任务分片数，有多个播放分片时传递分片总数，单个分片或者 hls 播放传 1 即可
static const char* kTaskParamIntPlayClipCount = "dl_param_play_clip_count";
/// int 当前播放的分片序号，从 1
/// 开始，多分片如果不从第一个分片起播需要指定当前播放分片序号，其他情况默认第一分片
static const char* kTaskParamIntPlayClipNo = "dl_param_play_clip_no";
/// long 文件大小字节数
static const char* kTaskParamLongFileSizeByte = "dl_param_file_size";
/// long 文件时长，单位:毫秒
static const char* kTaskParamLongFileDurationMs = "dl_param_file_duration";
/// 文件 md5，用于数据下载校验
static const char* kTaskParamFileMd5 = "dl_param_file_md5";
/// boolean 是否离线播放
static const char* kTaskParamBoolIsOffline = "dl_param_is_offline";
/// 腾讯视频 vid
static const char* kTaskParamVinfoVid = "dl_param_vid";
/// 腾讯视频 cid
static const char* kTaskParamVinfoCid = "dl_param_cid";
/// app 播放的时候传的清晰度，整段的时候可能和 vinfo 里面的不一样，需要用这个播离线
static const char* kTaskParamPlayDefinition = "dl_param_play_definition";
/// string 当前清晰度：对应下面formatinfo里面的清晰度描述，如sd
static const char* kTaskParamCurrentFormat = "dl_param_current_format";
/// int 当前清晰度 id 与 format 对应
static const char* kTaskParamIntCurrentFormatId = "dl_param_current_formatid";
/// string 用户选择清晰度：如sd
static const char* kTaskParamUserFormat = "dl_param_user_format";
/// int 后台天秤自适应清晰度切换最高清晰度：maxbitrate
static const char* kTaskParamIntMaxBitrate = "dl_param_max_bitrate";
/// int 后台天秤下载策略字段：bandwidthlevel
static const char* kTaskParamIntBandWidthLevel = "dl_param_band_width_level";
/// string 下载策略相关的扩展字段：extinfo
static const char* kTaskParamStrategyExtInfo = "dl_param_strategy_ext_info";
/// boolean 是否是付费视频，特定业务对付费视频有特殊下载调度逻辑
static const char* kTaskParamBoolSourceIsCharge = "dl_param_source_is_charge";
/// boolean 指示是否需要进行缓存加密
static const char* kTaskParamBoolCacheNeedEncrypt = "dl_param_cache_need_encrypt";
/// long 预下载字节数
static const char* kTaskParamLongPreloadSizeByte = "dl_param_preload_size";
/// long 预下载时长，单位:毫秒
static const char* kTaskParamLongPreloadDurationMs = "dl_param_preload_duration";
/// int 安全时间, 单位: 秒
static const char* kTaskParamIntSafePlayTimeSec = "dl_param_safe_play_time";
/// int 紧急时间, 单位: 秒
static const char* kTaskParamIntEmergencyTimeSec = "dl_param_emergency_time";
/// long 缓冲区大小, 单位: byte
static const char* kTaskParamLongBufferSizeByte = "dl_param_buffer_size";
/// string 业务层可以指定单个视频的存储路径，注意，必须是绝对路径并且目录必须保证存在
/// 注：hls类型传参为指定目录路径，例如/xxx/save_dir；mp4及其他类型传参为指定目录目标文件路径，例如/xxx/save_dir/xxx.mp4
/// 每个分片文件需保证下载完，整段文件未分片则需保证整段下载完，否则会缓存在默认路径，直到下载完后移动到指定目录
static const char* kTaskParamSavePath = "dl_param_save_path";
/// int 跳过片头时间点，单位：毫秒
static const char* kTaskParamIntPlayStartTimeMs = "dl_param_play_start_time";
/// int 跳过片尾时间点，单位：毫秒
static const char* kTaskParamIntPlayEndTimeMs = "dl_param_play_end_time";
/// string vinfo linkvid vl.vi.lnk
static const char* kTaskParamVinfoLinkVid = "dl_param_vinfo_link_vid";
/// string  vinfo base 用与加密视频解密 vl.vi.base
static const char* kTaskParamVinfoBase = "dl_param_vinfo_base";
/// int32_t 加密视频解密业务，对应vinfo请求时传入的platform
static const char* kTaskParamIntVinfoRequestPlatform = "dl_param_vinfo_request_platform";
/// string 加密视频解密业务，对应vinfo请求时传入的appver
static const char* kTaskParamVinfoRequestAppVer = "dl_param_vinfo_request_app_ver";
/// long vinfo tm
static const char* kTaskParamLongVinfoTm = "dl_param_vinfo_tm";
/// 一级 m3u8 内容，如果可以提前拿到一级 m3u8 内容，可以减少一次一级 m3u8 请求，加快起播速度
static const char* kTaskParamMasterM3u8Content = "dl_param_vinfo_m3u8";
/// arraylist< map<string, string> > 二级 m3u8 直出内容，用 keyid-m3u8 配对 json 字符串
static const char* kTaskParamJsonSecondaryM3u8Content = "dl_param_vinfo_secondary_m3u8";
/// TPTaskParamKeyJsonSecondaryM3u8Content key keyid
static const char* kTaskParamSecondaryM3u8ContentKeyKeyid = "keyid";
/// TPTaskParamKeyJsonSecondaryM3u8Content key m3u8
static const char* kTaskParamSecondaryM3u8ContentKeyM3u8 = "m3u8";
/// int 是否开启 p2p 下载  fp2p
static const char* kTaskParamIntVinfoFp2p = "dl_param_vinfo_fp2p";
/// int a/b test 字段用于上报 tstid
static const char* kTaskParamIntVinfoTestId = "dl_param_vinfo_testid";
/// string 在线播放的flowid
static const char* kTaskParamPlayFlowId = "dl_param_play_flowid";
/// 用于离线播放兼容
static const char* kTaskParamOfflinePlayExtraInfo = "dl_param_play_extra_info";
/// boolean 是否可以在下载地址里面添加扩展参数
static const char* kTaskParamBoolEnableExpandDownloadUrl = "dl_param_enable_expand_download_url";
/// int 是否做自适应【自适应切换类型，枚举值{0:非自适应播放, 1:无限制自适应,
/// 2:自适应不超过起播清晰度】
static const char* kTaskParamIntAdaptiveType = "dl_param_adaptive_type";
/// arraylist< map<string, string> >
/// 所有清晰度信息节点列表，可续可拓展map信息，list[{"dl_param_name":"%s", "dl_param_bitrate":"%s"
/// },
/// {"dl_param_name":"%s", "dl_param_bitrate":"%s" },...]
static const char* kTaskParamJsonFormatNodes = "dl_param_format_nodes";
/// TPTaskParamKeyJsonFormatNodes json 字符 key name
static const char* kTaskParamFormatNodesKeyName = "dl_param_name";
/// TPTaskParamKeyJsonFormatNodes json 字符 key bitrate
static const char* kTaskParamIntFormatNodesKeyBitrateBps = "dl_param_bitrate";
/// int {@link datatransfermode} 视频数据转码方式，目前用于 tv 音频与视频合流
static const char* kTaskParamIntDataTransferMode = "dl_param_data_transfer_mode";
/// pcdn url list
static const char* kTaskParamPcdnUrls = "dl_param_pcdn_urls";
/// pcdn vt list
static const char* kTaskParamPcdnVts = "dl_param_pcdn_vts";
/// int 直播流预期的低延时时间，单位：ms
static const char* kTaskParamIntLiveExpectDelayTimeMs = "dl_param_expect_delay_time";
/// int {@link quicenablemode} quic 启用支持的类型
static const char* kTaskParamIntQuicEnableMode = "dl_param_quic_enable_mode";
/// int {@link quiccongestiontype} quic 拥塞控制算法选择 跟tspdy_quic_request.h定义保持一致
static const char* kTaskParamIntQuicCongestionType = "dl_param_quic_congestion_type";
/// boolean quic 明文传输开关
static const char* kTaskParamBoolEnableQuicPlainText = "dl_param_is_enable_quic_plaintext";
/// boolean quic 连接迁移开关
static const char* kTaskParamBoolEnableQuicConnectionMigration =
    "dl_param_is_enable_quic_connection_migration";
/// int 实际开始播放倒计时，单位：秒
static const char* kTaskParamIntRemainDurationBeforeRealPlaySec = "dl_param_adv_remain_time";
/// int 多网卡开关，0：关闭 1：开启
static const char* kTaskParamIntEnableMultiNetwork = "dl_param_multi_network";
/// boolean 是否下载 0.ts
static const char* kTaskParamBoolDownloadFirstClip = "dl_param_first_clip";
/// int 源站标识，0自建，1腾讯云
static const char* kTaskParamIntVinfoCdnOrigin = "dl_param_vinfo_cdn_origin";
/// int cdn播放体验等级
static const char* kTaskParamIntVinfoPlayExperienceLevel = "dl_param_vinfo_play_experience_level";
/// string xp2p app id
static const char* kTaskParamXp2pId = "xp2p_id";
/// string xp2p app key
static const char* kTaskParamXp2pKey = "xp2p_key";
/// string xp2p app secret key
static const char* kTaskParamXp2pSecretKey = "xp2p_secretkey";
/// string package name
static const char* kTaskParamPackageName = "package";
/// boolean enable teg pcdn
static const char* kTaskParamBoolEnableTegPcdn = "dl_param_enable_teg_pcdn";
/// string nonce 透传, base 通过 tpdownloadproxyparamvinfobase 透传
static const char* kTaskParamNonce = "dl_param_nonce";
/// string 用于加密视频解密,需配合nonce使用
static const char* kTaskParamEncryptStreamKey = "dl_param_encrypt_stream_key";
/// string 用于static const char* kTaskParamencrypt_stream_key解密
static const char* kTaskParamEncryptStreamRandoms = "dl_param_encrypt_stream_randoms";
/// int {@link offlineschedulelevel}  嵌套 m3u8 离线下载的调度方式
static const char* kTaskParamIntOfflineSchedulerLevel = "dl_param_offline_schedule_level";
/// string app test id用于关联app tab实验平台ab上报
static const char* kTaskParamAppTestId = "dl_param_app_testid";
/// boolean 用于外部控制是否优先使用内部的dns缓存，再使用原始的url顺序
static const char* kTaskParamBoolDnsCacheFirst = "dl_param_dns_cache_first";
/// string 用于外部控制是否使用http代理地址
static const char* kTaskParamTaskHttpProxyHost = "dl_param_http_proxy_host";
/// int 用于外部控制是否使用http代理端口
static const char* kTaskParamIntTaskHttpProxyPort = "dl_param_http_proxy_port";
/// boolean 指定下载绝对路径下优先使用拷贝的, 用于本地上传(p2p)
static const char* kTaskParamBoolCacheCopyFirst = "dl_param_cache_copy_first";
/// string 用于统计各场景下数据，业务方自定义
static const char* kTaskParamSceneId = "dl_param_scene_id";
/// string 任务级pcdn charge id，用于pcdn 带宽统计与结算
static const char* kTaskParamPcdnChargeId = "dl_param_pcdn_charge_id";
/// boolean 是否需要流量控制
static const char* kTaskParamBoolNeedFlowControl = "dl_param_need_flow_control";
/// boolean 是否需要缓存到磁盘文件
static const char* kTaskParamBoolNeedCache = "dl_param_need_cache";
/// long 单位: 毫秒，预下载启动时间超过该值则使用http下载，之前使用p2p/pcdn
static const char* kTaskParamLongPrepareHttpStartTimeMs = "dl_param_prepare_http_start_time";
/// long 单位: 毫秒，预下载超时时间，运行超过阈值时间则回调预下载超时出错
static const char* kTaskParamLongPrepareRunningTimeoutMs = "dl_param_prepare_running_timeout";
/// boolean，标识数据如果需要缓存到磁盘，由调用方管理数据的淘汰
static const char* kTaskParamBoolPrepareAttachPersistentProperty =
    "dl_param_attach_persistent_property";
/// string 本地代理 token 密钥，随机数
static const char* kTaskParamAuthenticationTokenKey = "dl_param_authentication_token_key";
/// string 本地代理交互加解密key
static const char* kTaskParamAuthenticationEncryptKey = "dl_param_authentication_encrypt_key";
/// boolean 表示数据是否可以复用，对不可复用的进行fileid的时间戳拼接处理
static const char* kTaskParamBoolDownloadDataReusable = "dl_param_download_data_reusable";
/// int vinfo来源，0默认，1多网卡
static const char* kTaskParamIntVinfoFromType = "dl_param_vinfo_from_type";
/// string cdn 私有拼接参数
static const char* kTaskParamVinfoSelfCdnParam = "dl_param_vinfo_self_cdn_param";
/// string ts 打点上报序号列表，eg "1,3,5,7"
static const char* kTaskParamVinfoTsReportSequenceList = "dl_param_vinfo_ts_report_sequence_list";
// string vinfo 下发备选url
static const char* kTaskParamMultiNetUrl = "dl_param_multi_net_url";
// boolean 是否是试看视频
static const char* kTaskParamBoolIsPreview = "dl_param_is_preview";
/// string vinfo 下发的新版 chacha20 密钥字符串
static const char* kTaskParamVinfoSelfEncryptionCiphertext = "dl_param_vinfo_data_processor_text";
/// int {@likn TPPredownSpeedLevel } 预下载限速等级
static const char* kTaskParamIntPredownSpeedLevel = "dl_param_predown_speed_level";

class ITPDataTransportTaskParam {
 public:
  virtual void InitWithUrlList(IDTPArray<const char*>* url_list) = 0;

  virtual void InitWithUrlList(IDTPArray<const char*>* url_list,
                               IDTPMap<const char*>* extra_Info) = 0;

  virtual IDTPArray<const char*>* GetUrlList() = 0;

  virtual IDTPMap<const char*>* GetExtraTaskParam() = 0;

  // new
  virtual void SetDlType(int32_t dl_type) = 0;
  virtual int32_t GetDlType() const = 0;

  virtual int32_t GetClipCount() const = 0;
  virtual int32_t GetClipNo() const = 0;

  virtual BOOL IsOffline() const = 0;
  virtual BOOL IsAdaptive() const = 0;
  virtual BOOL IsCharge() const = 0;
  virtual BOOL IsDownloadDataReusable() const = 0;
  virtual BOOL IsUseP2p() const = 0;
  virtual BOOL IsTencentCloudOrigin() const = 0;

  virtual const char* GetCdnUrls() = 0;
  virtual const char* GetVid() const = 0;
  virtual const char* GetKeyId() const = 0;
  virtual const char* GetClipKeyId() const = 0;
  virtual const char* GetSavePath() const = 0;
  virtual const char* GetExtraJsonInfo() = 0;
  virtual const char* GetPlayDefinition() const = 0;

  virtual int32_t GetBizId(int32_t default_biz_id) = 0;

  virtual void Destroy() = 0;

 protected:
  virtual ~ITPDataTransportTaskParam() = default;
};

NAMESPACE_END