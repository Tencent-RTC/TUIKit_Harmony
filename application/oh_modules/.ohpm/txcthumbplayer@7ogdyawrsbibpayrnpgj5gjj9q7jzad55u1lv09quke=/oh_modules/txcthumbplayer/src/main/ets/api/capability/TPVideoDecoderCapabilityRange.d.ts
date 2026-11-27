/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 描述影响视频解码性能的关键要素，需要针对某个Codec的MediaCodec解码能力进行能力自定义时使用，所以是一个区间值
 *
 * @author harleyxwang
 * @date 2024/03/06
 */
export class TPVideoDecoderCapabilityRange {
  /**
   * codec支持的width的上限，如果不设置，则默认为最大值
   */
  upperWidth?: number;

  /**
   * codec支持的height的上限，如果不设置，则默认为最大值
   */
  upperHeight?: number;

  /**
   * codec支持的帧率的上限，如果不设置，则默认为最大值
   */
  upperFrameRate?: number;

  /**
   * codec支持的width的下限，如果不设置，则默认为0
   */
  lowerWidth?: number;

  /**
   * codec支持的height的下限，如果不设置，则默认为0
   */
  lowerHeight?: number;

  /**
   * codec支持的帧率的下限，如果不设置，则默认为0
   */
  lowerFrameRate?: number;
}
