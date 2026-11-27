/**
 * Copyright (c) 2021 Tencent. All rights reserved.
 * Module:   音视频设备管理模块
 * Function: 用于管理摄像头、麦克风和扬声器等音视频相关的硬件设备
 */
/**
 * 音频路由（即声音的播放模式）。
 *
 * 音频路由，即声音是从手机的扬声器还是从听筒中播放出来，因此该接口仅适用于手机等移动端设备。
 * 手机有两个扬声器：一个是位于手机顶部的听筒，一个是位于手机底部的立体声扬声器。
 * - 设置音频路由为听筒时，声音比较小，只有将耳朵凑近才能听清楚，隐私性较好，适合用于接听电话。
 * - 设置音频路由为扬声器时，声音比较大，不用将手机贴脸也能听清，因此可以实现“免提”的功能。
 */
export declare enum TXAudioRoute {
    TXAudioRouteSpeakerphone = 0,
    TXAudioRouteEarpiece = 1
}
export interface TXDeviceManager {
    /**
     * 1.1 判断当前是否为前置摄像头（仅适用于移动端）。
     */
    isFrontCamera(): boolean;
    /**
     * 1.2 切换前置或后置摄像头（仅适用于移动端）。
     */
    switchCamera(frontCamera: boolean): number;
    /**
     * 1.3 获取摄像头的最大缩放倍数（仅适用于移动端）。
     */
    getCameraZoomMaxRatio(): number;
    /**
     * 1.4 设置摄像头的缩放倍数（仅适用于移动端）。
     *
     * @param zoomRatio 取值范围 [1, 5]，取值为1表示最远视角（正常镜头），取值为5表示最近视角（放大镜头）。最大值推荐为5，若超过5，视频数据会变得模糊不清。
     */
    setCameraZoomRatio(zoomRatio: number): number;
    /**
     * 1.8 开启/关闭闪光灯，也就是手电筒模式（仅适用于移动端）。
     */
    enableCameraTorch(enabled: boolean): number;
    /**
     * 1.9 设置音频路由（仅适用于移动端）。
     *
     * 手机有两个音频播放设备：一个是位于手机顶部的听筒，一个是位于手机底部的立体声扬声器。
     * 设置音频路由为听筒时，声音比较小，只有将耳朵凑近才能听清楚，隐私性较好，适合用于接听电话。
     * 设置音频路由为扬声器时，声音比较大，不用将手机贴脸也能听清，因此可以实现“免提”的功能。
     */
    setAudioRoute(route: TXAudioRoute): number;
}
