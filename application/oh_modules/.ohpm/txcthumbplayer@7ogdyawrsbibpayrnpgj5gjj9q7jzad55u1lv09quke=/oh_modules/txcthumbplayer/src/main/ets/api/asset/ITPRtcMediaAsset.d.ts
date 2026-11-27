/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPUrlMediaAsset } from './ITPUrlMediaAsset';

/**
 * Rtc直播资源接口
 *
 * @author harleyxwang
 * @date 2024/7/29
 */

/**
 * SDP(Session Description Protocol)交互模式的定义
 */
export const enum TPSdpExchangeMode {
  /**
   * 内核提供的默认模式，使用标准的sdp格式
   */
  NORMAL = 0,
  /**
   * 内核提供的mini sdp模式，会先将标准sdp压缩，在使用udp交互
   * 可以加速起播，但需要sdp信令服务器支持
   */
  MINI = 1,
  /**
   * 由业务自己实现sdp交互，内核会回调offer SDP，业务做完SDP交互后把结果通过callback传回给内核
   */
  CUSTOM = 2,
}

/**
 * 远端SDP信息，用于TPSdpExchangeModeCustom
 */
export class TPRemoteSdpInfo {
  /**
   * 本次SDP交互是否成功
   */
  success: boolean;
  /**
   * 当前会话的id
   */
  sessionID: number;
  /**
   * 做完SDP交互之后得到的对端SDP字符串
   */
  remoteSdp: string;
}

/**
 * SDP交互callback，用于TPSdpExchangeModeCustom
 */
export interface ITPRtcSdpExchangeCallback {
  /**
   * rtc播放SDP信息回调
   * @param localSdp 本地通过 webrtc-core CreateOffer api拿到的会话描述字符串
   * @param sessionID 当前当话ID, 在webrtc demuxer内部维护
   * @return 做完媒体协商的结果
   */
  onSdpExchange(localSdp: string, sessionID: number): TPRemoteSdpInfo;
}

export interface ITPRtcMediaAsset extends ITPUrlMediaAsset {
  /**
   * 设置SDP交互模式
   * @param exchangeMode SDP交互模式，参考TPSdpExchangeMode
   */
  setSdpExchangeMode(exchangeMode: TPSdpExchangeMode): void;

  /**
   * 设置RTC直播的信令服务器地址，SDP交互模式为TPSdpExchangeMode.NORMAL和TPSdpExchangeMode.MINI时需要设置
   * @param sdpServerUrl RTC直播的信令服务器地址
   */
  setSdpServerUrl(sdpServerUrl: string): void;

  /**
   * 设置SDP交换callback，在SDP交互模式为TPSdpExchangeMode.CUSTOM时需要设置
   * @param callback ITPRtcSdpExchangeCallback
   */
  setSdpExchangeCallback(callback: ITPRtcSdpExchangeCallback): void;
}
