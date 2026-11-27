import { q10, r10 } from "./m1";
type s10 = string;
export declare enum t10 {
    AUDIO = 0,
    VIDEO = 1
}
export declare enum u10 {
    UNKNOWN = 0,
    LOCAL_HANGUP = 1,
    REMOTE_HANGUP = 2,
    CALL_PERMISSION_DENIED = 3,
    NETWORK_ERROR = 4
}
export declare enum v10 {
    SPEAKER_PHONE = 0,
    EAR_PIECE = 1
}
export declare enum w10 {
    FRONT = 0,
    BACK = 1
}
export declare class x10 {
    deviceId: q10;
}
export declare enum y10 {
    EXCELLENT = 0,
    GOOD = 1,
    POOR = 2,
    BAD = 3,
    VERY_BAD = 4,
    DOWN = 5
}
export declare class z10 {
    callUser: x10;
    quality: y10;
}
export interface a11 {
    onError?: (code: r10, msg: string) => void;
    c11?: (mediaType: t10) => void;
    d11?: (mediaType: t10, reason: u10) => void;
    e11?: (callUser: x10) => void;
    f11?: (callUser: x10) => void;
    g11?: (callUser: x10) => void;
    h11?: (callUser: x10) => void;
    i11?: (callUser: x10, available: boolean) => void;
    j11?: (callUser: x10, available: boolean) => void;
    k11?: (localQuality: z10, remoteQualityList: z10[]) => void;
}
export interface b11 {
    addListener(listener: a11): void;
    removeListener(listener: a11): void;
    callDevice(deviceId: q10, callType: t10): void;
    hangup(): void;
    startRemoteView(callUser: x10, view: s10): void;
    stopRemoteView(callUser: x10): void;
    openMicrophone(): void;
    closeMicrophone(): void;
    openCamera(camera: w10, view: s10): void;
    closeCamera(): void;
    switchCamera(camera: w10): void;
    selectAudioPlaybackDevice(device: v10): void;
}
export {};
