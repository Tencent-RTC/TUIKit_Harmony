// @keepTs
// @ts-nocheck
import image from "@ohos.multimedia.image";
import { SVGAParsedMovie, SVGAParsedSprite } from './SVGAProtoParser';
export declare class SVGASprite {
    readonly imageKey: string;
    readonly matteKey: string;
    readonly frames: Float32Array;
    readonly frameCount: number;
    constructor(i1: SVGAParsedSprite);
}
export declare class SVGAMovie {
    readonly width: number;
    readonly height: number;
    readonly fps: number;
    readonly frameCount: number;
    readonly sprites: SVGASprite[];
    private encodedImages;
    private imageSources;
    private unavailableKeys;
    private isDisposed;
    static load(h1: string): Promise<SVGAMovie>;
    constructor(g1: SVGAParsedMovie);
    hasImage(f1: string): boolean;
    imageSource(e1: string): image.ImageSource | undefined;
    markUnavailable(d1: string): void;
    dispose(): void;
}
