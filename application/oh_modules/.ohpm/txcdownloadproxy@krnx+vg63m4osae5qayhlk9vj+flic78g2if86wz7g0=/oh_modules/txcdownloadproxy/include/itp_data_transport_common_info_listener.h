/**
 * 通用信息回调，为了方便跨进程使用，后续增加回调不用改动多个接口，使用不同消息类型区分回调信息
 *
 * @date 2023-05-05
 */

#pragma once
#include "itp_data_transport_message_info.h"

NAMESPACE_BEGIN(tpdlproxy)

class ITPDataTransportCommonInfoListener {
 public:
  /**
   * 通用回调
   *
   * @param common_info_type {@link TPCommonInfoType} 通用类型
   * @param message_info {@link TPCommonInfoCallbackMessage} 通用消息
   */
  virtual void OnCommonInfoUpdate(int32_t common_info_type,
                                  ITPDataTransportMessageInfo* message_info) = 0;
};

NAMESPACE_END