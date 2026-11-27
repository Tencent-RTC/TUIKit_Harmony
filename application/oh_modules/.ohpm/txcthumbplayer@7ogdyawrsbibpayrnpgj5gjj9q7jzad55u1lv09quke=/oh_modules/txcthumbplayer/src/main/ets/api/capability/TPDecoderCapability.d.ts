/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { TPAudioCodecType } from '../common/TPAudioCodecType';
import { TPAudioDecoderType } from '../common/TPAudioDecoderType';
import { TPVideoCodecType } from '../common/TPVideoCodecType';
import { TPVideoDecoderType } from '../common/TPVideoDecoderType';
import { TPAudioCapabilityQueryParams } from './TPAudioCapabilityQueryParams';
import { TPVideoDecoderCapabilityRange } from './TPVideoDecoderCapabilityRange';

/**
 * 用于获取和管理解码能力的对象。使用该类前需要先调用TPMgr.init()接口进行初始化，初始化完成后才可调用。
 *
 * @author harleyxwang
 * @date 2024/03/05
 */

/**
 * 解码能力支持情况，目前仅有不支持和支持两个，后续可扩展
 */
export const enum TPDecoderCap {
  /**
   * 不支持
   */
  TP_DECODER_CAP_NOT_SUPPORT = 0,
  /**
   * 支持
   */
  TP_DECODER_CAP_SUPPORT = 1,
}

/**
 * @brief 同文件头描述
 */
export class TPDecoderCapability {
  /**
   * 获取视频解码能力支持情况，判断该编码格式在该宽、高及帧率下是否支持
   * @param codecType 编码格式，参考{@link TPVideoCodecType}
   * @param width 视频宽
   * @param height 视频高
   * @param frameRate 帧率
   * @return 返回视频解码能力支持情况，返回值见{@link TPDecoderCap}
   */
  static getVideoDecoderCapability(codecType: TPVideoCodecType, width: number, height: number, frameRate: number): TPDecoderCap;

  /**
   * 获取视频解码能力支持情况，判断该编码格式在该解码器类型、宽、高及帧率下是否支持
   * @param codecType 编码格式，参考{@link TPVideoCodecType}
   * @param decoderType 解码器类型
   * @param width 视频宽
   * @param height 视频高
   * @param frameRate 帧率
   * @return 返回视频解码能力支持情况，返回值见{@link TPDecoderCap}
   */
  static getVideoDecoderCapability(codecType: TPVideoCodecType, decoderType: TPVideoDecoderType, width: number,
                                   height: number, frameRate: number): TPDecoderCap;

  /**
   * 获取音频解码能力支持情况，判断该编码格式是否支持
   * @param codecType 编码格式，参考{@link TPAudioCodecType}
   * @return 返回视频解码能力支持情况，返回值见{@link TPDecoderCap}
   */
  static getAudioDecoderCapability(codecType: TPAudioCodecType): TPDecoderCap;

  /**
   * 获取音频解码能力支持情况，判断该编码格式在该解码器类型下是否支持
   * @param codecType 编码格式，参考{@link TPAudioCodecType}
   * @param decoderType 解码器类型
   * @return 返回视频解码能力支持情况，返回值见{@link TPDecoderCap}
   */
  static getAudioDecoderCapability(codecType: TPAudioCodecType, decoderType: TPAudioDecoderType): TPDecoderCap;

  /**
   * 获取音频解码能力支持情况，判断该编码格式在相关查询参数下该解码器类型下是否支持
   *
   * @param queryParams 查询参数
   * @return 返回视频解码能力支持情况，返回值见{@link TPDecoderCap}
   */
  static getAudioDecoderCapability(queryParams: TPAudioCapabilityQueryParams): TPDecoderCap;

  /**
   * 添加定制化的视频硬解码能力支持情况，描述该编码格式在OHAVCodec硬解能力支持情况，一般可用于业务方控制codec能力黑白名单
   * @param codecType 编码格式，参考{@link TPVideoCodecType}
   * @param decoderCap 自定义的解码能力，参考{@link TPDecoderCap}
   */
  static addCustomizedVideoOHAVCodecCapability(codecType: TPVideoCodecType, decoderCap: TPDecoderCap): void;

  /**
   * 添加定制化的视频硬解码能力支持情况，描述该编码格式在OHAVCodec硬解能力支持情况，一般可用于业务方控制codec能力黑白名单
   * @param codecType 编码格式，参考{@link TPVideoCodecType}
   * @param capabilityRange 视频解码性能区间，指定codec的解码能力区间
   * @param decoderCap 自定义的解码能力，参考{@link TPDecoderCap}
   */
  static addCustomizedVideoOHAVCodecCapability(codecType: TPVideoCodecType,
                                               capabilityRange: TPVideoDecoderCapabilityRange, decoderCap: TPDecoderCap): void;

  /**
   * 添加定制化的音频硬解码能力，描述该编码格式在OHAVCodec硬解能力支持情况，一般可用于业务方控制codec能力黑白名单
   * @param codecType 编码格式，参考{@link TPAudioCodecType}
   * @param decoderCap 自定义的解码能力，参考{@link TPDecoderCap}
   */
  static addCustomizedAudioOHAVCodecCapability(codecType: TPAudioCodecType, decoderCap: TPDecoderCap): void;
}
