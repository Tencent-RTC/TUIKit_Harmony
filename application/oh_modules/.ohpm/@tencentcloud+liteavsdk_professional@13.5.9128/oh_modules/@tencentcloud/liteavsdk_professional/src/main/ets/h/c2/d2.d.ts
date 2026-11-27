export declare enum p17 {
    AppletApiCodeSuccess = 0,
    AppletApiCodeInitFailed = -1,
    AppletApiCodeUnInitFailed = -2,
    AppletApiCodeUpdateFailed = -3,
    AppletApiCodeOperateFailed = -4
}
export declare enum q17 {
    AppletAudioRouteSpeakerphone = 0,
    AppletAudioRouteEarpiece = 1
}
export declare enum r17 {
    AppletPlayerModeLive = 1,
    AppletPlayerModeRtc = 2
}
/**
 * 像素格式
 */
export declare enum s17 {
    AppletPixelFormatUnknown = 0,
    AppletPixelFormatI420 = 1,
    AppletPixelFormatBGRA32 = 2,
    AppletPixelFormatRGBA32 = 3
}
export declare enum t17 {
    SnapshotError = -3,
    SdkVersion = -9999999
}
export declare class u17 {
    code: p17;
    result: string;
    constructor(code?: p17, result?: string);
}
export declare class v17 {
    d18: q17;
    playUrl: string | null;
    mode: r17;
    e18: boolean;
    f18: boolean;
    g18: boolean;
    h18: boolean;
    i18: boolean;
    j18: boolean;
    k18: number;
    l18: number;
    m18: number;
    n18: boolean;
    o18: boolean;
    constructor();
}
export declare enum w17 {
    AppletVideoMirrorTypeAuto = 0,
    AppletVideoMirrorTypeEnable = 1,
    AppletVideoMirrorTypeDisable = 2
}
export declare enum x17 {
    AppletSystemVolumeTypeAuto = 0,
    AppletSystemVolumeTypeMedia = 1,
    AppletSystemVolumeTypeVOIP = 2
}
export declare enum y17 {
    AppletVoiceReverbType_0 = 0,
    AppletVoiceReverbType_1 = 1,
    AppletVoiceReverbType_2 = 2,
    AppletVoiceReverbType_3 = 3,
    AppletVoiceReverbType_4 = 4,
    AppletVoiceReverbType_5 = 5,
    AppletVoiceReverbType_6 = 6,
    AppletVoiceReverbType_7 = 7,
    AppletVoiceReverbType_8 = 8,
    AppletVoiceReverbType_9 = 9,
    AppletVoiceReverbType_10 = 10,
    AppletVoiceReverbType_11 = 11
}
export declare enum z17 {
    AppletVoiceChangerType_0 = 0,
    AppletVoiceChangerType_1 = 1,
    AppletVoiceChangerType_2 = 2,
    AppletVoiceChangerType_3 = 3,
    AppletVoiceChangerType_4 = 4,
    AppletVoiceChangerType_5 = 5,
    AppletVoiceChangerType_6 = 6,
    AppletVoiceChangerType_7 = 7,
    AppletVoiceChangerType_8 = 8,
    AppletVoiceChangerType_9 = 9,
    AppletVoiceChangerType_10 = 10,
    AppletVoiceChangerType_11 = 11
}
export declare enum a18 {
    AudioQualityUnknown = 0,
    AudioQualitySpeech = 1,
    AudioQualityDefault = 2,
    AudioQualityMusic = 3
}
/**
 * 视频画面顺时针旋转角度
 */
export declare enum b18 {
    AppletRotation0 = 0,
    AppletRotation90 = 1,
    AppletRotation180 = 2,
    AppletRotation270 = 3
}
export declare class c18 {
    pushUrl: string | null;
    mode: number;
    p18: boolean;
    q18: boolean;
    i18: boolean;
    r18: boolean;
    s18: boolean;
    isFrontCamera: boolean;
    t18: boolean;
    u18: boolean;
    v18: boolean;
    w18: boolean;
    x18: number;
    width: number;
    height: number;
    y18: number;
    z18: number;
    fps: number;
    mirrorType: w17;
    a19: boolean;
    h18: boolean;
    b19: boolean;
    c19: boolean;
    d19: boolean;
    m18: number;
    volumeType: x17;
    e19: y17;
    f19: z17;
    g19: a18;
    beautyStyle: number;
    beautyLevel: number;
    whitenessLevel: number;
    h19: string | null;
    i19: string | null;
    j19: number;
    k19: number;
    l19: number;
    m19: string | null;
    constructor();
}
