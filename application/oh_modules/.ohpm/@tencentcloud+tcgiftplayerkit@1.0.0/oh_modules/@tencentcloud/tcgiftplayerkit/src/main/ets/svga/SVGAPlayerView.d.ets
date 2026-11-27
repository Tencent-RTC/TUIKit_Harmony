// @keepTs
// @ts-nocheck
import { SVGAMovie } from './SVGAMovie';
export declare class SVGAPlayer {
    private isMounted;
    private context?;
    private maskContext?;
    private width;
    private height;
    private movie?;
    private matteSprites;
    private onStarted?;
    private onFinished?;
    private isStarted;
    private sync?;
    private startTime;
    private renderedFrame;
    private drawSequence;
    private decodedImages;
    private decodedBytes;
    get isAttached(): boolean;
    mount(): void;
    unmount(): void;
    attach(f: CanvasRenderingContext2D): void;
    resize(d: number, e: number): void;
    play(a: SVGAMovie, b: () => void, c: (failed: boolean) => void): void;
    stop(): void;
    private startIfReady;
    private tick;
    private draw;
    private drawSprite;
    private drawFrame;
    private resetContext;
    private offscreenContext;
    private decodedImage;
    private evictDecodedImages;
    private releaseDecodedImages;
    private clearCanvas;
}
@Component
export declare struct SVGAPlayerView {
    player?: SVGAPlayer;
    private readonly settings;
    private readonly context;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    build(): void;
}
