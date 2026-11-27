/**
 * 支持协议
 */
export declare enum V2TXLiveMode {
    V2TXLiveModeRTMP = 0,
    V2TXLiveModeRTC = 1
}
/**
 * 视频分辨率
 */
export declare enum V2TXLiveVideoResolution {
    V2TXLiveVideoResolution160x160 = 0,
    V2TXLiveVideoResolution270x270 = 1,
    V2TXLiveVideoResolution480x480 = 2,
    V2TXLiveVideoResolution320x240 = 3,
    V2TXLiveVideoResolution480x360 = 4,
    V2TXLiveVideoResolution640x480 = 5,
    V2TXLiveVideoResolution320x180 = 6,
    V2TXLiveVideoResolution480x270 = 7,
    V2TXLiveVideoResolution640x360 = 8,
    V2TXLiveVideoResolution960x540 = 9,
    V2TXLiveVideoResolution1280x720 = 10,
    V2TXLiveVideoResolution1920x1080 = 11
}
/**
 * 视频宽高比模式
 *
 * @info 视频宽高比模式。
 * @note
 * - 横屏模式下的分辨率: V2TXLiveVideoResolution640x360 + V2TXLiveVideoResolutionModeLandscape = 640 × 360。
 * - 竖屏模式下的分辨率: V2TXLiveVideoResolution640x360 + V2TXLiveVideoResolutionModePortrait  = 360 × 640。
 */
export declare enum V2TXLiveVideoResolutionMode {
    V2TXLiveVideoResolutionModeLandscape = 0,
    V2TXLiveVideoResolutionModePortrait = 1
}
/**
 * 视频编码参数
 *
 * 该设置决定远端用户看到的画面质量。
 */
export declare class V2TXLiveVideoEncoderParam {
    videoResolution: V2TXLiveVideoResolution;
    videoResolutionMode: V2TXLiveVideoResolutionMode;
    videoFps: number;
    videoBitrate: number;
    minVideoBitrate: number;
    constructor(a21: any, b21?: number, videoBitrate?: number, c21?: number);
}
/**
 * 本地摄像头镜像类型
 */
export declare enum V2TXLiveMirrorType {
    V2TXLiveMirrorTypeAuto = 0,
    V2TXLiveMirrorTypeEnable = 1,
    V2TXLiveMirrorTypeDisable = 2
}
/**
 * 视频画面填充模式
 */
export declare enum V2TXLiveFillMode {
    V2TXLiveFillModeFill = 0,
    V2TXLiveFillModeFit = 1,
    V2TXLiveFillModeScaleFill = 2
}
/**
 * 视频画面顺时针旋转角度
 */
export declare enum V2TXLiveRotation {
    V2TXLiveRotation0 = 0,
    V2TXLiveRotation90 = 1,
    V2TXLiveRotation180 = 2,
    V2TXLiveRotation270 = 3
}
/**
 * 视频帧的像素格式
 */
export declare enum V2TXLivePixelFormat {
    V2TXLivePixelFormatUnknown = 0,
    V2TXLivePixelFormatBGRA32 = 2,
    V2TXLivePixelFormatRGBA32 = 3,
    V2TXLivePixelFormatTexture2D = 4
}
/**
 * 视频数据包装格式
 *
 * @info 视频数据包装格式。
 * @note 在自定义采集和自定义渲染功能，您需要用到下列枚举值来指定您希望以什么类型的容器来包装视频数据。
 * - Texture: 直接使用时效率最高。
 */
export declare enum V2TXLiveBufferType {
    V2TXLiveBufferTypeUnknown = 0,
    V2TXLiveBufferTypeTexture = 2
}
/**
 * 视频纹理包装类。
 */
export declare class V2TXLiveTexture {
    glTextureId: number;
    glContext: number;
}
/**
 * 视频帧信息
 *
 * @info 视频帧信息。
 *         V2TXLiveVideoFrame 用来描述一帧视频画面的裸数据，它可以是一帧编码前的画面，也可以是一帧解码后的画面。
 * @note  自定义采集和自定义渲染时使用。自定义采集时，需要使用 V2TXLiveVideoFrame 来包装待发送的视频帧；自定义渲染时，会返回经过 V2TXLiveVideoFrame 包装的视频帧。
 */
export declare class V2TXLiveVideoFrame {
    pixelFormat: V2TXLivePixelFormat;
    bufferType: V2TXLiveBufferType;
    width: number;
    height: number;
    rotation: V2TXLiveRotation;
    texture: V2TXLiveTexture;
}
/**
 * 声音音质
 */
export declare enum V2TXLiveAudioQuality {
    V2TXLiveAudioQualitySpeech = 0,
    V2TXLiveAudioQualityDefault = 1,
    V2TXLiveAudioQualityMusic = 2
}
/**
 * 音频帧数据
 */
export declare class V2TXLiveAudioFrame {
    data: ArrayBuffer;
    sampleRate: number;
    channel: number;
}
/**
 * 推流器的统计数据
 */
export declare class V2TXLivePusherStatistics {
    appCpu: number;
    systemCpu: number;
    width: number;
    height: number;
    fps: number;
    videoBitrate: number;
    audioBitrate: number;
    rtt: number;
    netSpeed: number;
    constructor(w20?: number, x20?: number, width?: number, height?: number, fps?: number, videoBitrate?: number, audioBitrate?: number, y20?: number, z20?: number);
}
/**
 * 播放器的统计数据
 */
export declare class V2TXLivePlayerStatistics {
    appCpu: number;
    systemCpu: number;
    width: number;
    height: number;
    fps: number;
    videoBitrate: number;
    audioBitrate: number;
    audioPacketLoss: number;
    videoPacketLoss: number;
    jitterBufferDelay: number;
    audioTotalBlockTime: number;
    audioBlockRate: number;
    videoTotalBlockTime: number;
    videoBlockRate: number;
    rtt: number;
    netSpeed: number;
    constructor(l20?: number, m20?: number, width?: number, height?: number, fps?: number, videoBitrate?: number, audioBitrate?: number, n20?: number, o20?: number, p20?: number, q20?: number, r20?: number, s20?: number, t20?: number, u20?: number, v20?: number);
}
/**
 * 直播流的连接状态
 */
export declare enum V2TXLivePushStatus {
    V2TXLivePushStatusDisconnected = 0,
    V2TXLivePushStatusConnecting = 1,
    V2TXLivePushStatusConnectSuccess = 2,
    V2TXLivePushStatusReconnecting = 3
}
/**
 * 混流输入类型配置
 */
export declare enum V2TXLiveMixInputType {
    V2TXLiveMixInputTypeAudioVideo = 0,
    V2TXLiveMixInputTypePureVideo = 1,
    V2TXLiveMixInputTypePureAudio = 2
}
/**
 * 云端混流中每一路子画面的位置信息
 */
export declare class V2TXLiveMixStream {
    userId: string;
    streamId: string;
    x: number;
    y: number;
    width: number;
    height: number;
    zOrder: number;
    inputType: V2TXLiveMixInputType;
    constructor(userId?: string, streamId?: string, x?: number, y?: number, width?: number, height?: number, k20?: number, inputType?: V2TXLiveMixInputType);
    toString(): string;
}
/**
 * 云端混流（转码）配置
 */
export declare class V2TXLiveTranscodingConfig {
    videoWidth: number;
    videoHeight: number;
    videoBitrate: number;
    videoFramerate: number;
    videoGOP: number;
    backgroundColor: number;
    backgroundImage: string;
    audioSampleRate: number;
    audioBitrate: number;
    audioChannels: number;
    mixStreams: Array<V2TXLiveMixStream>;
    outputStreamId: string;
    constructor();
    toString(): string;
}
/**
 * 本地音视频录制模式
 */
export declare enum V2TXLiveRecordMode {
    V2TXLiveRecordModeBoth = 0
}
/**
 * 本地录制音视频配置
 */
export declare class V2TXLiveLocalRecordingParams {
    filePath: string;
    recordMode: V2TXLiveRecordMode;
    interval: number;
    constructor();
}
/**
 * 日志级别枚举值
 */
export declare enum V2TXLiveLogLevel {
    V2TXLiveLogLevelAll = 0,
    V2TXLiveLogLevelDebug = 1,
    V2TXLiveLogLevelInfo = 2,
    V2TXLiveLogLevelWarning = 3,
    V2TXLiveLogLevelError = 4,
    V2TXLiveLogLevelFatal = 5,
    V2TXLiveLogLevelNULL = 6
}
/**
 * Log配置
 */
export declare class V2TXLiveLogConfig {
    logLevel: V2TXLiveLogLevel;
    enableObserver: boolean;
    enableConsole: boolean;
    enableLogFile: boolean;
    logPath: string;
    constructor();
}
