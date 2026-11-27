import { ParamType, TXBitrateItem, TXSubtitleRenderModel, TXTrackInfo, TXVodSubtitleData, TXVodSubtitleFrameBuffer } from "../../q3/x3";
import { TXVCubePlayerConfig } from "./q4";
export interface ITXVCubePlayer {
    setDataSource(dataSource: string, headers?: Map<string, string>): void;
    setVideoRenderTarget(surfaceId: string | number): void;
    setConfig(playerConfig: TXVCubePlayerConfig): void;
    setAutoPlay(autoPlay: boolean): void;
    prepareAsync(): void;
    start(): void;
    stop(): void;
    pause(): void;
    setScreenOnWhilePlaying(screenOn: boolean): void;
    getVideoWidth(): number;
    getVideoHeight(): number;
    isPlaying(): boolean;
    seekTo(positionMs: number, isAccurateSeek?: boolean): void;
    getCurrentPosition(): number;
    getPdtTimeMs(positionMs: number): number;
    getPositionMs(pdtTimeMs: number): number;
    getDurationMs(): number;
    getPlayableDurationMs(): number;
    release(): void;
    reset(): void;
    setRate(rate: number): void;
    getRate(): number;
    setAudioVolume(volume: number): void;
    setAudioNormalization(value: number): void;
    setAutoMaxBitrate(autoMaxBitrate: number): void;
    setAudioStreamType(streamtype: number): void;
    getVideoSarNum(): number;
    getVideoSarDen(): number;
    setLooping(looping: boolean): void;
    isLooping(): boolean;
    getBitrateIndex(): number;
    setBitrateIndex(index: number): void;
    enableAdaptiveBitrate(): void;
    getSupportedBitrates(): TXBitrateItem[];
    setRenderMode(mode: number): void;
    publishAudioToNetwork(): void;
    unpublishAudioToNetwork(): void;
    publishVideoToNetwork(): void;
    unpublishVideoToNetwork(): void;
    attachTRTC(trtcCloud: Object): void;
    detachTRTC(): void;
    getPropertyLong(paramId: number): number;
    setPrivateConfig(configure: Map<string, ParamType>): void;
    addSubtitleSource(url: string, name: string, mimeType: string): void;
    addAudioTrackSource(url: string, name: string): void;
    setSubtitleStyle(renderModel: TXSubtitleRenderModel): void;
    selectTrack(trackIndex: number): void;
    deselectTrack(trackIndex: number): void;
    getTrackInfo(): TXTrackInfo[];
    checkSubtitle(): void;
    setOnGetTXCVodTargetStateCallback(targetStateObj: OnGetTXCVodTargetState | null): void;
    setOnPreparedCallback(callback: OnPreparedCallback | null): void;
    setOnCompletionCallback(callback: OnCompletionCallback | null): void;
    setOnBufferingUpdateCallback(callback: OnBufferingUpdateCallback | null): void;
    setOnSeekCompleteCallback(callback: OnSeekCompleteCallback | null): void;
    setOnVideoSizeChangedCallback(callback: OnVideoSizeChangedCallback | null): void;
    setOnErrorCallback(callback: OnErrorCallback | null): void;
    setOnInfoCallback(callback: OnInfoCallback | null): void;
    setOnSubtitleDataCallback(callback: OnSubtitleDataCallback | null): void;
    setOnSubtitleFrameDataCallback(callback: OnSubtitleFrameDataCallback | null): void;
}
/**
 * 监听器
 */
export interface OnPreparedCallback {
    onPrepared(player: ITXVCubePlayer): void;
}
export interface OnCompletionCallback {
    onCompletion(player: ITXVCubePlayer): void;
}
export interface OnBufferingUpdateCallback {
    onBufferingUpdate(player: ITXVCubePlayer, percent: number): void;
}
export interface OnSeekCompleteCallback {
    onSeekComplete(player: ITXVCubePlayer): void;
}
export interface OnVideoSizeChangedCallback {
    onVideoSizeChanged(player: ITXVCubePlayer, width: number, height: number, sarNumerator: number, sarDenominator: number, crop: string): void;
}
export interface OnErrorCallback {
    onError(player: ITXVCubePlayer, what: number, extra: number): void;
}
export interface OnInfoCallback {
    onInfo(player: ITXVCubePlayer, what: number, arg1?: number, arg2?: number, extra?: Map<string, ParamType>): void;
}
export interface OnSubtitleDataCallback {
    onSubtitleData(player: ITXVCubePlayer, subtitleData: TXVodSubtitleData): void;
}
export interface OnGetTXCVodTargetState {
    getTargetState(): number;
}
export interface OnSubtitleFrameDataCallback {
    onReceiveSubtitleFrameData(player: ITXVCubePlayer, subtitleFrameBuffer: TXVodSubtitleFrameBuffer): void;
}
