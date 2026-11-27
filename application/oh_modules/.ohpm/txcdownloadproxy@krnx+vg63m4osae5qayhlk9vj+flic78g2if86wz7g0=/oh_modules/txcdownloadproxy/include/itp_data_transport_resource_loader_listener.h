#pragma once

#include "itp_data_transport_resource_loader_data.h"
#include "itp_data_transport_resource_loader_media_content_info.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportResourceLoaderListener {
 public:
  // 资源加载器打开一个资源传输通道，启动一个资源传输任务时首先调用这个方法；
  virtual int32_t Open(int32_t request_id, const char* url) = 0;

  // 资源加载器读取媒体资源信息，在Open后和ReadData前被调用
  virtual void ReadMediaContentInfo(
      int32_t request_id, const char* url,
      ITPDataTransportResourceLoaderMediaContentInfo& content_info) = 0;

  // 资源加载器seek资源数据到指定位置，在ReadMediaContentInfo后和Close前被调用
  virtual int32_t SeekData(int32_t request_id, const char* url, int64_t position) = 0;

  // 资源加载器读取媒体资源数据，在ReadMediaContentInfo后和Close前被调用
  virtual void ReadData(int32_t request_id, const char* url, int64_t length,
                        ITPDataTransportResourceLoaderData& resource_loader_data) = 0;

  // 资源加载器关闭一个资源传输通道，在一个资源传输完成后被调用
  virtual void Close(int32_t request_id, const char* url) = 0;
};

NAMESPACE_END
