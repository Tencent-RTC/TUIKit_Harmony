// @keepTs
// @ts-nocheck
import { TCGiftPlaybackEvent, TCGiftSVGABackend } from './TCGiftPlaybackBackend';
import { TCGiftPreparationResult, TCGiftPreparationTask, TCGiftPreparedResource } from './TCGiftPreparedResource';
export declare class TCGiftPlayer {
    readonly svgaBackend: TCGiftSVGABackend;
    private assets;
    private preparation?;
    private activeBackend?;
    private currentLease?;
    private requestID;
    private onEvent?;
    private hasStarted;
    prepare(v1: string, w1: (result: TCGiftPreparationResult) => void): TCGiftPreparationTask;
    play(t1: TCGiftPreparedResource, u1: (event: TCGiftPlaybackEvent) => void): void;
    playURL(r1: string, s1: (event: TCGiftPlaybackEvent) => void): void;
    stop(): void;
    private begin;
    private start;
    private receive;
}
@Component
export declare struct TCGiftPlayerView {
    player?: TCGiftPlayer;
    build(): void;
}
