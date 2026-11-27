#pragma once

#include "itp_data_transport_offline_task_listener.h"
#include "itp_data_transport_task_param.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportOfflineTaskMgr {
 public:
  ///
  /// 普通离线下载任务，数据会默认缓存到磁盘
  ///
  /// @param taskParam 下载任务相关参数
  /// @param offlineTaskDelegate 任务信息回调
  /// @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
  ///
  virtual int32_t CreateOfflineTask(ITPDataTransportTaskParam* task_param,
                                    ITPDataTransportOfflineTaskListener* offline_task_listener) = 0;

  ///
  /// 多分片任务离线下载，所有任务 url 将看被作互相关联在一起
  ///
  /// @param taskParamList 多个下载任务参数集
  /// @param offlineTaskDelegate 任务信息回调
  /// @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
  ///
  virtual int32_t CreateMultiOfflineTask(
      IDTPArray<ITPDataTransportTaskParam*>* task_param_list,
      ITPDataTransportOfflineTaskListener* offline_task_listener) = 0;

  ///
  /// 开始离线下载任务
  ///
  /// @param task_id {@link #CreateOfflineTask} 创建返回的任务 id
  ///
  virtual void StartOfflineTask(int32_t task_id) = 0;

  ///
  /// 停止离线任务下载，已缓存的数据不会删除，重新创建任务可以继续下载
  ///
  /// @param task_id {@link #CreateOfflineTask} 创建返回的任务 id
  ///
  virtual void StopOfflineTask(int32_t task_id) = 0;

  ///
  /// 更新离线缓存路径，更新后新的离线下载任务都会下载到新的目录
  ///
  /// @param biz_id 业务 id，用于关联存储路径
  /// @param save_path 新的离线缓存路径
  ///
  virtual void UpdateOfflinePath(int32_t biz_id, const char* save_path) = 0;

  ///
  /// 删除已经下载过的离线任务，会删除本地已存储的数据
  ///
  /// @param biz_id 业务 id，用于关联存储路径
  /// @param file_id 文件唯一 id
  ///
  virtual int32_t RemoveOfflineTask(int32_t biz_id, const char* file_id) = 0;

  ///
  /// 腾讯视频业务独有接口
  /// hls 续下载时需要确保获取指定 formatid 清晰度，需要一个加密字段传递给播放后台
  ///
  /// @param vid 视频请求的原始 vid
  /// @param link_vid vinfo 中的 link vid
  /// @param format_id 视频清晰度 id，320001等
  /// @param encrypt_random_num 随机数
  /// @return 加密串 ext tag
  ///
  virtual const char* GetHLSOfflineExtTag(const char* vid, const char* link_vid, int32_t format_id,
                                          int64_t encrypt_random_num) = 0;

  ///
  /// 腾讯视频业务独有接口
  /// 校验离线数据完整性
  ///
  /// @param disk_path 离线存储路径
  /// @param file_format 文件类型, 1-整段 mp4 2- 分片mp4 3- hls
  /// @param resource_id 存储 id
  /// @param key_id 分片 mp4 拼接路径使用，分片文件中的 key_id 前面部分
  /// @return 本地已下载大小
  ///
  virtual int64_t VerifyOfflineCacheSync(const char* disk_path, int32_t file_format,
                                         const char* resource_id, const char* key_id) = 0;
};

NAMESPACE_END