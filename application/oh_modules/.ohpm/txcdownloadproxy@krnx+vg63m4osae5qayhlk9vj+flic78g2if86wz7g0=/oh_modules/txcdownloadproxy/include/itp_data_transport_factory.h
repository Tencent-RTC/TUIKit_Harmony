#pragma once

#include "itp_data_transport_mgr.h"
#include "itp_data_transport_task_param.h"
#include "utils/itp_object.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportFactory {
 public:
  /// 获取下载组件实例
  virtual ITPDataTransportMgr* GetDataTransportMgr() = 0;
  virtual ITPDataTransportTaskParam* CreateTPDataTransportTaskParam() = 0;
  virtual void DestroyTPDataTransportTaskParam(ITPDataTransportTaskParam* task_param) = 0;

  virtual ITPDataTransportMessageInfo* GetTPDataTransportMessageInfo() = 0;
  virtual void DestoryTPDataTransportMessageInfo(ITPDataTransportMessageInfo* message_info) = 0;

  // 数据结构接口
  virtual IDTPMap<int32_t>* CreateIntTPMap() = 0;
  virtual IDTPMap<const char*>* CreateStringTPMap() = 0;
  virtual IDTPArray<int32_t>* CreateIntTPArray() = 0;
  virtual IDTPArray<const char*>* CreateStringTPArray() = 0;

  // 析构需要将 array 中所有 param 先释放，再释放 array
  virtual IDTPArray<ITPDataTransportTaskParam*>* CreateTaskParamTPArray() = 0;
  virtual ITPObject* CreateTPObject() = 0;

 protected:
  virtual ~ITPDataTransportFactory() = default;
};

NAMESPACE_END