#pragma once
#include "utils/tp_data_transport_common.h"

NAMESPACE_BEGIN(tpdlproxy)

enum LogLevel {
  kLogLevelDebug = 3,
  kLogLevelInfo = 4,
  kLogLevelWarn = 5,
  kLogLevelError = 6,
};

class ITPDataTransportLogListener {
 public:
#ifdef WIN32
  // wchar_t 类型 对应宽字符类型日志输出，预留接口，底层暂未实现
  virtual void LogInfoW(const wchar_t* file_name, int32_t line, const wchar_t* tag,
                        const wchar_t* msg) = 0;
  virtual void LogDebugW(const wchar_t* file_name, int32_t line, const wchar_t* tag,
                         const wchar_t* msg) = 0;
  virtual void LogWarnW(const wchar_t* file_name, int32_t line, const wchar_t* tag,
                        const wchar_t* msg) = 0;
  virtual void LogErrorW(const wchar_t* file_name, int32_t line, const wchar_t* tag,
                         const wchar_t* msg) = 0;
#endif

  // char 类型
  virtual void LogInfoA(const char* file_name, int32_t line, const char* tag, const char* msg) = 0;
  virtual void LogDebugA(const char* file_name, int32_t line, const char* tag, const char* msg) = 0;
  virtual void LogWarnA(const char* file_name, int32_t line, const char* tag, const char* msg) = 0;
  virtual void LogErrorA(const char* file_name, int32_t line, const char* tag, const char* msg) = 0;
};

NAMESPACE_END
