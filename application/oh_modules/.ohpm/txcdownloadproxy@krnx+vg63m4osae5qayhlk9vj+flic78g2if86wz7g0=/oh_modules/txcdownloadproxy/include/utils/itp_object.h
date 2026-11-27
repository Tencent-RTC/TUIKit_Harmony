#pragma once
#include "tp_data_transport_common.h"

NAMESPACE_BEGIN(tpdlproxy)

enum ObjectType {
  kObjectTypeBool = 1,
  kObjectTypeInt32,
  kObjectTypeInt64,
  kObjectTypeString,
  kObjectTypeCString,  // 二进制数据，data + len
};

class ITPObject {
 public:
  virtual void Init(int32_t type, const char* value) = 0;
  // value 统一转换成 string 处理
  virtual int32_t GetObjectType() const = 0;
  // 通常 string value 获取
  virtual const char* GetObjectValue() const = 0;
  // 获取 binary data + len
  virtual int32_t GetObjectDataLen() const = 0;
  virtual ITPObject* Clone() = 0;
  virtual void Destroy() = 0;

 protected:
  virtual ~ITPObject() = default;
};

NAMESPACE_END