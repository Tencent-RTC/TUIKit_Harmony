/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPMediaAssetObjectParam } from './ITPMediaAssetObjectParam';

/**
 * 有序key-value对参数，通过{@link ITPMediaAsset#setObjectParam(String, ITPMediaAssetObjectParam)}设置。
 * 调用方通过add方法一个一个的添加，内部按添加的顺序保存
 * 下面定义的参数用于在hls avs 分离或dash中预选则某一路视频、音频或字幕。
 * key的命名规则：TP_ASSET_PARAM_KEY_ + 类型 + 名字，
 * 其中"类型"表示key对应value的类型，可以为int、long、float、String，不过所有类型都是通过string传入，内部按照key指定的类型来取值。
 *
 * @author harleyxwang
 * @date 2024/2/22
 */

/**
 * 以下这些参数用于hls情况下通过{@link ITPMediaAsset#setObjectParam(String, ITPMediaAssetObjectParam)}
 * 设置{@link ITPMediaAsset#TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_VIDEO}
 *
 * 通过指定这些参数中的一个或多个，来指定选择哪一路视频流。value的取值须参考hls master playlist中
 * 相应字段的取值方式和范围。内部按照参数传入的顺序来匹配，参数越靠前，优先级越高。内部将这些传入的参数跟hls master playlist中
 * 各个stream的参数进行比较，从而选出最匹配的一条流。如果不能匹配到任何流，则默认选择playlist中第一条。
 * 例如：传入FRAME-RATE=30，BANDWIDTH=20000000，会首先匹配帧率，然后再从匹配的结果中匹配带宽。
 * 注意dash和hls的匹配规则稍有不同，hls会顺序匹配各个传入参数，而dash一旦匹配到某个参数，就不再匹配后面的参数。请看下面dash部分的注释。
 *
 * 单个参数比较时，不同的参数匹配规则不同，目前匹配规则有三种：
 * 精准匹配：必须完全相等，比如轨道名字
 * 向下匹配：找到对应参数等于传入参数、或者比传入参数小且最接近的那一路流，比如分辨率
 * 最近匹配：找到对应参数和传入参数最接近的那一路流，比如帧率
 */

export const enum TPAssetParamKey {
  /**
   * hls video track framerate， 对应HLS master playlist内video的FRAME-RATE字段
   * 匹配规则：最近匹配
   */
  TP_ASSET_PARAM_KEY_FLOAT_HLS_TRACK_FRAMERATE = "hls_track_framerate",
  /**
   * hls video track codecs，对应HLS master playlist内video的CODECS字段，比如：avc1.4d401f,mp4a.40.2
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_STRING_HLS_TRACK_CODECS = "hls_track_codecs",
  /**
   * hls video track bandwidth，对应HLS master playlist内video的BANDWIDTH字段
   * 匹配规则：向下匹配
   */
  TP_ASSET_PARAM_KEY_INT_HLS_TRACK_BANDWIDTH = "hls_track_bandwidth",
  /**
   * hls video track resolution，对应HLS master playlist内video的RESOLUTION字段，value以"width x height"的格式传入，比如：1920x1080
   * 匹配规则：向下匹配
   */
  TP_ASSET_PARAM_KEY_STRING_HLS_TRACK_RESOLUTION = "hls_track_resolution",

  /**
   * 以下这些参数用于hls情况下通过{@link ITPMediaAsset#setObjectParam(String, ITPMediaAssetObjectParam)}设置
   * {@link ITPMediaAsset#TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_AUDIO} 或
   * {@link ITPMediaAsset#TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_SUBTITLE}
   * 通过指定这些参数中的一个或多个，来指定选择哪一路音频/字幕。value的类型都为String，value的取值须参考hsl master playlist中
   * 相应字段的取值方式和范围。匹配规则见上述注释。
   */

  /**
   * hls audio / subtitle track group id，对应HLS master playlist内audio/subtitle的GROUP-ID字段
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_STRING_HLS_TRACK_GROUPID = "hls_track_groupid",
  /**
   * hls audio / subtitle track name，对应HLS master playlist内audio/subtitle的NAME字段
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_STRING_HLS_TRACK_NAME = "hls_track_name",
  /**
   * hls audio / subtitle track language，对应HLS master playlist内audio/subtitle的LANGUAGE字段
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_STRING_HLS_TRACK_LANGUAGE = "hls_track_language",
  /**
   * 设置Hls多Program的默认起播通道，为Program列表的下标
   * 配置有效值为>=-1的整形数转换的string. 缺省为-1播放内核理解为应使用优先级更低的信息进行配置，bandwidth、luma samples
   * 0/1/2，表示使用对应下标的Program Info进行起播，此时不会Open其他的Program对应的stream
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_INT_HLS_START_PROGRAM_INDEX = "hls_start_program_index",
  /**
   * 设置Hls多Program的默认起播通道，根据设定的Preferred Bandwidth选最优的Program进行起播，单位是bps hls program bandwidth，对应HLS master
   * playlist内program的BANDWIDTH字段 配置有效值为>=-1的整形数转换的string. 缺省为-1播放内核理解为应使用优先级更低的信息进行配置，luma samples
   * 匹配规则：向下匹配
   * 如：bandwidth1 : 2462348 , bandwidth2 : 1105139， 输入：2462348，匹配bandwidth1,  输入 2462348 -1 ， 匹配bandwidth2
   */
  TP_ASSET_PARAM_KEY_INT_HLS_PROGRAM_PREFERRED_BANDWIDTH = "hls_program_preferred_bandwidth",
  /**
   * 设置Hls多Program的默认起播通道，根据设定的Preferred Luma Samples选最优的Program进行起播
   * hls program luma samples，对应HLS master playlist内program的RESOLUTION字段的width和height的乘积结果
   * 配置有效值为>=-1的整形数转换的string. 缺省为-1播放内核理解为应使用优先级更低的信息进行配置
   * 匹配规则：向下匹配
   * 如：luma samples1 : 1920 * 1080 , luma samples2 : 1280 * 720
   * 输入：1920 * 1080，匹配luma samples1,  输入 1920 * 1080 -1 ， 匹配luma samples2
   */
  TP_ASSET_PARAM_KEY_INT_HLS_PROGRAM_PREFERRED_LUMA_SAMPLES = "hls_program_preferred_luma_samples",

  /**
   * 以下这些参数用于dash情况下通过{@link ITPMediaAsset#setObjectParam(String, ITPMediaAssetObjectParam)}设置
   * {@link ITPMediaAsset#TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_VIDEO} 或
   * {@link ITPMediaAsset#TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_AUDIO} 或
   * {@link ITPMediaAsset#TP_ASSET_PARAM_KEY_OBJECT_PREFERRED_SUBTITLE}
   *
   * 通过指定这些参数中的一个或多个，来指定选择哪一路视频/音频/字幕。value的取值须参考dash mpd(media presentation description)中
   * 这相应字段的取值方式和范围。内部按照参数传入的顺序来匹配，参数越靠前，优先级越高。内部将这些传入的参数跟dash mpd中
   * 各个stream的参数进行比较，从而选出最匹配的一条流。如果不能匹配到任何流，则默认选择playlist中第一条。
   * dash的匹配规则目前较简单，一旦命中，不再往后匹配，
   * 例如：预选择视频时，传入frameRate=30，bandwidth=20000000，首先匹配到帧率相近的一路流，后面的带宽不再匹配，
   * 例如：预选则音频时，传入lang=eng，bandwidth=96636，首先匹配lang，如果匹配到，则停止，否则继续匹配bandwidth
   *
   * 单个参数比较时，不同的参数匹配规则不同，目前匹配规则有三种：
   * 精准匹配：必须完全相等，比如轨道名字
   * 向下匹配：找到对应参数等于传入参数、或者比传入参数小且最接近的那一路流，比如分辨率
   * 最近匹配：找到对应参数和传入参数最接近的那一路流，比如帧率
   */

  /**
   * dash video track framerate，对应dash mpd内video的frameRate字段
   * 匹配规则：最近匹配
   */
  TP_ASSET_PARAM_KEY_FLOAT_DASH_TRACK_FRAMERATE = "dash_track_framerate",
  /**
   * dash video track bandwidth，对应dash mpd内video/audio的bandwidth字段
   * 匹配规则：向下匹配
   */
  TP_ASSET_PARAM_KEY_INT_DASH_TRACK_BANDWIDTH = "dash_track_bandwidth",
  /**
   * dash video track resolution 对应dash mpd内video的width字段和height字段，以"width x height"的格式传入，比如：1920x1080
   * 匹配规则：向下匹配
   */
  TP_ASSET_PARAM_KEY_STRING_DASH_TRACK_RESOLUTION = "dash_track_resolution",
  /**
   * dash video track luma samples，与resolution不同的是，此参数传入dash mpd内video的width和height的乘积结果
   * 匹配规则：向下匹配
   */
  TP_ASSET_PARAM_KEY_INT_DASH_TRACK_LUMA_SAMPLES = "dash_track_luma_samples",
  /**
   * dash audio/subtitle track language，对应dash mpd内audio/subtitle的lang字段
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_STRING_DASH_TRACK_LANGUAGE = "dash_track_language",
  /**
   * dash audio/subtitle track label，对应dash mpd内audio/subtitle的label字段
   * 匹配规则：精准匹配
   */
  TP_ASSET_PARAM_KEY_STRING_DASH_TRACK_LABEL = "dash_track_label",
}

export interface ITPMediaAssetParamMap extends ITPMediaAssetObjectParam {
  /**
   * 添加key-value. 内部按照添加的顺序存放键值对
   * @param key 要设置的参数的key
   * @param value 要设置的参数的value
   */
  add(key: string, value: string): void;

  /**
   * 获取按插入顺序排序的参数map
   * @return 返回所有已添加的key和其对应的value
   */
  getParamMap(): Map<string, string>;
}
