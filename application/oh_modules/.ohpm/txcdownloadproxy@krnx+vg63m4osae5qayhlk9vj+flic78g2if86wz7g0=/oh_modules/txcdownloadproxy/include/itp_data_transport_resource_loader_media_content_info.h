#pragma once

#include "tp_data_transport_enum.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportResourceLoaderMediaContentInfo {
 public:
  virtual const char* GetContentType() = 0;
  virtual int64_t GetContentLength() = 0;
  virtual ResourceLoaderResponseCode GetResponseCode() = 0;

  // 设置读取的数据格式信息，内部进行拷贝赋值
  virtual void Init(const char* content_type, int64_t content_length,
                    ResourceLoaderResponseCode response_code) = 0;

  // 销毁复制的数据类型信息，释放内存
  virtual void Destroy() = 0;

  // 深拷贝一个副本
  virtual ITPDataTransportResourceLoaderMediaContentInfo* Clone() = 0;

 private:
  // 数据格式 Init赋值，Destroy释放
  char* content_type_;

  // 数据总长度
  int64_t content_length_;

  // 请求返回状态
  ResourceLoaderResponseCode response_code_;
};
NAMESPACE_END