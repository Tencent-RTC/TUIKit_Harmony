#pragma once

#include "utils/itp_object.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportMessageInfo {
 public:
  virtual void InitWithTaskId(int32_t task_id, int32_t message_type, ITPObject* obj1 = nullptr,
                              ITPObject* obj2 = nullptr, ITPObject* obj3 = nullptr,
                              ITPObject* obj4 = nullptr) = 0;

  // 和播放器约定 void*, 按特定格式解析
  virtual int32_t GetTaskId() const = 0;
  virtual int32_t GetMessageType() const = 0;
  virtual void Destroy() = 0;
  // 需要调用 Destroy 释放
  virtual ITPObject* CloneTPObject(int32_t index) = 0;
  // 拷贝整个对象
  virtual ITPDataTransportMessageInfo* Clone() = 0;

 protected:
  virtual ~ITPDataTransportMessageInfo() = default;
};

NAMESPACE_END