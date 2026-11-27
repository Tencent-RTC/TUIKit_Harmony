import { ITXChorusMusicPlayer, ITXChorusPlayerEventCallback, TXChorusRole, TXChorusMusicTrack, TXChorusCopyrightedMusicParams, TXChorusExternalMusicParams, TXChorusYsdMusicParams } from "./c3";
import { TRTCParams } from "./y2";
export declare class TXChorusMusicPlayerImpl implements ITXChorusMusicPlayer {
    private nativePlayer;
    static New(t27: number, u27: string, callback: ITXChorusPlayerEventCallback): ITXChorusMusicPlayer;
    private constructor();
    setChorusRole(role: TXChorusRole, q27: TRTCParams): void;
    loadMusic(params: TXChorusCopyrightedMusicParams): void;
    loadExternalMusic(params: TXChorusExternalMusicParams): void;
    loadYsdMusic(params: TXChorusYsdMusicParams): void;
    start(): void;
    stop(): void;
    pause(): void;
    resume(): void;
    seek(p27: number): void;
    switchMusicTrack(o27: TXChorusMusicTrack): void;
    setPlayoutVolume(volume: number): void;
    setPublishVolume(volume: number): void;
    setMusicPitch(pitch: number): void;
    callExperimentalAPI(n27: string): void;
    destroy(): void;
}
