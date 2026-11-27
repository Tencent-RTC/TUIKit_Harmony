/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { TPDrmType } from '../common/TPDrmType';
import { TPDrmCapAttribute } from './TPDrmCapAttribute';

/**
 *  用于获取和管理drm能力的对象。使用该类前需要先调用TPMgr.init()接口进行初始化，初始化完成后才可调用。
 *
 * @author harleyxwang
 * @date 2024/03/11
 */

/**
 * drm能力支持情况，目前仅有不支持和支持两个，后续可扩展
 */
export const enum TPDrmCap {
  /**
   * 不支持
   */
  NOT_SUPPORT = 0,
  /**
   * 支持
   */
  SUPPORT = 1,
}

/**
 * @brief 同文件头描述
 */
export class TPDrmCapability {
  /**
   * 获取某个指定的drm能力支持情况
   * @param drmType drm类型
   * @return 返回drm能力支持情况，返回值见{@link TPDrmCap}
   */
  static getDrmCapability(drmType: TPDrmType): TPDrmCap;

  /**
   * 获取设备的drm能力属性, 如果该设备不支持某个drm类型，则返回null
   * @param drmType drm类型
   * @return 如果该设备支持该drm类型，则返回相应的drm能力属性，否则返回null
   */
  static getDrmCapAttribute(drmType: TPDrmType): TPDrmCapAttribute | null;

  /**
   * 获取设备的drm能力属性列表，如果该设备不支持某个drm类型，则不添加到drm能力属性列表中
   * @return 返回设备的drm能力属性列表
   */
  static getDrmCapAttributes(): TPDrmCapAttribute[];

  /**
   * 添加定制化的MediaDrm能力支持情况，一般可用于业务方控制drm能力黑白名单
   * @param drmType drm类型，主要是针对widevine和ChinaDrm等需要使用MediaDrm来判断能力的drm类型，其他drm类型不支持添加定制化能力
   * @param drmCap 定制化的drm能力支持情况
   * @return 如果添加成功，则返回true，否则返回false
   */
  static addCustomizedMediaDrmCapability(drmType: TPDrmType, drmCap: TPDrmCap): boolean;
}
