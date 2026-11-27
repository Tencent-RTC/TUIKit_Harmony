#pragma once

#include "itp_data_transport_message_info.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportOfflineTaskListener {
 public:
  /**
   * 进度回调
   *
   * @param task_id {@link ITPDataTransportOfflineTaskMgr#CreateOfflineTask} 创建任务返回的 id
   * @param playable_duration_ms 可播时长，单位：毫秒 hls
   * 播放时可以返回准确的可播时长，其他格式不可用
   * @param download_speed_kb 下载速度 KB/s
   * @param current_download_size_byte 当前下载字节数
   * @param total_filesize_byte 总字节数，有 vinfo 时一般通过 vinfo 获取总文件大小，其他情况可能没有
   * @param ext_info 扩展信息
   */
  virtual void OnDownloadProgressUpdate(int32_t task_id, int32_t playable_duration_ms,
                                        int32_t download_speed_kb,
                                        int64_t current_download_size_byte,
                                        int64_t total_filesize_byte, const char* ext_info) = 0;

  /**
   * 视频数据全部下载完成
   *
   * @param task_id {@link ITPDataTransportOfflineTaskMgr#CreateOfflineTask} 创建任务返回的 id
   */
  virtual void OnDownloadFinished(int32_t task_id) = 0;

  /**
   * 错误回调
   *
   * @param task_id {@link ITPDataTransportOfflineTaskMgr#CreateOfflineTask} 创建任务返回的 id
   * @param module_id 模块ID
   * @param error_code 错误码
   * @param extInfo 扩展信息
   */
  virtual void OnDownloadError(int32_t task_id, int32_t module_id, int32_t error_code,
                               const char* ext_info) = 0;

  /**
   * 预留：通用回调接口
   *
   * @param task_id {@link ITPDataTransportOfflineTaskMgr#CreateOfflineTask} 创建任务返回的 id
   * @param message_type 消息类型 {@link TPDataTransportTaskCommonMessage}
   * @param message_info 消息内容
   */
  virtual void OnCommonMessageCallback(int32_t task_id, int32_t message_type,
                                       ITPDataTransportMessageInfo* message_info) = 0;
};

NAMESPACE_END