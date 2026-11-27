// @keepTs
// @ts-nocheck
export declare const svgaFrameStride: number;
export interface SVGAParsedSprite {
    imageKey: string;
    matteKey: string;
    frames: Float32Array;
}
export interface SVGAParsedMovie {
    width: number;
    height: number;
    fps: number;
    frameCount: number;
    sprites: SVGAParsedSprite[];
    images: Record<string, ArrayBuffer>;
}
export declare function decodeSVGAFile(j1: string): Promise<SVGAParsedMovie>;
