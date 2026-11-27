#pragma once
/**
 * 腾讯视频离线播放 vinfo 桥接接口，离线下载在另一个模块内，但是播放依赖 vinfo 需要通过接口桥接一层
 *
 * @author abnerwang
 * @date 2022-12-28
 */
#include "utils/tp_data_transport_common.h"

class ITPDataTransportOfflineVinfoAdapter {
 public:
  /**
   * 检查视频状态是否是离线视频
   *
   * @param vid 视频 vid
   * @param format 视频清晰度
   * @return 如果有离线视频记录，返回离线 vinfo，否则返回空
   */
  virtual const char* CheckVideoStatus(const char* vid, const char* format) = 0;

  /**
   * 获取离线视频时长，离线下载广告需要用这个接口来决定播放的广告时长
   *
   * @param vid 视频 vid
   * @param format 视频清晰度
   * @return 找到对应离线视频记录返回对应视频时长，否则返回 0
   */
  virtual int32_t GetRecordDuration(const char* vid, const char* format) = 0;
};
