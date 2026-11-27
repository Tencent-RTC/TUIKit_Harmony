// @keepTs
// @ts-nocheck
import { SVGAPlayer } from './svga/SVGAPlayerView';
import { TCGiftPlayerError, TCGiftPlayerErrorCode, TCGiftPreparedAsset } from './TCGiftPreparedResource';
export declare enum TCGiftPlaybackEventType {
    started = 0,
    finished = 1,
    failed = 2
}
export declare class TCGiftPlaybackEvent {
    readonly type: TCGiftPlaybackEventType;
    readonly error?: TCGiftPlayerError;
    constructor(p1: TCGiftPlaybackEventType, q1?: TCGiftPlayerError);
    static failed(o1: TCGiftPlayerErrorCode): TCGiftPlaybackEvent;
}
export interface TCGiftPlaybackBackend {
    play(asset: TCGiftPreparedAsset, onEvent: (event: TCGiftPlaybackEvent) => void): void;
    stop(): void;
}
export declare class TCGiftSVGABackend implements TCGiftPlaybackBackend {
    readonly player: SVGAPlayer;
    play(m1: TCGiftPreparedAsset, n1: (event: TCGiftPlaybackEvent) => void): void;
    stop(): void;
}
