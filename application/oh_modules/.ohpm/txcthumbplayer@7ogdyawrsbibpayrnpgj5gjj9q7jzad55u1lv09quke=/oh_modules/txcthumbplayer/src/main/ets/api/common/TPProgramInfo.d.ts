/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 *  描述一路节目（Program）的信息。一路节目包含若干相关的媒体轨道，如音频，视频，字幕等。
 *  如果HLS多码率的流，每一种码率包含跟该码率对应的音频，视频，字幕，就可称为一路节目。
 *
 * @author harleyxwang
 * @date 2024/03/12
 */
export interface TPProgramInfo {
  /**
   * 当前节目是否被激活（在播放)
   */
  readonly isActivated: boolean;

  /**
   * 当前节目Id
   */
  readonly programId: number;

  /**
   * 当前节目数据的带宽，在父类m3u8中用于描述子类m3u8的bitrate，单位为bps，例如：7680000
   */
  readonly bandwidth: number;

  /**
   * 当前节目Resolution，在父类m3u8中用于描述子类m3u8的宽高信息，例如："1280x720"
   */
  readonly resolution: string;

  /**
   * 当前节目的url，在父类m3u8中用于描述子类m3u8的url信息
   */
  readonly url: string;
}
