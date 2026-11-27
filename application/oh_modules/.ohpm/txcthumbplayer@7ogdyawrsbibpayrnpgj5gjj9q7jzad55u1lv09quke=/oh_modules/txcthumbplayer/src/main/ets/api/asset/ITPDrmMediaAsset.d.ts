/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAsset } from './ITPMediaAsset';
import { ITPUrlMediaAsset } from './ITPUrlMediaAsset';
import { TPDrmType } from '../common/TPDrmType';

/**
 * DRM asset接口，用于描述DRM资源
 * 下面定义的参数通过{@link ITPMediaAsset#setParam}来设置。
 * 参数key的格式请参考{@link ITPMediaAsset}注释说明
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

export interface ITPDrmMediaAsset extends ITPUrlMediaAsset {
  /**
   * 设置DRM的类型，参考{@link TPDrmType}。
   * @param drmType drm类型
   */
  setDrmType(drmType: TPDrmType): void;

  /**
   * 设置证书url，用于向provisioning服务器申请证书，允许设置空，内部会解析
   * @param certificateUrl 证书url
   */
  setCertificateUrl(certificateUrl: string): void;

  /**
   * 设置证书url，用于向provisioning服务器申请证书，允许设置空，内部会解析
   * 安卓端没有FairPlay，此证书url对应理解为provision url
   * @param certificateUrl 证书url
   * @param httpHeader 证书url的http header
   */
  setCertificateUrl(certificateUrl: string, httpHeader: Map<string, string>): void;

  /**
   * 设置license url，用于向license服务器申请播放授权许可，license中封装了加密媒体流的解密密钥和密钥使用规则
   * @param licenseUrl license url
   */
  setLicenseUrl(licenseUrl: string): void;

  /**
   * 设置license url，用于向license服务器申请播放授权许可，license中封装了加密媒体流的解密密钥和密钥使用规则
   * @param licenseUrl license url
   * @param httpHeader license url的http header
   */
  setLicenseUrl(licenseUrl: string, httpHeader: Map<string, string>): void;
}
