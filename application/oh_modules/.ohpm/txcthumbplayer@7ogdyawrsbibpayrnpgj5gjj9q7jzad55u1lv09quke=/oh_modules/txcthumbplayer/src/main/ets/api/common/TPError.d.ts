/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { TPErrorType } from "./TPErrorType";

/**
 * 错误结构定义
 *
 * @author karlyczhang
 * @date 2024/03/05
 */
export interface TPError {
  /**
   * 错误类型，参考{@link TPErrorType}
   */
  readonly errorType: TPErrorType;

  /**
   * 错误码
   */
  readonly errorCode: number;

  /**
   * 出错时的播放位置
   */
  readonly currentPosMs: number;

  /**
   * 扩展参数，方便后续扩展，暂未用到
   */
  readonly extraParams?: Map<string, object>
}
