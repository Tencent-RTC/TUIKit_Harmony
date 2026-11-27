import { Context } from '@ohos.abilityAccessCtrl';
import { ParamType, TXBitrateItem, TXSubtitleRenderModel, TXTrackInfo } from "../../q3/x3";
import { AbstractTXVCubePlayer } from "../r4/s4";
import { TXVCubePlayerConfig } from "../r4/q4";
export declare class TXCThumbPlayer extends AbstractTXVCubePlayer {
    private static readonly TAG;
    private static readonly BizId;
    private static sdkInited;
    private context;
    private tpPlayer;
    private bitrateIndex;
    private cachedBytes;
    private bitrate;
    private tcpSpeed;
    private totalFileSize;
    private config?;
    private privateConfig?;
    private speedRate;
    private looping;
    private hasReceiveFirstVideoRenderEvent;
    private isSetDefaultBufferSize;
    private trtcCloud;
    private audioPublishing;
    private videoPublishing;
    /**
     * 构造一个TXCThumbPlayer对象.
     *
     * @param context 用于系统函数调用，内部会转成ApplicationContext保存.
     */
    constructor(context: Context);
    setDataSource(dataSource: string): void;
    private setPreferredProgramParam;
    private checkDlType;
    private isOfflinePlay;
    private setVideoInfo;
    setVideoRenderTarget(surfaceId: string): void;
    setAutoPlay(autoPlay: boolean): void;
    setConfig(k42: TXVCubePlayerConfig): void;
    setPrivateConfig(j42: Map<string, ParamType>): void;
    private parseExtraConfig;
    prepareAsync(): void;
    start(): void;
    stop(): void;
    isPlaying(): boolean;
    pause(): void;
    setScreenOnWhilePlaying(f42: boolean): void;
    getVideoWidth(): number;
    getVideoHeight(): number;
    reset(): void;
    release(): void;
    seekTo(c42: number, d42?: boolean): void;
    seekToPdtTime(b42: number): void;
    getCurrentPosition(): number;
    getDurationMs(): number;
    getPlayableDurationMs(): number;
    getPdtTimeMs(a42: number): number;
    getPositionMs(z41: number): number;
    setRate(rate: number): void;
    getRate(): number;
    setAudioVolume(volume: number): void;
    setAudioNormalization(value: number): void;
    setAudioStreamType(y41: number): void;
    getVideoSarNum(): number;
    getVideoSarDen(): number;
    setLooping(x41: boolean): void;
    isLooping(): boolean;
    getBitrateIndex(): number;
    setBitrateIndex(index: number): void;
    enableAdaptiveBitrate(): void;
    getSupportedBitrates(): TXBitrateItem[];
    setRenderMode(mode: number): void;
    /**
     * 挂接 TRTC 云服务，并向 thumbplayer 内核注册视频/音频帧回调，
     * 后续帧通过 sendCustomVideoData/sendCustomAudioData 送到 TRTC 网络。
     *
     * 注意：thumbplayer 侧要求音频帧回调必须在 prepareAsync 之前设置，
     * 因此该方法通常应在 startPlay 之前调用（与 Android 的 attachTRTC 一致）。
     */
    attachTRTC(l41: Object): void;
    /**
     * 解除 TRTC 挂接：反注册帧回调、关闭自定义采集、清理状态。
     * 与 Android 的 detachTRTC 逻辑保持一致。
     */
    detachTRTC(): void;
    publishAudioToNetwork(): void;
    unpublishAudioToNetwork(): void;
    publishVideoToNetwork(): void;
    unpublishVideoToNetwork(): void;
    getPropertyLong(i41: number): number;
    addSubtitleSource(dataSource: string, name: string, mimeType: string): void;
    addAudioTrackSource(dataSource: string, name: string): void;
    selectTrack(h41: number): void;
    deselectTrack(g41: number): void;
    getTrackInfo(): TXTrackInfo[];
    checkSubtitle(): void;
    setAutoMaxBitrate(x40: number): void;
    setSubtitleStyle(v40: TXSubtitleRenderModel): void;
    private convertToTPSubtitleRenderModel;
    private setupPlayerCallbacks;
    private transferInfo;
    private transferError;
    /**
     * 更新比特率的方法
     * @param {number} fileTotalSize 文件的总大小（字节）
     */
    updateBitrate(a40: number): void;
    /**
     * 收到视频首帧回调，收到后先保存起来，
     * 调用start之后马上发送出去
     */
    onReceiveFirstVideoRenderEvent(): void;
    private transferToVodSubtitleData;
    private innerLogI;
    private innerLogE;
    /**
     * ThumbPlayer 视频帧输出回调 → 剥离 stride、组装 I420 → sendCustomVideoData(SUB)。
     *
     * TPVideoFrameBuffer 中 data[0..2] 为 Y/U/V 三平面，lineSize 为每平面的行 stride，
     * 可能大于 width/2，因此需要按行拷贝，剥离 padding 后紧凑拼成一整块 ArrayBuffer。
     */
    private onVideoFrameOutForTRTC;
    /**
     * 按行拷贝一个 plane，剥离 stride padding。
     * @param src        源 plane 数据（长度可能为 stride*height）
     * @param stride     源每行字节数（可能 > width）
     * @param width      有效宽度（每行实际字节数）
     * @param height     行数
     * @param dst        目标 buffer
     * @param dstOffset  目标 buffer 内起始偏移
     */
    private copyPlane;
    /**
     * 将 TP 的 0/90/180/270 角度映射为 TRTCVideoRotation 枚举。
     */
    private mapRotation;
    /**
     * ThumbPlayer 音频帧输出回调 → 转发给 TRTC 做外部混音。
     * 注：设置了 OUT_AUDIO_SAMPLE_FORMAT = S16 后，audioFrame.data[0] 即 interleaved PCM16 数据。
     */
    private onAudioFrameOutForTRTC;
}
