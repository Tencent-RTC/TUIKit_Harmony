import image from "@ohos.multimedia.image";
import { q10, r10 } from "./m1";
type s10 = string;
export declare enum n13 {
    HD = 0,
    SD = 1
}
export declare enum o13 {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3,
    ZOOM_IN = 4,
    ZOOM_OUT = 5,
    STOP = 6
}
export declare enum p13 {
    PLAYING = 0,
    LOADING = 1,
    STOPPED = 2
}
export declare enum q13 {
    RESOLUTION_640_360 = 0,
    RESOLUTION_960_540 = 1,
    RESOLUTION_1280_720 = 2,
    RESOLUTION_1920_1080 = 3,
    RESOLUTION_360_640 = 4,
    RESOLUTION_540_960 = 5,
    RESOLUTION_720_1280 = 6,
    RESOLUTION_1080_1920 = 7
}
export declare class r13 {
    resolution: q13;
}
export declare class s13 {
    filePath: string;
}
export interface t13 {
    onError?: (channelId: number, errCode: r10, errMsg: string) => void;
    u13?: () => void;
    v13?: () => void;
    w13?: () => void;
    x13?: (channelId: number, available: boolean) => void;
    y13?: (channelId: number) => void;
    z13?: (channelId: number, state: p13) => void;
    onSnapshotComplete?: (channelId: number, image: image.PixelMap | null, errCode: r10) => void;
    onLocalRecordBegin?: (channelId: number, errCode: r10, storagePath: string) => void;
    onLocalRecording?: (channelId: number, durationMs: number, storagePath: string) => void;
    onLocalRecordComplete?: (channelId: number, errCode: r10, storagePath: string) => void;
}
export interface j12 {
    addListener(listener: t13): void;
    removeListener(listener: t13): void;
    startSession(deviceId: q10): void;
    stopSession(): void;
    startRemoteView(channelId: number, streamType: n13, view: s10): void;
    stopRemoteView(channelId: number): void;
    switchRemoteStream(channelId: number, streamType: n13): void;
    muteRemoteAudio(channelId: number, mute: boolean): void;
    muteAllRemoteAudio(mute: boolean): void;
    startLocalAudio(): void;
    stopLocalAudio(): void;
    muteLocalAudio(mute: boolean): void;
    startLocalVideo(view: s10, videoEncoderParams: r13): void;
    stopLocalVideo(): void;
    sendPTZCommand(channelId: number, command: o13, speed: number): void;
    takeSnapshot(channelId: number): void;
    startLocalRecording(channelId: number, params: s13): void;
    stopLocalRecording(channelId: number): void;
}
export {};
