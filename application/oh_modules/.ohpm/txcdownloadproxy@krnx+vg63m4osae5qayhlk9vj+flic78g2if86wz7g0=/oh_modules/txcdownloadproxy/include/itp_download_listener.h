#pragma once
namespace tpdlproxy {

class ITPDownloadListener {
 public:
  /**
   * quic质量上报
   *
   * @param  report_info 上报信息
   * @return
   **/
  virtual void OnQuicQualityReportUpdate(const wchar_t* report_info) = 0;
};

}  // namespace tpdlproxy