#pragma once

#include "tp_data_transport_enum.h"

NAMESPACE_BEGIN(tpdlproxy)
class ITPDataTransportResourceLoaderData {
 public:
  virtual const char* GetData() = 0;
  virtual int64_t GetDataLength() = 0;
  virtual int32_t GetResponseCode() = 0;

  // 设置读取的数据，内部进行拷贝赋值
  virtual void Init(const char* data, int64_t data_length,
                    ResourceLoaderResponseCode response_code) = 0;

  // 销毁复制的数据类型信息，释放内存
  virtual void Destroy() = 0;

  // 深拷贝一个副本
  virtual ITPDataTransportResourceLoaderData* Clone() = 0;

 private:
  // 读取到的数据，Init赋值，Destroy释放
  char* data_;

  // 读取到的数据长度
  int64_t data_length_;

  // 请求返回状态
  ResourceLoaderResponseCode response_code_;
};
NAMESPACE_END