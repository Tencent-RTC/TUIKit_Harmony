#pragma once

#include "itp_data_transport_factory.h"

/**
 * 创建下载代理工厂，单例模式，用于生成下载代理实例
 *
 * @return 下载代理工厂单例地址
 **/
TPDATATRANSPORT_API tpdlproxy::ITPDataTransportFactory* __stdcall GetTPDataTransportFactory();
