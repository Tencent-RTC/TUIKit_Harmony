#pragma once

#include <stdint.h>

#define TPDATATRANSPORT_C_API __attribute__((visibility("default")))

#ifdef __cplusplus
extern "C" {
#endif

TPDATATRANSPORT_C_API int32_t TPDataTransport_Init(void* context);
TPDATATRANSPORT_C_API int32_t TPDataTransport_CreateTask(int32_t service_type, const char* key_id,
                                                         int32_t task_type, int32_t clip_count);
TPDATATRANSPORT_C_API int32_t TPDataTransport_SetTaskInfo(int32_t task_id, int32_t clip_no,
                                                          const char* clip_key_id,
                                                          int32_t task_type, const char* url,
                                                          const char* save_path,
                                                          const char* extra_info);
TPDATATRANSPORT_C_API int32_t TPDataTransport_StartTask(int32_t task_id);
TPDATATRANSPORT_C_API int32_t TPDataTransport_StopTask(int32_t task_id);

TPDATATRANSPORT_C_API int32_t TPDataTransport_UpdateOfflinePath(int32_t biz_id,
                                                                const char* disk_path);
TPDATATRANSPORT_C_API int32_t TPDataTransport_RemoveCache(int32_t biz_id, const char* key_id);

TPDATATRANSPORT_C_API void TPDataTransport_SetGlobalOptionalConfigParam(const char* key,
                                                                        const char* value);

// 日志回调
typedef void (*TPDataTransportLogCallback)(int level, const char* fileName, int line,
                                           const char* tag, const char* message);
TPDATATRANSPORT_C_API void TPDataTransport_SetLogCallback(TPDataTransportLogCallback callback);

// 消息回调
typedef int32_t (*TPDataTransportMessageCallback)(int32_t message_id, int32_t task_id, void* param1,
                                                  void* param2, void* param3, void* param4,
                                                  void* param5);
TPDATATRANSPORT_C_API void TPDataTransport_SetMessageCallback(
    TPDataTransportMessageCallback callback);

typedef char* (*TPDataTransportGetOfflineRecordContentCallback)(const char* vid,
                                                                const char* format);
TPDATATRANSPORT_C_API void TPDataTransport_SetGetOfflineRecordContent(
    TPDataTransportGetOfflineRecordContentCallback callback);

typedef int32_t (*TPDataTransportGetOfflineRecordDurationCallback)(const char* vid,
                                                                   const char* format);
TPDATATRANSPORT_C_API void TPDataTransport_SetGetOfflineRecordDuration(
    TPDataTransportGetOfflineRecordDurationCallback callback);

#ifdef __cplusplus
}
#endif
