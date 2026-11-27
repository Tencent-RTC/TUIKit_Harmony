import { Context } from '@ohos.abilityAccessCtrl';
import { ITXVodPlayCallback } from "../q3/g4";
import { TXBitrateItem, TXPlayInfoParams, TXSubtitleRenderModel, TXTrackInfo } from "../q3/x3";
import { TXVodPlayConfig } from "../q3/j4";
import { TXVodPlayer } from "../q3/f4";
export declare class TXCVodPlayer {
    TAG: string;
    private static readonly TAG;
    private static readonly HARDWARE_DECODE;
    private static readonly SOFTWARE_DECODE;
    private static readonly SOFTWARE_DECODE_264;
    private static readonly HARDWARE_DECODE_264;
    private static readonly SOFTWARE_DECODE_265;
    private static readonly HARDWARE_DECODE_265;
    private static readonly MIN_RETRY_PROGRESS_INTERVAL;
    private static readonly AUDIO_NORMALIZATION_NOT_SET;
    private context;
    private mediaPlayer;
    private vodPlayCallback;
    private txVodPlayerReference;
    private vodConfig;
    private recvFirstRenderEvent;
    private isGainAudioFocus;
    private autoPlay;
    private enableHWDec;
    private rate;
    private surfaceId;
    private isStopped;
    private privateConfig;
    private bitrateIndex;
    private playInfoParams;
    private overlayInfo;
    private preferredResolution;
    private playUrl;
    private loop;
    private startTimeMs;
    private onceLoopRestart;
    private subtitleRenderModel;
    private autoMaxBitrate;
    private vInfo;
    private currentState;
    private targetState;
    private videoWidth;
    private videoHeight;
    private surfaceWidth;
    private surfaceHeight;
    private videoRotationDegree;
    private metaRotationDegree;
    private playingStateBufferProcess;
    private durationBeforeNew;
    private surfaceRender;
    private videoSarNum;
    private videoSarDen;
    private serverIp;
    private autoPreferredResolution;
    protected playerType: number;
    private lastSeekWhenPrepared;
    private isSeeking;
    private seekWhenSeekComplete;
    private audioVolume;
    private audioNormalization;
    private isMute;
    private latestValidBitrate;
    private latestValidBitrateIndex;
    private isRendering;
    private static hasPremiumLicense;
    private static isHevcSupportedChecked;
    private static isHevcSupported;
    private static isHevcDecodeFailed;
    private isHevcPlayUrl;
    private backupPlayUrl;
    private updateNetStatusIntervalID;
    private refreshProgressIntervalID;
    private trtcCloud;
    private isPublishVideo;
    private isPublishAudio;
    /**
     * 当mediaPlayer==null时，保存用户添加的字幕轨数据,openVideo的时候传给mediaPlayer
     */
    private cacheSubtitleSourceList;
    /**
     * 当mediaPlayer==null时，保存用户添加的外挂音轨数据,openVideo的时候传给mediaPlayer
     */
    private cacheAudioTrackSourceList;
    private selectedSubtitleList;
    private successfulSelectedAudioTrackName;
    private selectedAudioTrack;
    private selectingTrack;
    /**
     * 构造一个player对象.
     *
     * @param context 用于系统函数调用，内部会转成ApplicationContext保存.
     */
    constructor(context: Context);
    /**
     * 设置播放器配置信息.
     * <p>
     * <p>推荐在启动播放前设置配置信息.
     *
     * @param config 播放器配置信息.配置信息请参考 {@link TXVodPlayConfig}.
     */
    setConfig(config: TXVodPlayConfig | null): void;
    /**
     * 设置字幕样式信息，可在播放后对字幕样式进行更新
     * @param renderModel 字幕样式配置信息 {@link TXSubtitleRenderModel}
     */
    setSubtitleStyle(x47: TXSubtitleRenderModel): void;
    /**
     * 设置用于视频渲染的目标。
     * 设置render
     * target之后，底层在条件满足的情况下，会开始输出视频帧。因此，在设置之前，必须确保跟该target
     * 已经根据视频流信息设置了正确的宽高，否则有可能导致前面显示若干帧宽高不正确。
     *
     * @param surfaceId surface实例的标识
     * @return
     */
    setVideoRenderTarget(surfaceId: string): void;
    /**
     * 添加外挂字幕
     * @param url 字幕地址
     * @param name
     *     字幕的名字。如果添加多个字幕，字幕名称请设置为不同的名字，用于区分与其他添加的字幕，否则可能会导致字幕选择错误。
     * @param mimeType 字幕类型，仅支持VVT和SRT格式 {@link
     *     TXVodConstants#VOD_PLAY_MIMETYPE_TEXT_SRT}, {@link
     *     TXVodConstants#VOD_PLAY_MIMETYPE_TEXT_VTT}
     *  后面可以通过{@link #getSubtitleTrackInfo()}中的{@link TXTrackInfo#getName()}获取对应的名字
     */
    addSubtitleSource(url: string, name: string, mimeType: string): void;
    /**
     * 添加外挂音轨
     * @param url 外挂音轨的url
     * @param name
     *     外挂音轨的名字。如果添加多个音轨，音轨名称请设置为不同的名字，用于区分与其他添加的音轨，否则可能会导致音轨选择错误。
     */
    addAudioTrackSource(url: string, name: string): void;
    private selectTrackIfNeedWhenReplay;
    private recordStartSelectTrackInfo;
    private recordSelectTrackCompleteInfo;
    private sendSelectTrackCompleteTrackEvent;
    /**
     * 选择轨道
     * @param trackIndex 轨道index，通过{@link TXTrackInfo#getTrackIndex()} 获取
     */
    selectTrack(j47: number): void;
    /**
     * 取消选定的轨道
     * @param trackIndex 轨道索引，通过{@link TXTrackInfo#getTrackIndex()}获取
     */
    deselectTrack(h47: number): void;
    /**
     * 返回字幕轨道信息列表
     * @return 字幕轨道信息列表
     */
    getSubtitleTrackInfo(): TXTrackInfo[];
    /**
     * 返回音频轨道信息列表
     * @return 音频轨道信息列表
     */
    getAudioTrackInfo(): TXTrackInfo[];
    /**
     * 使用fileId或url开始播放。
     *
     * @param playInfoParams 与fileId或url相关的播放信息参数
     */
    startPlay(r46: TXPlayInfoParams): void;
    private doPlayEventCallback;
    /**
     * 普通url播放
     * @param playUrl 视频链接
     * @return 播放状态码。0表示成功，-1表示播放链接为空，其他值表示不同的错误码
     */
    private startPlayUrl;
    /**
     * 如果上次播放是DRM，那么会存留DRM信息。用于重播场景辅助设置DRM信息
     */
    private hasWidevineDrmInfo;
    /**
     * 清理drm信息，如果播放的不是DRM(Widevine)，应及时清理DRM的信息，避免变成DRM播放
     */
    private clearWidevineDrmInfo;
    /**
     * 启动Widevine DRM播放
     * @param playUrl 播放URL
     * @param keyLicenseUrl 密钥许可URL
     * @param provisionUrl provision URL
     * @param downgradeUrl 降级播放SimpleAES地址
     * @param overlayInfo 叠加信息
     * @returns 播放状态码
     */
    private doStartWidevineDrmPlay;
    /**
     * 开始播放指定的播放链接。
     *
     * @param playUrl 要播放的视频链接
     * @return 播放状态码。0表示成功，-1表示播放链接为空，其他值表示不同的错误码
     */
    private doStartPlay;
    private parsePlayUrl;
    private stripOversign;
    private openVideo;
    private updateNetStatus;
    private refreshProgress;
    private release;
    private releaseMediaPlayerCallbacks;
    /**
     * 停止播放。
     *
     * @param isNeedClearLastImg 是否清除最后一帧图像。true:
     *     清除最后一帧图像。建议在正常停止播放时清除。false:
     *     保留最后一帧图像。建议在异常停止播放（如网络异常导致播放被迫停止）且SDK用户希望重新连接服务器继续播放时保留。
     * @return 是否成功停止播放。0: 成功。非0: 失败。
     */
    stopPlay(w44: boolean): number;
    /**
     * 是否正在播放。
     *
     * @return 是否正在播放。true: 正在播放。false: 未播放。
     */
    isPlaying(): boolean;
    /**
     * 暂停播放，停止获取流数据，并保持最后一帧图像。
     */
    pause(): void;
    /**
     * 恢复播放，重新获取流数据。
     * <p>
     * <p> 点播从暂停位置开始播放，直播从当前位置开始播放实时图像。
     */
    resume(): void;
    /**
     * 跳转到视频流中的指定时间点
     * 注意：此接口支持版本11.8
     * @param timeMs 视频流时间点，单位为豪秒（ms）
     * @param isAccurateSeek 是否精确Seek
     *                      -- true: 精确Seek，必须找到当前时间点，这将更耗时
     *                      -- false：非精确Seek，即找到上一个I帧
     */
    seek(timeMs: number, u44?: boolean): void;
    private isInPlaybackState;
    /**
     * 跳转到视频流中指定的PDT时间点。
     * <p>
     * <p> 可以实现视频快进、快退、进度条跳转等功能。
     *
     * @param pdtTimeMs 视频流的PDT时间点，以毫秒(ms)为单位
     */
    seekToPdtTime(s44: number): void;
    /**
     * 当前播放时间，单位ms
     *
     * @return
     */
    getCurrentPlaybackTimeMs(): number;
    getBufferDurationMs(): number;
    getDurationMs(): number;
    getPlayableDurationMs(): number;
    /**
     * 获取视频宽度
     *
     * @return 视频宽度
     */
    getWidth(): number;
    /**
     * 获取视频高度
     *
     * @return 视频高度
     */
    getHeight(): number;
    /**
     * 设置播放器的回调函数。
     *
     * @param callback 播放器回调。请参考{@link ITXVodPlayCallback}
     */
    setVodPlayCallback(o44: TXVodPlayer, callback: ITXVodPlayCallback): void;
    /**
     * 启用或禁用视频硬解码.
     *
     * @param enable 启用或禁用视频硬解码. true:启用视频硬解码.
     *     false:禁用视频硬解码.启用默认的视频软解码.
     * @return 是否成功启用或禁用视频硬解码. true:启用或禁用视频硬解码成功.
     *     false:启用或禁用视频硬解码失败.
     */
    enableHardwareDecode(enable: boolean): boolean;
    /**
     * 挂接 TRTC 云服务，将点播的音视频通过 TRTC 通道分发。
     * 需要在启动播放前调用，用于播片（云端播放器 + 直播互动）场景。
     *
     * @param trtcCloud 上层传入的 TRTCCloud 实例
     */
    attachTRTC(n44: Object): void;
    /**
     * 解除对 TRTC 云服务的挂接，同时会取消当前的音视频发布。
     */
    detachTRTC(): void;
    /**
     * 将当前点播视频画面发布到 TRTC 网络（配合 attachTRTC 使用）。
     */
    publishVideo(): void;
    /**
     * 停止将当前点播视频画面发布到 TRTC 网络。
     */
    unpublishVideo(): void;
    /**
     * 将当前点播音频发布到 TRTC 网络（配合 attachTRTC 使用）。
     */
    publishAudio(): void;
    /**
     * 停止将当前点播音频发布到 TRTC 网络。
     */
    unpublishAudio(): void;
    /**
     * 设置是否静音播放。
     *
     * @param mute 是否静音播放。true: 静音播放。false: 不静音播放。
     */
    setMute(mute: boolean): void;
    /**
     * 设置音量大小
     *
     * @param volume 音量大小。范围：0 ~ 100。
     */
    setAudioPlayoutVolume(volume: number): void;
    /**
     * 设置VOD在startPlay后是否自动开始播放，默认为自动播放
     *
     * @param autoPlay
     */
    setAutoPlay(autoPlay: boolean): void;
    /**
     * 设置VOD的播放速率。默认1.0
     *
     * @param rate
     */
    setRate(rate: number): void;
    /**
     * 返回当前播放的码率索引
     *
     * @return
     */
    getBitrateIndex(): number;
    /**
     * 设置当前播放的码率索引，无缝切换清晰度
     * 清晰度切换可能需要短暂的时间。腾讯云支持多码率HLS切片对齐以确保最佳体验。
     *
     * @param index 码率索引，index == -1，表示启用HLS流自适应；
     *              index > 0 {@link
     * TXVodPlayer#getSupportedBitrates()}，表示手动切换到对应清晰度的码率
     * @see TXBitrateItem#index
     */
    setBitrateIndex(index: number): void;
    /**
     * 重新播放视频
     * @param isFromErrorState 是否来自错误状态
     */
    private replay;
    /**
     * 如果播放地址是主播放ArrayList，则返回支持的码率（清晰度）
     * <p>
     * <p>只有在接收到PLAY_EVT_PLAY_BEGIN事件后才能正确返回结果
     *
     * @return 码率ArrayList；如果没有多码率支持，则为空数组
     */
    getSupportedBitrates(): TXBitrateItem[];
    /**
     * 设置播放的起始时间。
     * <p>
     * 在调用startPlay之前设置，以修改播放的起始位置。
     *
     * @param pos 视频流时间点，以秒（s）为单位，精确到小数点后三位。
     */
    setStartTime(pos: number): void;
    /**
     * 设置是否循环播放
     *
     * @param loop
     */
    setLoop(loop: boolean): void;
    isLoop(): boolean;
    /**
     * 设置自适应播放时能切换的最高码率
     * @param autoMaxBitrate 自适应播放时能切换的最高码率
     */
    setAutoMaxBitrate(l44: number): void;
    /**
     * 获取UI组件快照
     * @param uiContext UI上下文
     * @param nativeXComponentID 原生X组件ID
     */
    private screenshot;
    /**
     * 异步快照
     * @param uiContext UI上下文（可选）
     * @param nativeXComponentID 原生X组件ID（可选）
     */
    snapshotAsync(uiContext: any, i44: string): void;
    private start;
    getMetaRotationDegree(): number;
    private readonly preparedCallback;
    private readonly completionCallback;
    private readonly seekCompleteCallback;
    private readonly videoSizeChangedCallback;
    private retryCount;
    private readonly errorCallback;
    private onHevcVideoDecoderError;
    private onVideoDecoderError;
    private onHLSKeyError;
    private readonly infoCallback;
    private readonly subtitleDataCallback;
    private innerLogI;
    private innerLogE;
}
