/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */
import { TPAudioCodecType } from "../common/TPAudioCodecType";
import { TPAudioDecoderType } from "../common/TPAudioDecoderType";
import { TPChannelLayout } from  "../common/TPChannelLayout";

/**
 * 音频能力查询参数
 * hoaOrder不为0时，参数仅HOA阶数，采样率有效。
 * hoaOrder为0时，参数仅声道布局，采样率，对象数有效。若无对象可不用设置。
 *
 * @author harleyxwang
 * @date 2024/03/06
 */
export class TPAudioCapabilityQueryParams {
  /**
   * 音频codec类型 {@link TPAudioCodecType}
   */
  codecType?: TPAudioCodecType;

  /**
   * 音频解码器类型 {@link TPAudioDecoderType}
   */
  decoderType?: TPAudioDecoderType;

  /**
   * 音频的channelLayout {@link TPChannelLayout}
   */
  channelLayout?: TPChannelLayout;

  /**
   * 音频的采样率 例如: 48KHz, 44.1KHz etc.
   */
  sampleRate?: number;

  /**
   * 对象的数量. 如果没有对象可不填。
   */
  objectCount?: number;

  /**
   * HOA阶数。若是HOA，可指定HOA阶数
   */
  hoaOrder?: number;
}
