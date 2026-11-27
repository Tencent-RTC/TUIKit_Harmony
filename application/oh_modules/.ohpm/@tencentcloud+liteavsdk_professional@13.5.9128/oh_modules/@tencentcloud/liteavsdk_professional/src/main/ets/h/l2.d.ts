/**
 * Copyright (c) 2021 Tencent. All rights reserved.
 * Module:   V2TXLivePlayer @ TXLiteAVSDK
 * Function: 腾讯云直播播放器
 * <H2>功能
 * 腾讯云直播播放器。
 * 主要负责从指定的直播流地址拉取音视频数据，并进行解码和本地渲染播放。
 * <H2>介绍
 * 播放器包含如下能力：
 * - 支持 RTMP、HTTP-FLV、HLS、TRTC、WebRTC 协议。
 * - 屏幕截图，可以截取当前直播流的视频画面。
 * - 延时调节，可以设置播放器缓存自动调整的最小和最大时间。
 * - 自定义的视频数据处理，您可以根据项目需要处理直播流中的视频数据后，再进行渲染以及播放。
 */
import { Context } from '@ohos.abilityAccessCtrl';
import { V2TXLiveRotation, V2TXLiveFillMode, V2TXLiveLocalRecordingParams } from "./o2";
import { V2TXLivePlayerObserver } from "./m2";
/**
 * 利用 C 函数创建 V2TXLivePlayer 实例
 *
 * 你可以按照下列方式创建和销毁 V2TXLivePlayer Instance
 * <pre>
 * let v2TXLivePlayer = createV2TXLivePlayer(getContext());
 * releaseV2TXLivePlayer(v2TXLivePlayer);
 * </pre>
 */
export declare function createV2TXLivePlayer(context?: Context): V2TXLivePlayer;
/**
 * 析构 V2TXLivePlayer 对象
 */
export declare function releaseV2TXLivePlayer(d21: V2TXLivePlayer): void;
export interface V2TXLivePlayer {
    /**
     * 设置播放器回调
     *
     * 通过设置回调，可以监听 V2TXLivePlayer 播放器的一些回调事件，
     * 包括播放器状态、播放音量回调、音视频首帧回调、统计数据、警告和错误信息等。
     * @param observer 播放器的回调目标对象，更多信息请查看 {@link V2TXLivePlayerObserver}
     */
    setObserver(observer: V2TXLivePlayerObserver): void;
    /**
     * 设置播放器的视频渲染 View。 该控件负责显示视频内容
     *
     * @param view 播放器渲染 View。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK：成功。
     */
    setRenderView(view: string): number;
    /**
     * 设置播放器画面的旋转角度
     *
     * @param rotation 旋转角度 {@link V2TXLiveRotation}。
     *         - V2TXLiveRotation0【默认值】: 0度, 不旋转。
     *         - V2TXLiveRotation90:  顺时针旋转90度。
     *         - V2TXLiveRotation180: 顺时针旋转180度。
     *         - V2TXLiveRotation270: 顺时针旋转270度。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    setRenderRotation(rotation: V2TXLiveRotation): number;
    /**
     * 设置画面的填充模式
     *
     * @param mode 画面填充模式 {@link V2TXLiveFillMode}。
     *         - V2TXLiveFillModeFill 【默认值】: 图像铺满屏幕，不留黑边，如果图像宽高比不同于屏幕宽高比，部分画面内容会被裁剪掉。
     *         - V2TXLiveFillModeFit: 图像适应屏幕，保持画面完整，但如果图像宽高比不同于屏幕宽高比，会有黑边的存在。
     *         - V2TXLiveFillModeScaleFill: 图像拉伸铺满，因此长度和宽度可能不会按比例变化。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    setRenderFillMode(mode: V2TXLiveFillMode): number;
    /**
     * 设置播放器画面的镜像模式
     *
     * 开启镜像模式后，视频画面将左右翻转，您可以根据需要随时切换观看效果。
     * @param enable 是否开启播放端镜像模式。【默认值】：false。
     * @return 返回值 {@link V2TXLiveCode}
     *         - V2TXLIVE_OK: 成功
     */
    setRenderMirrorMode(enable: boolean): number;
    /**
     * 开始播放音视频流
     *
     * @param url 音视频流的播放地址，支持 RTMP, HTTP-FLV, TRTC。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK：操作成功，开始连接并播放。
     *         - V2TXLIVE_ERROR_INVALID_PARAMETER：操作失败，url 不合法。
     *         - V2TXLIVE_ERROR_REFUSED：RTC 不支持同一设备上同时推拉同一个 StreamId。
     */
    startPlay(url: string): number;
    /**
     * 停止播放音视频流
     *
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    stopPlay(): number;
    /**
     * 播放器是否正在播放中
     *
     * @return 是否正在播放。
     *         - 1: 正在播放中。
     *         - 0: 已经停止播放。
     */
    isPlaying(): number;
    /**
     * 暂停播放器的音频流
     *
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    pauseAudio(): number;
    /**
     * 恢复播放器的音频流
     *
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    resumeAudio(): number;
    /**
     * 暂停播放器的视频流
     *
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    pauseVideo(): number;
    /**
     * 恢复播放器的视频流
     *
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    resumeVideo(): number;
    /**
     * 设置播放器音量
     *
     * @param volume 音量大小，取值范围0 - 100。【默认值】: 100。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    setPlayoutVolume(volume: number): number;
    /**
     * 设置播放器缓存自动调整的最小和最大时间 ( 单位：秒 )
     *
     * @param minTime 缓存自动调整的最小时间，取值需要大于0。【默认值】：1。
     * @param maxTime 缓存自动调整的最大时间，取值需要大于0。【默认值】：5。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     *         - V2TXLIVE_ERROR_INVALID_PARAMETER: 操作失败，minTime 和 maxTime 需要大于0。
     *         - V2TXLIVE_ERROR_REFUSED: 播放器处于播放状态，不支持修改缓存策略。
     */
    setCacheParams(minTime: number, maxTime: number): number;
    /**
     * 直播流无缝切换，支持 FLV 和 LEB
     *
     * @param newUrl 新的拉流地址。
     */
    switchStream(newUrl: string): number;
    /**
     * 启用播放音量大小提示
     *
     * 开启后可以在 {@link V2TXLivePlayerObserver} 回调中获取到 SDK 对音量大小值的评估。
     * @param intervalMs 决定了 onPlayoutVolumeUpdate 回调的触发间隔，单位为ms，最小间隔为100ms，如果小于等于0则会关闭回调，建议设置为300ms；【默认值】：0，不开启。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    enableVolumeEvaluation(intervalMs: number): number;
    /**
     * 截取播放过程中的视频画面
     *
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     *         - V2TXLIVE_ERROR_REFUSED: 播放器处于停止状态，不允许调用截图操作。
     */
    snapshot(): number;
    /**
     * 开启接收 SEI 消息
     *
     * @param enable      true: 开启接收 SEI 消息; false: 关闭接收 SEI 消息。【默认值】: false。
     * @param payloadType 指定接收 SEI 消息的 payloadType，支持 5、242、243，请与发送端的 payloadType 保持一致。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     */
    enableReceiveSeiMessage(enable: boolean, payloadType: number): number;
    /**
     * 是否显示播放器状态信息的调试浮层
     *
     * @param isShow 是否显示。【默认值】：false。
     */
    showDebugView(isShow: boolean): void;
    /**
     * 调用 V2TXLivePlayer 的高级 API 接口
     *
     * @note  该接口用于调用一些高级功能。
     * @param key   高级 API 对应的 key。
     * @param value 调用 key 所对应的高级 API 时，需要的参数。
     * @return 返回值 {@link V2TXLiveCode}。
     *         - V2TXLIVE_OK: 成功。
     *         - V2TXLIVE_ERROR_INVALID_PARAMETER: 操作失败，key 不允许为 null。
     */
    setProperty(key: string, value: Object): number;
    /**
     * 开始录制音视频流
     *
     * @param  请参考 V2TXLiveDef.java 中关于 {@link V2TXLiveLocalRecordingParams}的介绍。
     * @return 返回值 {@link V2TXLiveCode}。
     *          - `V2TXLIVE_OK`: 成功。
     *          - `V2TXLIVE_ERROR_INVALID_PARAMETER` : 参数不合法，例如 filePath 为空。
     *          - `V2TXLIVE_ERROR_REFUSED`: API被拒绝，拉流尚未开始。
     * @note   拉流开启后才能开始录制，非拉流状态下开启录制无效。
     *        - 录制过程中不要动态切换软/硬解，生成的视频极有可能出现异常。
     */
    startLocalRecording(params: V2TXLiveLocalRecordingParams): number;
    /**
     * 停止录制音视频流
     *
     * @note  当停止拉流后，如果视频还在录制中，SDK 内部会自动结束录制。
     */
    stopLocalRecording(): void;
}
