#pragma once

#include "itp_array_interface.h"

NAMESPACE_BEGIN(tpdlproxy)

// 注意：生命周期结束时，需要调用Destroy()方法
template <typename T>
class IDTPMap {
 public:
  virtual bool AddValue(const char* key, T value) = 0;
  virtual void Erase(const char* key) = 0;
  virtual bool GetValue(const char* key, T& result) = 0;
  virtual IDTPArray<const char*>* GetAllKeys() = 0;
  virtual uint32_t GetSize() = 0;
  // 注意：Clone返回的数组指针，生命周期结束时，需要调用Destroy()方法
  virtual IDTPMap<T>* Clone() = 0;
  virtual void Destroy() = 0;

 protected:
  virtual ~IDTPMap() = default;
};

NAMESPACE_END
