/**
 * 1.1 视频分辨率。
 *
 * 此处仅定义横屏分辨率（如 640 × 360），如需使用竖屏分辨率（如360 × 640），需要同时指定 {@link TRTCVideoResolutionMode} 为 Portrait。
 */
export declare enum TRTCVideoResolution {
    TRTCVideoResolution_120_120 = 1,
    TRTCVideoResolution_160_160 = 3,
    TRTCVideoResolution_270_270 = 5,
    TRTCVideoResolution_480_480 = 7,
    TRTCVideoResolution_160_120 = 50,
    TRTCVideoResolution_240_180 = 52,
    TRTCVideoResolution_280_210 = 54,
    TRTCVideoResolution_320_240 = 56,
    TRTCVideoResolution_400_300 = 58,
    TRTCVideoResolution_480_360 = 60,
    TRTCVideoResolution_640_480 = 62,
    TRTCVideoResolution_960_720 = 64,
    TRTCVideoResolution_160_90 = 100,
    TRTCVideoResolution_256_144 = 102,
    TRTCVideoResolution_320_180 = 104,
    TRTCVideoResolution_480_270 = 106,
    TRTCVideoResolution_640_360 = 108,
    TRTCVideoResolution_960_540 = 110,
    TRTCVideoResolution_1280_720 = 112,
    TRTCVideoResolution_1920_1080 = 114
}
/**
 * 1.2 视频宽高比模式。
 *
 * TRTCVideoResolution 中仅定义了横屏分辨率（如 640 × 360），如需使用竖屏分辨率（如360 × 640），需要同时指定 `TRTCVideoResolutionMode` 为 Portrait。
 */
export declare enum TRTCVideoResolutionMode {
    TRTCVideoResolutionModeLandscape = 0,
    TRTCVideoResolutionModePortrait = 1
}
/**
 * 1.3 视频流类型。
 *
 * TRTC 内部有三种不同的视频流，分别是：
 *  - 高清大画面：一般用来传输摄像头的视频数据。
 *  - 低清小画面：小画面和大画面的内容相互，但是分辨率和码率都比大画面低，因此清晰度也更低。
 *  - 辅流画面：一般用于屏幕分享，同一时间在同一个房间中只允许一个用户发布辅流视频，其他用户必须要等该用户关闭之后才能发布自己的辅流。
 * @note 不支持单独开启低清小画面，小画面必须依附于大画面而存在，SDK 会自动设定低清小画面的分辨率和码率。
 */
export declare enum TRTCVideoStreamType {
    TRTCVideoStreamTypeBig = 0,
    TRTCVideoStreamTypeSmall = 1,
    TRTCVideoStreamTypeSub = 2
}
/**
 * 1.4 视频画面填充模式。
 *
 * 如果视频显示区域的宽高比不等于视频内容的宽高比时，需要指定画面的填充模式。
 */
export declare enum TRTCVideoFillMode {
    TRTCVideoFillMode_Fill = 0,
    TRTCVideoFillMode_Fit = 1
}
/**
 * 1.5 视频画面旋转方向。
 *
 * TRTC 提供了对本地和远程画面的旋转角度设置 API，下列的旋转角度都是指顺时针方向的。
 */
export declare enum TRTCVideoRotation {
    TRTCVideoRotation0 = 0,
    TRTCVideoRotation90 = 1,
    TRTCVideoRotation180 = 2,
    TRTCVideoRotation270 = 3
}
/**
 * 1.6 美颜（磨皮）算法。
 *
 * TRTC 内置多种不同的磨皮算法，您可以选择最适合您产品定位的方案。
 */
export declare enum TRTCBeautyStyle {
    TRTCBeautyStyleSmooth = 0,
    TRTCBeautyStyleNature = 1
}
/**
 * 1.7 视频像素格式。
 *
 * TRTC 提供针对视频的自定义采集和自定义渲染功能：
 * - 在自定义采集功能中，您可以用下列枚举值描述您采集的视频像素格式。
 * - 在自定义渲染功能中，您可以指定您期望 SDK 回调出的视频像素格式。
 */
export declare enum TRTCVideoPixelFormat {
    TRTCVideoPixelFormat_Unknown = 0,
    TRTCVideoPixelFormat_I420 = 1,
    TRTCVideoPixelFormat_Texture_2D = 2,
    TRTCVideoPixelFormat_BGRA32 = 3,
    TRTCVideoPixelFormat_NV21 = 4,
    TRTCVideoPixelFormat_RGBA32 = 5
}
/**
 * 1.8 视频数据传递方式。
 *
 * 在自定义采集和自定义渲染功能，您需要用到下列枚举值来指定您希望以什么方式传递视频数据：
 * - 方案一：使用内存 Buffer 传递视频数据，该方案在 iOS 效率尚可，但在 Android 系统上效率较差，Windows 暂时仅支持内存 Buffer 的传递方式。
 * - 方案二：使用 Texture 纹理传递视频数据，该方案在 iOS 和 Android 系统下均有较高的效率，Windows 暂不支持，需要您有一定的 OpenGL 编程基础。
 */
export declare enum TRTCVideoBufferType {
    TRTCVideoBufferType_Unknown = 0,
    TRTCVideoBufferType_Buffer = 1,
    TRTCVideoBufferType_Texture = 3
}
/**
 * 1.9 视频的镜像类型。
 *
 * 视频的镜像是指对视频内容进行左右翻转，尤其是对本地的摄像头预览视频，开启镜像后能给主播带来熟悉的“照镜子”体验。
 */
export declare enum TRTCVideoMirrorType {
    TRTCVideoMirrorType_Auto = 0,
    TRTCVideoMirrorType_Enable = 1,
    TRTCVideoMirrorType_Disable = 2
}
/**
 * 1.10 本地视频截图的数据源。
 *
 * SDK 支持从如下两种数据源中截取图片并保存成本地文件：
 * - 视频流：从视频流中截取原生的视频内容，截取的内容不受渲染控件的显示控制。
 * - 渲染层：从渲染控件中截取显示的视频内容，可以做到用户所见即所得的效果，但如果显示区域过小，截取出的图片也会很小。
 * - 采集层：从采集控件中截取采集到的视频内容，可以截取采集出来的高清截图。
 */
export declare enum TRTCSnapshotSourceType {
    TRTCSnapshotSourceTypeStream = 0,
    TRTCSnapshotSourceTypeView = 1,
    TRTCSnapshotSourceTypeCapture = 2
}
/**
 * 2.1 应用场景。
 *
 * TRTC 针对常见的音视频应用场景都进行了定向优化，以满足各种垂直场景下的差异化要求，主要场景可以分为如下两类：
 * - 直播（LIVE）场景：包括 LIVE 和 VoiceChatRoom，前者是音频+视频，后者是纯音频。
 *   直播场景下，用户被分成“主播”和“观众”两种角色，单个房间中同时最多支持10万人在线，适合于观众人数众多的直播场景。
 * - 实时（RTC）场景：包括 VideoCall 和 AudioCall，前者是音频+视频，后者是纯音频。
 *   实时场景下，用户没有角色的差异，但单个房间中同时最多支持 300 人在线，适合于小范围实时通信的场景。
 */
export declare enum TRTCAppScene {
    TRTCAppSceneVideoCall = 0,
    TRTCAppSceneLIVE = 1,
    TRTCAppSceneAudioCall = 2,
    TRTCAppSceneVoiceChatRoom = 3
}
/**
 * 2.2 角色。
 *
 * 仅适用于直播类场景（即 {@link TRTCAppSceneLIVE} 和 {@link TRTCAppSceneVoiceChatRoom}），把用户区分成两种不同的身份：
 * - 主播：可以随时发布自己的音视频流，但人数有限制，同一个房间中最多只允许 50 个主播同时发布自己的音视频流。
 * - 观众：只能观看其他用户的音视频流，要发布音视频流，需要先通过 {@link switchRole} 切换成主播，同一个房间中最多能容纳10万观众。
 */
export declare enum TRTCRoleType {
    TRTCRoleAnchor = 20,
    TRTCRoleAudience = 21
}
/**
 * 2.5 网络质量。
 *
 * TRTC 会每隔两秒对当前的网络质量进行评估，评估结果为六个等级：Excellent 表示最好，Down 表示最差。
 */
export declare enum TRTCQuality {
    TRTCQuality_Unknown = 0,
    TRTCQuality_Excellent = 1,
    TRTCQuality_Good = 2,
    TRTCQuality_Poor = 3,
    TRTCQuality_Bad = 4,
    TRTCQuality_Vbad = 5,
    TRTCQuality_Down = 6
}
/**
 * 2.6 音视频状态类型。
 *
 * 该枚举类型用于音频状态变化回调接口（{@link onRemoteAudioStatusUpdated}）与视频状态变化回调接口（{@link onRemoteVideoStatusUpdated}），用于指定当前的音频或视频状态。
 */
export declare enum TRTCAVStatusType {
    TRTCAVStatusStopped = 0,
    TRTCAVStatusPlaying = 1,
    TRTCAVStatusLoading = 2
}
/**
 * 2.7 音视频状态变化原因类型。
 *
 * 该枚举类型用于音频状态变化回调接口（{@link onRemoteAudioStatusUpdated}）与视频状态变化回调接口（{@link onRemoteVideoStatusUpdated}），用于指定当前的音频或视频状态变化原因。
 */
export declare enum TRTCAVStatusChangeReason {
    TRTCAVStatusChangeReasonInternal = 0,
    TRTCAVStatusChangeReasonBufferingBegin = 1,
    TRTCAVStatusChangeReasonBufferingEnd = 2,
    TRTCAVStatusChangeReasonLocalStarted = 3,
    TRTCAVStatusChangeReasonLocalStopped = 4,
    TRTCAVStatusChangeReasonRemoteStarted = 5,
    TRTCAVStatusChangeReasonRemoteStopped = 6
}
/**
 * 3.2 声音音质。
 *
 * TRTC 提供了三种精心校调好的模式，用来满足各种垂直场景下对音质的差异化追求：
 * - 人声模式（Speech）：适用于以人声沟通为主的应用场景，该模式下音频传输的抗性较强，TRTC 会通过各种人声处理技术保障在弱网络环境下的流畅度最佳。
 * - 音乐模式（Music）：适用于对声乐要求很苛刻的场景，该模式下音频传输的数据量很大，TRTC 会通过各项技术确保音乐信号在各频段均能获得高保真的细节还原度。
 * - 默认模式（Default）：介于 Speech 和 Music 之间的档位，对音乐的还原度比人声模式要好，但传输数据量比音乐模式要低很多，对各种场景均有不错的适应性。
 */
export declare enum TRTCAudioQuality {
    TRTCAudioQualitySpeech = 1,
    TRTCAudioQualityDefault = 2,
    TRTCAudioQualityMusic = 3
}
/**
 * 3.3 音频路由（即声音的播放模式）。
 *
 * 音频路由，即声音是从手机的扬声器还是从听筒中播放出来，因此该接口仅适用于手机等移动端设备。
 * 手机有两个扬声器：一个是位于手机顶部的听筒，一个是位于手机底部的立体声扬声器。
 * - 设置音频路由为听筒时，声音比较小，只有将耳朵凑近才能听清楚，隐私性较好，适合用于接听电话。
 * - 设置音频路由为扬声器时，声音比较大，不用将手机贴脸也能听清，因此可以实现“免提”的功能。
 * - 音频路由为有线耳机。
 * - 音频路由为蓝牙耳机。
 * - 音频路由为USB专业声卡设备。
 */
export declare enum TRTCAudioRoute {
    TRTCAudioModeUnknown = -1,
    TRTCAudioModeSpeakerphone = 0,
    TRTCAudioModeEarpiece = 1,
    TRTCAudioModeWiredHeadset = 2,
    TRTCAudioModeBluetoothHeadset = 3,
    TRTCAudioModeSoundCard = 4
}
/**
 * 3.9 音频回调数据读写模式。
 *
 * TRTC 提供了两种音频回调数据的操作模式。
 * - 读写模式（ReadWrite）：可以获取并修改回调的音频数据，默认模式。
 * - 只读模式（ReadOnly）：仅从回调中获取音频数据。
 */
export declare enum TRTCAudioFrameOperationMode {
    TRTCAudioFrameOperationModeReadWrite = 0,
    TRTCAudioFrameOperationModeReadOnly = 1
}
/**
 * 4.1 Log 级别。
 *
 * 不同的日志等级定义了不同的详实程度和日志数量，推荐一般情况下将日志等级设置为：TRTCLogLevelInfo。
 */
export declare enum TRTCLogLevel {
    TRTCLogLevelVerbose = 0,
    TRTCLogLevelDebug = 1,
    TRTCLogLevelInfo = 2,
    TRTCLogLevelWarn = 3,
    TRTCLogLevelError = 4,
    TRTCLogLevelFatal = 5,
    TRTCLogLevelNone = 6
}
/**
 * 4.5 媒体录制类型。
 *
 * 该枚举类型用于本地媒体录制接口 {@link startLocalRecording}，用于指定是录制音视频文件还是纯音频文件。
 */
export declare enum TRTCLocalRecordType {
    TRTCRecordTypeAudio = 0,
    TRTCRecordTypeVideo = 1,
    TRTCRecordTypeBoth = 2
}
/**
 * 4.11 音频录制内容类型。
 *
 * 该枚举类型用于音频录制接口 {@link startAudioRecording}，用于指定录制音频的内容。
 */
export declare enum TRTCAudioRecordingContent {
    TRTCAudioRecordingContentAll = 0,
    TRTCAudioRecordingContentLocal = 1,
    TRTCAudioRecordingContentRemote = 2
}
/**
 * 4.12 媒体流发布模式。
 *
 * 该枚举类型用于媒体流发布接口 {@link startPublishMediaStream} TRTC 的媒体流发布服务能够将房间中的多路音视频流混合成一路发布至 CDN 或者回推到房间内，也可以将您当前的这路音视频发布到腾讯或者第三方 CDN
 * 因此您需要指定对应媒体流的发布模式，我们提供了如下几种模式。
 */
export declare enum TRTCPublishMode {
    TRTCPublishModeUnknown = 0,
    TRTCPublishBigStreamToCdn = 1,
    TRTCPublishSubStreamToCdn = 2,
    TRTCPublishMixStreamToCdn = 3,
    TRTCPublishMixStreamToRoom = 4
}
/**
 * 4.14 测速场景。
 *
 * 该枚举类型用于测速场景选择。
 */
export declare enum TRTCSpeedTestScene {
    TRTCSpeedTestScene_DelayTesting = 1,
    TRTCSpeedTestScene_DelayAndBandwidthTesting = 2,
    TRTCSpeedTestScene_OnlineChorusTesting = 3
}
/**
 * 4.15 设置重力感应的适配模式（仅适用于移动端）。
 *
 * v11.7 版本开始支持，只在 SDK 内部摄像头采集场景生效
 */
export declare enum TRTCGravitySensorAdaptiveMode {
    TRTCGravitySensorAdaptiveMode_Disable = 0,
    TRTCGravitySensorAdaptiveMode_FillByCenterCrop = 1,
    TRTCGravitySensorAdaptiveMode_FitWithBlackBorder = 2
}
/**
 * 5.1 进房参数。
 *
 * 作为 TRTC SDK 的进房参数，只有该参数填写正确，才能顺利进入 roomId 或者 strRoomId 所指定的音视频房间。
 * 由于历史原因，TRTC 支持数字和字符串两种类型的房间号，分别是 roomId 和 strRoomId。
 * 请注意：不要混用 roomId 和 strRoomId，因为它们之间是不互通的，例如数字 123 和字符串 “123” 在 TRTC 看来是两个完全不同的房间。
 */
export declare class TRTCParams {
    sdkAppId: number;
    userId: string;
    userSig: string;
    roomId: number;
    strRoomId: string;
    role: number;
    streamId: null | string;
    userDefineRecordId: null | string;
    privateMapKey: null | string;
    businessInfo: null | string;
    constructor(m25?: number, userId?: string, n25?: string, o25?: number, p25?: string, role?: TRTCRoleType, q25?: null | string, r25?: null | string, streamId?: null | string, s25?: null | string);
}
/**
 * 5.2 视频编码参数。
 *
 * 该设置决定远端用户看到的画面质量，同时也决定了云端录制出的视频文件的画面质量。
 */
export declare class TRTCVideoEncParam {
    videoResolution: TRTCVideoResolution;
    resMode: TRTCVideoResolutionMode;
    videoFps: number;
    videoBitrate: number;
    minVideoBitrate: number;
    enableAdjustRes: boolean;
    constructor(h25?: TRTCVideoResolution, i25?: TRTCVideoResolutionMode, j25?: number, videoBitrate?: number, k25?: number, l25?: boolean);
}
/**
 * 5.4 视频画面的渲染参数。
 *
 * 您可以通过设置此参数来控制画面的旋转角度、填充模式和左右镜像模式。
 */
export declare class TRTCRenderParams {
    rotation: TRTCVideoRotation;
    fillMode: TRTCVideoFillMode;
    mirrorType: TRTCVideoMirrorType;
    constructor(rotation?: TRTCVideoRotation, fillMode?: TRTCVideoFillMode, g25?: TRTCVideoMirrorType);
}
/**
 * 5.5 网络质量。
 *
 * 表征网络质量的好坏，您可以通过该数值在用户界面上展示每个用户的网络质量。
 */
export declare class TRTCQualityInfo {
    userId: string;
    quality: TRTCQuality;
    constructor(userId?: string, quality?: TRTCQuality);
}
/**
 * 5.6 音量大小。
 *
 * 表征语音音量的评估值，您可以通过该数值在用户界面上展示每个用户的音量大小。
 */
export declare class TRTCVolumeInfo {
    userId: string;
    volume: number;
    vad: number;
    pitch: number;
    spectrumData: Float32Array;
    spectrumDataLength: number;
    constructor(userId?: string, volume?: number, d25?: number, pitch?: number, e25?: Float32Array, f25?: number);
}
/**
 * 5.7 测速参数。
 *
 * 您可以在用户进入房间前通过 {@link startSpeedTest} 接口测试网速（注意：请不要在通话中调用）。
 */
export declare class TRTCSpeedTestParams {
    sdkAppId: number;
    userId: string;
    userSig: string;
    expectedUpBandwidth: number;
    expectedDownBandwidth: number;
    scene: TRTCSpeedTestScene;
}
/**
 * 5.8 网络测速结果。
 *
 * 您可以在用户进入房间前通过 {@link startSpeedTest} 接口进行测速（注意：请不要在通话中调用）。
 */
export declare class TRTCSpeedTestResult {
    success: boolean;
    errMsg: string;
    ip: string;
    quality: TRTCQuality;
    upLostRate: number;
    downLostRate: number;
    rtt: number;
    availableUpBandwidth: number;
    availableDownBandwidth: number;
    upJitter: number;
    downJitter: number;
}
/**
 * 5.9 视频纹理数据。
 */
export declare class TRTCTexture {
    glTextureId: number;
    glContext: number;
}
/**
 * 5.10 视频帧信息。
 *
 * TRTCVideoFrame 用来描述一帧视频画面的裸数据，也就是编码前或者解码后的视频画面数据。
 */
export declare class TRTCVideoFrame {
    videoFormat: TRTCVideoPixelFormat;
    bufferType: TRTCVideoBufferType;
    texture: TRTCTexture;
    data: ArrayBuffer;
    width: number;
    height: number;
    timestamp: number;
    rotatioin: TRTCVideoRotation;
}
/**
 * 5.11 音频帧数据。
 */
export declare class TRTCAudioFrame {
    data: ArrayBuffer;
    sampleRate: number;
    channel: number;
    timestamp: number;
    extraData: ArrayBuffer;
}
/**
 * 5.15 本地音频文件的录制参数。
 *
 * 该参数用于在音频录制接口 {@link startAudioRecording} 中指定录制参数。
 */
export declare class TRTCAudioRecordingParams {
    filePath: string;
    recordingContent: TRTCAudioRecordingContent;
    maxDurationPerFile: number;
}
/**
 * 5.16 本地媒体文件的录制参数。
 *
 * 该参数用于在本地媒体文件的录制接口 {@link startLocalRecording} 中指定录制相关参数。
 * 接口 {@link startLocalRecording} 是接口 {@link startAudioRecording} 的能力加强版本，前者可以录制视频文件，后者只能录制音频文件。
 */
export declare class TRTCLocalRecordingParams {
    filePath: string;
    recordType: TRTCLocalRecordType;
    interval: number;
    maxDurationPerFile: number;
}
/**
 * 5.18 房间切换参数。
 *
 * 该参数用于切换房间接口{@link switchRoom}，可以让用户从一个房间快速切换到另一个房间。
 */
export declare class TRTCSwitchRoomConfig {
    roomId: number;
    strRoomId: string;
    userSig: string;
    privateMapKey: string;
    constructor(z24?: number, a25?: string, b25?: string, c25?: string);
}
/**
 * 5.19 音频自定义回调的格式参数。
 *
 * 该参数用于在音频自定义回调相关的接口中，设置 SDK 回调出来的音频数据的相关格式（包括采样率、声道数等）。
 */
export declare class TRTCAudioFrameCallbackFormat {
    sampleRate: number;
    channel: number;
    samplesPerCall: number;
    mode: TRTCAudioFrameOperationMode;
}
/**
 * 5.24 远端音频流智能并发播放策略的参数。
 *
 * 该参数用于设置远端音频流智能并发播放策略。
 */
export declare class TRTCAudioParallelParams {
    maxCount: number;
    includeUsers: string[];
}
/**
 * 5.25 媒体流发布相关配置的用户信息。
 *
 * 您可以通过设置该参数，配合媒体流目标发布参数 ({@link TRTCPublishTarget}) 和混流转码参数 ({@link TRTCStreamMixingConfig})，将您指定的多路音视频流进行转码并发布到您填写的目标发布地址中
 */
export declare class TRTCUser {
    userId: string;
    intRoomId: number;
    strRoomId: string;
}
/**
 * 5.26 向腾讯或者第三方 CDN 上发布音视频流时需设置的 url 配置。
 *
 * 该配置用于媒体流发布接口 {@link startPublishMediaStream} 中的目标推流配置 ({@link TRTCPublishTarget})
 */
export declare class TRTCPublishCdnUrl {
    rtmpUrl: string;
    isInternalLine: boolean;
}
/**
 * 5.27 目标推流配置。
 *
 * 该配置用于媒体流发布接口 {@link startPublishMediaStream}。
 */
export declare class TRTCPublishTarget {
    mode: TRTCPublishMode;
    cdnUrlList: TRTCPublishCdnUrl[];
    mixStreamIdentity: TRTCUser;
}
/**
 * 5.28 转码视频布局。
 *
 * 该配置用于媒体流发布接口（{@link startPublishMediaStream}）中的转码配置（{@link TRTCStreamMixingConfig}）。
 * 用于指定转码流中每一路视频画面的位置、大小、图层以及流类型等信息。
 */
export declare class TRTCVideoLayout {
    x: number;
    y: number;
    width: number;
    height: number;
    zOrder: number;
    fillMode: TRTCVideoFillMode;
    cornerRadius: number;
    backgroundColor: number;
    placeHolderImage: string;
    fixedVideoUser: TRTCUser;
    fixedVideoStreamType: TRTCVideoStreamType;
}
/**
 * 5.29 水印布局。
 *
 * 该配置用于媒体流发布接口 ({@link startPublishMediaStream}) 中的转码配置 ({@link TRTCStreamMixingConfig})
 */
export declare class TRTCWatermark {
    watermarkUrl: string;
    x: number;
    y: number;
    width: number;
    height: number;
    zOrder: number;
}
/**
 * 5.30 媒体流编码输出参数。
 *
 * 【字段含义】该配置用于媒体流发布接口（{@link startPublishMediaStream}）。
 * 【特别说明】当您的发布目标（{@link TRTCPublishTarget}）中的 mode 配置为 {@link TRTCPublishMixStreamToCdn} 或者 {@link TRTCPublishMixStreamToRoom} 时，该参数为必填。
 * 【特别说明】当您使用转推服务（mode 为 {@link TRTCPublishBigStreamToCdn} 或者 {@link TRTCPublishSubStreamToCdn}）时，为了更好的转推稳定性以及更好的 CDN 播放兼容性，也建议您填写该配置的具体参数。
 */
export declare class TRTCStreamEncoderParam {
    videoEncodedWidth: number;
    videoEncodedHeight: number;
    videoEncodedFPS: number;
    videoEncodedGOP: number;
    videoEncodedKbps: number;
    audioEncodedSampleRate: number;
    audioEncodedChannelNum: number;
    audioEncodedKbps: number;
    audioEncodedCodecType: number;
    videoEncodedCodecType: number;
    videoSeiParams: string;
}
/**
 * 5.31 媒体流转码配置参数。
 *
 * 该配置用于媒体流发布接口（{@link startPublishMediaStream}）。
 * 用于指定转码时各路画面的排版位置信息和输入的音频信息。
 */
export declare class TRTCStreamMixingConfig {
    backgroundColor: number;
    backgroundImage: string;
    videoLayoutList: TRTCVideoLayout[];
    audioMixUserList: TRTCUser[];
    watermarkList: TRTCWatermark[];
}
/**
 * 5.33 音量评估等相关参数设置。
 *
 * 该设置用于开启人声检测、声音频谱计算。
 */
export declare class TRTCAudioVolumeEvaluateParams {
    interval: number;
    enableVadDetection: boolean;
    enablePitchCalculation: boolean;
    enableSpectrumCalculation: boolean;
    constructor(interval?: number, w24?: boolean, x24?: boolean, y24?: boolean);
}
