#pragma once

#include <stdint.h>

#include "tp_data_transport_common.h"

NAMESPACE_BEGIN(tpdlproxy)

// 注意：生命周期结束时，需要调用Destroy()方法
template <typename T>
class IDTPArray {
 public:
  virtual bool AddValue(T value) = 0;
  virtual void Erase(uint32_t index) = 0;
  virtual bool GetValue(uint32_t index, T& result) = 0;
  virtual uint32_t GetSize() = 0;
  // 注意：Clone返回的数组指针，生命周期结束时，需要调用Destroy()方法
  virtual IDTPArray<T>* Clone() = 0;
  virtual void Destroy() = 0;

 protected:
  virtual ~IDTPArray() = default;
};

NAMESPACE_END
