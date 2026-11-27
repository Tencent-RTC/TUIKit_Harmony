/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPAudioStreamUsage } from "./TPAudioStreamUsage";

/**
 * TPAudioRenderConfig 鸿蒙音频渲染器外部可选配置，当前支持设置播放场景
 * 通过player->AddOptionalParam设置，key:OPTIONAL_ID_BEFORE_OBJECT_AUDIO_RENDER_CONFIG
 *
 * @author fantsyzhang
 * @date 2024/08/22
 */
export class TPAudioRenderConfig {
  /**
   * 播放场景，具体参考{@link TPAudioStreamUsage}
   */
  streamUsage: TPAudioStreamUsage
}
