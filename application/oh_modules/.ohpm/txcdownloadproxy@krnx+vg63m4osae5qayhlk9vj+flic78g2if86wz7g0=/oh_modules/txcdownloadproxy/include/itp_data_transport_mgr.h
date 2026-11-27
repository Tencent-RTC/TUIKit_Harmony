#pragma once

#include "itp_data_transport_common_info_listener.h"
#include "itp_data_transport_log_listener.h"
#include "itp_data_transport_offline_task_mgr.h"
#include "itp_data_transport_offline_vinfo_adapter.h"
#include "itp_data_transport_preload_task_mgr.h"
#include "itp_data_transport_task_mgr.h"
#include "tp_data_transport_enum.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportMgr {
 public:
  ///
  /// 日志接口，优先设置
  ///
  /// @param log_listener 日志回调接口
  ///
  virtual void SetLogListener(ITPDataTransportLogListener* log_listener) = 0;

  ///
  /// 通用信息回调接口
  ///
  virtual void AddCommonInfoListener(ITPDataTransportCommonInfoListener* common_info_listener) = 0;

  ///
  /// 可以注销对应监听
  ///
  virtual void RemoveCommonInfoListener(
      ITPDataTransportCommonInfoListener* common_info_listener) = 0;

  ///
  /// 获取 native 版本号
  ///
  /// @return 如果 native 加载成功，返回版本号 eg: x.x.x.x，否则为空
  ///
  virtual const char* GetNativeLibVersion() = 0;

  ///
  /// native 是否加载成功，可能加载失败
  ///
  /// 失败表示下载组件不可用
  ///
  virtual bool IsNativeInit() = 0;

  ///
  /// 初始化入口
  ///
  virtual bool InitDataTransport() = 0;

  ///
  /// 带 context 的初始化入口，目前主要给鸿蒙平台用，和 windows 接口暂时区分开
  /// 需要 context 获取一些目录相关的能力
  ///
  virtual bool InitDataTransport(void* context) = 0;

  ///
  /// 反初始化，会注销所有的bizid，析构停止所有线程
  ///
  virtual void DeinitDataTransport() = 0;

  ///
  /// 如果业务需要独立存储、配置逻辑，需要通过存储路径注册业务
  /// id，后续业务相关的播放、预下载、离线等业务都需要带上业务 id 进行关联
  ///
  /// @param data_dir 数据存储目录
  /// @return 业务 id 大于 0，如果 native 没有加载成功会注册失败返回 -1
  ///
  virtual int32_t RegisterBizId(const char* data_dir) = 0;

  ///
  /// 业务方可以自定义业务 id，这种情况下业务 id 的路径可以为空
  ///
  /// @param assigned_biz_id 业务方自己指定的业务 id，需要大于 10000，10000 及以内内部预留避免冲突
  /// @param data_dir 数据存储目录
  /// @return 如果返回和业务方设置的 assignedbiz_id 一致表示注册成功，否则表示注册失败返回 -1
  ///
  virtual int32_t RegisterAssignedBizId(int32_t assigned_biz_id, const char* data_dir) = 0;

  ///
  /// 取消相关业务实例，清除实例相关内存等信息
  /// @param biz_id {@link #RegisterBizId} 根据路径注册后返回
  virtual void UnregisterBizId(int32_t biz_id) = 0;

  ///
  /// 获取常规任务实例
  ///
  /// @return 常规任务实例，初始化失败、子进程实例绑定失败时会返回空
  ///
  virtual ITPDataTransportTaskMgr* GetTaskMgr() = 0;

  ///
  /// 获取预下载任务创建实例
  ///
  /// @return 预加载任务实例，初始化失败、子进程实例绑定失败时会返回空
  ///
  virtual ITPDataTransportPreloadTaskMgr* GetPreloadTaskMgr() = 0;

  ///
  /// 获取离线下载任务创建实例
  ///
  /// @return 离线下载任务实例，初始化失败、子进程实例绑定失败时会返回空
  ///
  virtual ITPDataTransportOfflineTaskMgr* GetOfflineTaskMgr() = 0;

  ///
  /// 设置配置参数信息，全局生效
  ///
  /// @param key {@link TPGlobalOptionalConfigParam} 可全局配置参数
  /// @param value 可全局配置参数值
  /// @return 可能设置失败，底层未初始化
  ///
  virtual bool SetGlobalOptionalConfigParam(const char* key, const char* value) = 0;

  ///
  /// 设置实例相关的参数信息，实例相关场景生效
  /// @param biz_id {@link #RegisterBizId} 生成的业务场景 id，用于索引对应业务的存储目录
  /// @param key {@link TPDataTransportBizOptionalConfigParam} 业务相关可配置参数
  /// @param value 业务相关可配置参数值
  /// @return 可能设置失败，业务未初始化成功
  virtual bool SetBizOptionalConfigParam(int32_t biz_id, const char* key, const char* value) = 0;

  ///
  /// 获取全局相关信息
  ///
  /// @param key {@link TPDataTransportGlobalAccessibleNativeInfoType} 可用的全局信息定义
  /// @return
  ///
  virtual const char* GetGlobalAccessibleNativeInfo(int32_t key) = 0;

  ///
  /// 获取业务级相关信息
  ///
  /// @param biz_id {@link #RegisterBizId} 生成的业务场景 id，用于索引对应业务的存储目录
  /// @param key {@link TPDataTransportBizAccessibleNativeInfoType} 可用的业务级信息定义
  /// @return
  ///
  virtual const char* GetBizAccessibleNativeInfo(int32_t biz_id, int32_t key) = 0;

  ///
  /// 片段删除接口
  /// 接口涉及数据复用和管理，由业务方保障调用的准确性
  /// 场景说明：
  /// 1. 限hls场景下使用
  /// 2. 非hls场景下，使用clearCache或者removeStorageCache删除整个资源
  ///
  /// @param biz_id {@link #RegisterBizId} 生成的业务场景 id，用于索引对应业务的存储目录
  /// @param file_id 任务创建时传的 {@link TPDataTransportTaskParam#TASK_PARAM_FILE_ID}
  /// @param start_time_ms 删除片段的起始时间点，单位ms，以分片为单位
  /// @param end_time_ms 删除片段的结束时间点，单位ms，以分片为单位
  /// @return 是否成功
  ///
  virtual bool ClearRangeCache(int32_t biz_id, const char* file_id, int32_t start_time_ms,
                               int32_t end_time_ms) = 0;

  ///
  /// 删除特定内存数据、缓存数据、离线属性，以及清理所有缓存
  /// 接口涉及数据复用和管理，由业务方保障调用的准确性
  /// 场景说明：
  /// 1. 在线播放开启缓存（只具有在线属性）
  /// 2. 离线下载（只具有离线属性）
  /// 3. 下载 + 在线播放（同时具有在线和离线属性）
  ///
  /// @param biz_id {@link #RegisterBizId} 生成的业务场景 id，用于索引对应业务的存储目录
  /// @param file_id 任务创建时传的 {@link
  /// TPDataTransportTaskParam#TASK_PARAM_FILE_ID}，在删除所有在线缓存时可以传空
  /// @param mode {@link ClearCacheMode} 删除资源的类型
  /// @return 是否成功
  ///
  virtual bool ClearCache(int32_t biz_id, const char* file_id, int32_t mode) = 0;

  ///
  /// 查询资源状态
  ///
  /// @param biz_id {@link #RegisterBizId} 生成的业务场景 id，用于索引对应业务的存储目录
  /// @param file_id 任务创建时传的 {@link
  /// TPDataTransportTaskParam#TASK_PARAM_FILE_ID}，在删除所有在线缓存时可以传空
  /// @param file_format {@link CacheFileFormat} 文件类型
  /// @return 资源状态信息，-1：未知；0：未完成；1：完成
  ///
  virtual int32_t CheckFileCacheStatus(int32_t biz_id, const char* file_id,
                                       int32_t file_format) = 0;

  ///
  /// 获取类型所占缓存大小
  ///
  /// @param biz_id {@link #RegisterBizId} 生成的业务场景 id，用于索引对应业务的存储目录
  /// @param file_id 任务创建时传的 {@link
  /// TPDataTransportTaskParam#TASK_PARAM_FILE_ID}，在删除所有在线缓存时可以传空
  /// @return 资源所占缓存大小
  ///
  virtual int64_t GetFileCacheSize(int32_t biz_id, const char* file_id) = 0;

  ///
  /// 腾讯视频业务独有接口
  /// 腾讯视频离线播放时，需要从另一个模块获取 vinfo，通过接口桥接来实现，避免多个模块引用耦合
  ///
  /// @param vinfo_adapter 离线下载适配
  ///
  virtual void SetOfflineVinfoAdapter(ITPDataTransportOfflineVinfoAdapter* vinfo_adapter) = 0;

  ///
  /// 腾讯视频业务独有接口
  /// 判断某个 vid、format 是否有离线记录，主要用来做离线
  ///
  /// @param vid 视频 vid
  /// @param format 视频清晰度，sd、hd、shd、fhd 等
  /// @return 如果有离线记录，直接返回 vinfo xml，否则返回空字符串
  ///
  virtual const char* CheckVideoStatus(const char* vid, const char* format) = 0;

  ///
  /// 腾讯视频业务独有接口
  /// 获取离线视频时长，有就大于 0，没有结果等于 0
  ///
  /// @param vid 视频 vid
  /// @param format 视频清晰度，sd、hd、shd、fhd 等
  /// @return 离线视频时长
  ///
  virtual int32_t GetRecordDuration(const char* vid, const char* format) = 0;
};

NAMESPACE_END