import { Context } from '@ohos.abilityAccessCtrl';
import { TXCopyrightedMedia, ITXSongScore, TXSongScoreNoteItem } from "./b3";
import { ITXMusicPreloadCallback, TXClimaxTimeRange, ITXSongScoreCallback } from "./b3";
import w27 from 'libliteavsdk.so';
export declare class TXCopyrightedMediaImpl implements TXCopyrightedMedia {
    private TXCopyrightedMediaNativeImpl;
    static New(): TXCopyrightedMedia;
    static Destroy(d29: TXCopyrightedMedia): void;
    private constructor();
    setLicense(context: Context, c29: string, key: string): void;
    genMusicURI(z28: string, a29: number, b29: string): string;
    setMusicPreloadCallback(callback: ITXMusicPreloadCallback): void;
    preloadMusic(w28: string, x28: string, y28: string): void;
    preloadClimaxSegment(t28: string, u28: string, v28: string): void;
    preloadPitchAndLyricFile(q28: string, r28: string, s28: string): void;
    getClimaxSegmentTimeRange(n28: string, o28: number, p28: string): TXClimaxTimeRange;
    cancelPreloadMusic(l28: string, m28: string): void;
    isMusicPreload(j28: string, k28: string): boolean;
    clearMusicCache(): void;
    clearMusicCacheByMusicId(h28: string, i28: string): void;
    setMusicCacheMaxCount(maxCount: number): void;
    createSongScore(d28: string, sampleRate: number, channel: number, e28: string, f28: string, g28: string): ITXSongScore;
}
export declare class TXSongScoreImpl implements ITXSongScore {
    private TXCopyrightedSongScoreNativeImpl;
    constructor(y27: w27.TXCopyrightedMediaNapi, z27: string, sampleRate: number, channel: number, a28: string, b28: string, c28: string);
    setSongScoreCallback(callback: ITXSongScoreCallback): void;
    prepare(): void;
    finish(): void;
    process(x27: ArrayBuffer, timeStamp: number): void;
    setKeyShift(shiftKey: number): void;
    calculateTotalScore(): number;
    getAllGrove(): Array<TXSongScoreNoteItem>;
    destroy(): void;
}
