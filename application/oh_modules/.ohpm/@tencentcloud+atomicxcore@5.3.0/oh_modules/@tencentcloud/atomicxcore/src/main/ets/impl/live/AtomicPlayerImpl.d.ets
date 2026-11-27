/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicPlayerImpl @ AtomicXCore
 */
import image from "@ohos.multimedia.image";
import { IAtomicPlayerImpl, PlayerListener, PlayerRenderRotation, PlayerState } from '../../api/live/AtomicPlayer';
import { AtomicLiveView } from '../../api/view/live/AtomicLiveView';
export declare class AtomicPlayerImpl implements IAtomicPlayerImpl {
    private readonly state;
    private readonly listeners;
    private view;
    private liveID;
    private eventToken;
    private stateToken;
    constructor();
    private ensureSubscribed;
    private static subscribeWeakly;
    private safeCall;
    getState(): PlayerState;
    addListener(listener?: PlayerListener): void;
    removeListener(listener?: PlayerListener): void;
    setView(view: AtomicLiveView): void;
    startPlay(url: string): void;
    stopPlay(): void;
    joinChannel(liveID: string): Promise<void>;
    leaveChannel(): void;
    setVolume(volume: number): void;
    switchStream(url: string): Promise<void>;
    setRenderRotation(rotation: PlayerRenderRotation): void;
    snapshot(callback?: (pixelMap: image.PixelMap | undefined) => void): void;
    /**
     * Requests a snapshot and decodes it, resolving to undefined on any
     * failure (call error, empty payload or decode error).
     */
    private takeSnapshot;
    enableReceiveSeiMessage(enable: boolean, payloadType: number): void;
    enableAdvancedFeature(key: string, value: Object): void;
    private static advancedFeatureParam;
    /**
     * Resolves the live id carried by a `livekit://liveid=<id>` style url,
     * mirroring `resolveLiveID` on iOS / Android.
     */
    private resolveLiveID;
    private updateLiveID;
    /**
     * Binds the live ID to the render view. `setLiveID` is SDK-internal on the
     * controller (mirrors Android, where it is an `internal` API).
     */
    private bindView;
    private onModuleEvent;
    private onModuleStateChanged;
    /**
     * Parses a JSON object payload. Mirrors `as? [String: Any]` on iOS and
     * `as? Map` on Android: any non-object payload is dropped.
     */
    private parseObject;
    /** Reads a nested object, mirroring the checked casts on iOS / Android. */
    private recordOf;
    /** Reads a number field with a runtime type check (`as?` equivalent). */
    private numberOf;
    /** Reads a string field with a runtime type check (`as?` equivalent). */
    private stringOf;
    private base64ToUint8Array;
    private base64ToArrayBuffer;
    private decodeBase64PixelMap;
    private mapToPlayerStatistics;
    private static statisticsEquals;
    private playerCodeFromValue;
    private playbackStatusFromValue;
    private endedReasonFromValue;
    private kickedOutReasonFromValue;
}
