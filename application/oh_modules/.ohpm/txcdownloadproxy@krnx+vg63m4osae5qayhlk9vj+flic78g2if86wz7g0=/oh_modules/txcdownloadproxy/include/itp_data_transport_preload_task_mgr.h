#pragma once

#include "itp_data_transport_preload_task_listener.h"
#include "itp_data_transport_task_param.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportPreloadTaskMgr {
 public:
  /**
   * 普通预下载下载任务
   *
   * @param task_param 下载任务相关参数
   * @param preload_task_listener 任务信息回调
   * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
   */
  virtual int32_t CreatePreloadTask(ITPDataTransportTaskParam* task_param,
                                    ITPDataTransportPreloadTaskListener* preload_task_listener) = 0;

  /**
   * @param preload_task_id {@link #CreatePreloadTask} 创建的预下载任务 id
   */
  virtual void StopPreloadTask(int32_t preload_task_id) = 0;

  /**
   * 任务创建后，可以更新任务相关的配置参数
   *
   * @param preload_task_id {@link #CreatePreloadTask} 创建的预下载任务 id
   * @param key 任务相关参数枚举
   * @param value
   */
  virtual void SetPreloadTaskOptionalConfigParam(int32_t preload_task_id, const char* key,
                                                 const char* value) = 0;
};

NAMESPACE_END