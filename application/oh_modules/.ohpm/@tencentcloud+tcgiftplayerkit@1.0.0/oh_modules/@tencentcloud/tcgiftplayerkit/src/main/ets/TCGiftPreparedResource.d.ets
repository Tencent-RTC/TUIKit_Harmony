// @keepTs
// @ts-nocheck
import { SVGAMovie } from './svga/SVGAMovie';
export declare enum TCGiftPlayerErrorCode {
    invalidResourceURL = 1,
    unsupportedFormat = 2,
    missingFile = 3,
    invalidResponse = 4,
    downloadFailed = 5,
    unmountedView = 6,
    svgaParseFailed = 7,
    svgaPlaybackFailed = 8
}
export declare class TCGiftPlayerError extends Error {
    readonly code: TCGiftPlayerErrorCode;
    constructor(c1: TCGiftPlayerErrorCode);
    static from(a1: Object, b1: TCGiftPlayerErrorCode): TCGiftPlayerError;
}
export declare class TCGiftPreparationTask {
    private cancelled;
    private completed;
    private cancelHandler?;
    get isCancelled(): boolean;
    cancel(): void;
    onCancel(z: () => void): void;
    deliver(x: () => void, y?: () => void): void;
}
export declare class TCGiftResolvedURL {
    readonly isLocal: boolean;
    readonly location: string;
    readonly pathExtension: string;
    constructor(u: boolean, v: string, w: string);
}
export declare class TCGiftResourceTask {
    readonly result: Promise<string>;
    private download?;
    constructor(s: Promise<string>, t?: TCGiftResourceDownload);
    cancel(): void;
}
export declare class TCGiftResourceLoader {
    static resolve(r: string): TCGiftResolvedURL;
    static load(q: TCGiftResolvedURL): TCGiftResourceTask;
}
declare class TCGiftResourceDownload {
    private static pending;
    readonly result: Promise<string>;
    private consumers;
    private cancelled;
    private session?;
    private rejectCancellation?;
    private cancellation;
    static task(p: TCGiftResolvedURL): TCGiftResourceTask;
    constructor(o: TCGiftResolvedURL);
    retain(): void;
    release(): void;
    private abort;
    private checkActive;
    private load;
}
export declare class TCGiftPreparedAsset {
    readonly resourceURL: string;
    readonly ready: Promise<SVGAMovie>;
    private movieValue?;
    private leases;
    private disposed;
    private failed;
    private download?;
    private readonly onDispose;
    constructor(l: string, m: TCGiftResolvedURL, n: (asset: TCGiftPreparedAsset) => void);
    get isReusable(): boolean;
    get movie(): SVGAMovie | undefined;
    retainLease(): void;
    releaseLease(): void;
}
export declare class TCGiftAssetLease {
    private assetValue?;
    constructor(k: TCGiftPreparedAsset);
    get asset(): TCGiftPreparedAsset | undefined;
    release(): void;
}
export declare class TCGiftPreparedResource {
    readonly resourceURL: string;
    private lease;
    constructor(i: string, j: TCGiftAssetLease);
    makeLease(): TCGiftAssetLease | undefined;
    release(): void;
}
export declare class TCGiftPreparationResult {
    readonly resource?: TCGiftPreparedResource;
    readonly error?: TCGiftPlayerError;
    constructor(g?: TCGiftPreparedResource, h?: TCGiftPlayerError);
}
export {};
