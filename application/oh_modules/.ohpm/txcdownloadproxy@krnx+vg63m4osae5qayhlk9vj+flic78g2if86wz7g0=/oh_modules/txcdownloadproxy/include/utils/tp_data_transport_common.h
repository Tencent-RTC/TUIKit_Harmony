#pragma once

#include <stdint.h>

#ifdef WIN32
#  include <windows.h>

#  define TPDATATRANSPORT_EXPORTS

#  ifdef TPDATATRANSPORT_EXPORTS
#    define TPDATATRANSPORT_API extern "C" __declspec(dllexport)
#  else
#    define TPDATATRANSPORT_API extern "C" __declspec(dllimport)
#  endif

#else
#  define __stdcall
#  define TPDATATRANSPORT_API __attribute__((visibility("default")))
#endif

#define NAMESPACE_BEGIN(name) namespace name {
#define NAMESPACE_END }

NAMESPACE_BEGIN(tpdlproxy)

#define DLPROXY_HRESULT int32_t
#define BOOL int32_t
#define FALSE 0
#define TRUE 1

NAMESPACE_END