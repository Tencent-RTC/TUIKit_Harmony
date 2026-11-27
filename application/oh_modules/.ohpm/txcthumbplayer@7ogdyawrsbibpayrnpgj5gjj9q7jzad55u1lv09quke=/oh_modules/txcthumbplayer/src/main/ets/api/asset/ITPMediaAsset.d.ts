/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * 资源接口，用于描述资源。该接口是资源类的顶层接口，所有类型的asset都继承于该接口
 * 该接口中定义的参数key，用于设置扩展参数。参考{@link #setParam(String, String)}和
 * {@link #setObjectParam(String, ITPMediaAssetObjectParam)}
 * key的命名规则：TP_ASSET_PARAM_KEY_ + 类型 + 名字，
 * 其中"类型"表示key对应value的类型，可以为bool、int、long、float、String，不过所有类型都是通过string传入，内部按照key指定的类型来取值。
 * 如果类型为"OBJECT"，则表示该key的value是一个对象，该对象必须继承于@{@link ITPMediaAssetObjectParam}
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

import { ITPMediaAssetObjectParam } from './ITPMediaAssetObjectParam'
import { ITPResourceLoader } from '../resourceloader/ITPResourceLoader'

export const enum TPAssetParamKeyObjectPreferredKey {
  /**
   * 用于avs分离，指定优先选择哪一路视频流，该参数的value是一个{@link ITPMediaAssetParamMap}的实例对象
   */
  TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_VIDEO = "tp_asset_param_key_object_preferred_video",
  /**
   * 用于avs分离，指定优先选择哪一路音频流，该参数的value是一个{@link ITPMediaAssetParamMap}的实例对象
   */
  TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_AUDIO = "tp_asset_param_key_object_preferred_audio",
  /**
   * 用于avs分离，指定优先选择哪一路字幕，该参数的value是一个{@link ITPMediaAssetParamMap}的实例对象
   */
  TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_SUBTITLE = "tp_asset_param_key_object_preferred_subtitle",
  /**
   * 用于hls多program情况下，指定优先选择哪一路program，该参数的value是一个{@link ITPMediaAssetParamMap}的实例对象
   */
  TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_PROGRAM = "tp_asset_param_key_object_preferred_program",
}

export const enum TPAssetType {
  /**
   * 未知Asset类型
   */
  UNKNOWN = 0,

  /**
   * 单个url播放资源类型
   */
  URL = 3,

  /**
   * 直播RTC播放资源类型
   */
  RTC = 4,

  /**
   * 加密播放资源类型
   */
  DRM = 5,

  /**
   * 组合型播放资源类型
   */
  MULTI_ASSET = 6,

  /**
   * 模拟直播资源类型
   */
  SIMULATED_LIVE = 8,

  /**
   * 本地文件描述符的资源类型
   */
  FD = 9,
}

export interface ITPMediaAsset {
  /**
   * 获取当前asset类型
   * @return TPAssetType
   */
  getAssetType(): TPAssetType;

  /**
   * 当前asset资源是否有效. 一些必要的参数不能为空, 例如TPUrlMediaAsset中的url不能为空, 为空则无效
   * @return true:有效 false: 无效
   */
  isValid(): boolean;

  /**
   * 设置扩展参数，基本类型——number、bool以及字符串都通过该方法设置
   * 公共的key定义在ITPMediaAsset中，不同asset特有的param的key定义在各自的asset中
   * 给传输组件传递的param请参考定义{@link com.tencent.thumbplayer.core.datatransport.aidl.TPDataTransportTaskParam}的说明
   * @param key 健值，如果key已经存在，则覆盖原有值
   * @param value 该param的值
   */
  setParam(key: string, value: string): void;

  /**
   * 设置对象参数，value的类型必须继承于ITPMediaAssetObjectParam
   * @param key 健值，如果key已经存在，则覆盖原有值
   * @param value 该param的值
   */
  setObjectParam(key: string, value: ITPMediaAssetObjectParam): void;

  /**
   * 设置外部实现的资源加载器
   * @param value 资源加载器
   */
  setResourceLoader(value: ITPResourceLoader): void;
}
