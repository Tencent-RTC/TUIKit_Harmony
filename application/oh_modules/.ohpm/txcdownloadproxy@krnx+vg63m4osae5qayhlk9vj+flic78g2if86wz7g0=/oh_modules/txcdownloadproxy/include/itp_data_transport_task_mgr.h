#pragma once

#include "itp_data_transport_resource_loader_listener.h"
#include "itp_data_transport_task_listener.h"
#include "itp_data_transport_task_param.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportTaskMgr {
 public:
  /**
   * 普通下载任务
   *
   * @param task_param 下载任务相关参数
   * @param task_listener 任务信息回调
   * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
   */
  virtual int32_t CreateTask(ITPDataTransportTaskParam* task_param,
                             ITPDataTransportTaskListener* task_listener) = 0;

  /**
   * 可以将多个不同 url 下载地址组合成一个任务调度，会将所有 url 关联起来调度，主要用做多个分片 mp4
   * 的下载
   *
   * @param task_param_list 多个下载任务参数集
   * @param task_listener 任务信息回调
   * @return 任务 id，用于后续任务的相关管理标识，返回 <=0 表示任务创建失败
   */
  virtual int32_t CreateMultiTask(IDTPArray<ITPDataTransportTaskParam*>* task_param_list,
                                  ITPDataTransportTaskListener* task_listener) = 0;

  /**
   * 停止任务，当前任务相关逻辑会完全停止，下载停止、数据内存会被逐渐淘汰、任务被淘汰
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   */
  virtual void StopTask(int32_t task_id) = 0;

  /**
   * 暂停任务，下载停止、内存不会淘汰，任务等待继续下载
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   */
  virtual void PauseTask(int32_t task_id) = 0;

  /**
   * 恢复任务，配合 PauseTask 接口，恢复被暂停的任务
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   */
  virtual void ResumeTask(int32_t task_id) = 0;

  /**
   * 主动获取任务下载过程中的错误码
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   * @return 错误码格式化字符串 模块号;错误码  eg:231;1400015
   */
  virtual const char* GetTaskErrorCode(int32_t task_id) = 0;

  /**
   * 任务创建成功后，获取代理 url 地址
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   * @param urlType {@link TPTaskProxyUrlType} 代理 url 类型
   * @return 返回当前任务对应的代理 url 地址
   */
  virtual const char* GetProxyUrl(int32_t task_id, int32_t url_type) = 0;

  /**
   * @param task_id {@link #CreateMultiTask} 创建组合任务返回的 id
   * @param urlType {@link TPTaskProxyUrlType} 代理 url 类型
   * @return 返回组合任务对应代理 url 地址
   */
  virtual IDTPArray<const char*>* GetMultiProxyUrlList(int32_t task_id, int32_t url_type) = 0;

  /**
   * 任务创建后，更新任务下载参数，如果在下载过程中 url、url header 等信息发生变化，可以动态更新
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   * @param task_param 更新的参数内容
   */
  virtual void UpdateRunningTaskParam(int32_t task_id,
                                      IDTPArray<ITPDataTransportTaskParam*>* task_param) = 0;

  /**
   * 任务创建后，可以更新任务相关的配置参数
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   * @param key {@link TaskOptionalConfigParam} 任务级更新相关参数信息
   * @param value 更新参数值
   */
  virtual void SetTaskOptionalConfigParam(int32_t task_id, const char* key, const char* value) = 0;

  /**
   * 任务创建后，获取任务级相关信息
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   * @param key {@link TPTaskAccessibleNativeInfoType} 可获取的任务参数 key
   * @return 对应任务参数信息
   */
  virtual const char* GetTaskAccessibleNativeInfo(int32_t task_id, int32_t key) = 0;

  /**
   * 设置 ResourceLoader 接口通道
   *
   * @param task_id {@link #CreateTask} 创建任务返回的 id
   * @param resource_loader_listener 数据资源读取
   */
  virtual void SetTaskResourceLoaderListener(
      int32_t task_id, ITPDataTransportResourceLoaderListener* resource_loader_listener) = 0;
};

NAMESPACE_END
