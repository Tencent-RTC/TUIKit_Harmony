/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicPlayer @ AtomicXCore
 * Function: Atomic player related interfaces, managing video stream playback, render view binding, and player event listening for low-latency live streaming and CDN streams.
 */
import image from "@ohos.multimedia.image";
import { AtomicLiveView } from '../view/live/AtomicLiveView';
/**
 * Delegate interface consumed by [AtomicPlayer]. The implementation module
 * (impl/live/AtomicPlayerImpl.ets) implements it and registers a factory via
 * [registerPlayerImplFactory]; the api layer itself never imports the
 * implementation, keeping the dependency graph acyclic.
 */
export interface IAtomicPlayerImpl {
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
    enableReceiveSeiMessage(enable: boolean, payloadType: number): void;
    enableAdvancedFeature(key: string, value: Object): void;
}
/**
 * Register the player impl factory. Called by the internal implementation
 * module when it is loaded; business code never needs to call this.
 */
export declare function registerPlayerImplFactory(factory: () => IAtomicPlayerImpl): void;
/**
 * Atomic player error code enumeration, used to report the result of player operations and runtime errors.
 */
export declare enum PlayerCode {
    /**
     * No error, operation succeeded.
     */
    OK = 0,
    /**
     * Invalid parameter.
     */
    ERROR_INVALID_PARAMETER = -1001
}
/**
 * Status of the player, reflecting the current playback lifecycle.
 *
 * State machine (typical transitions):
 * ```
 *                   startPlay
 *     IDLE ──────────────────▶ LOADING
 *       ▲                         │
 *       │                   play succeeded
 *   stopPlay                          │
 *    connection lost                  │
 *       │                         ▼
 *       │◀─────────────────────PLAYING ◀────────────────┐
 *       │                         │                     │
 *       │                         │                     │
 *       │                     buffering         recover succeeded
 *       │                         │                     │
 *       │                         ▼                     │
 *       └──────────────────────LOADING ─────────────────┘
 *
 * ```
 *
 * > **Tip**: `IDLE` is the initial state; it is also returned to after calling `stopPlay`.
 * > The buffering / auto-recovery process reuses `LOADING`, without distinguishing "first loading" from "re-buffering".
 */
export declare enum PlayerPlaybackStatus {
    /**
     * Idle. Initial state, or playback stopped / connection lost.
     */
    IDLE = 0,
    /**
     * Loading. Establishing the connection or buffering data; the video has not started or is temporarily stalled.
     */
    LOADING = 1,
    /**
     * Playing. The link is normal and the video is playing smoothly.
     */
    PLAYING = 2
}
/**
 * Render rotation angle of the video.
 */
export declare enum PlayerRenderRotation {
    /**
     * No rotation.
     */
    ROTATION_0 = 0,
    /**
     * Rotated 90 degrees clockwise.
     */
    ROTATION_90 = 1,
    /**
     * Rotated 180 degrees clockwise.
     */
    ROTATION_180 = 2,
    /**
     * Rotated 270 degrees clockwise.
     */
    ROTATION_270 = 3
}
/**
 * The reason the live ended.
 */
export declare enum EndedReason {
    /**
     * Actively ended by the host.
     */
    ENDED_BY_HOST = 0,
    /**
     * Ended by the server.
     */
    ENDED_BY_SERVER = 1
}
/**
 * The reason the local end is kicked out of the live room.
 */
export declare enum KickedOutReason {
    /**
     * Kicked out by an admin.
     */
    BY_ADMIN = 0,
    /**
     * Logged in on another device.
     */
    BY_LOGGED_ON_OTHER_DEVICE = 1,
    /**
     * Kicked out by the server.
     */
    BY_SERVER = 2,
    /**
     * Network disconnected.
     */
    FOR_NETWORK_DISCONNECTED = 3,
    /**
     * The live channel expired.
     */
    FOR_LIVE_CHANNEL_EXPIRED = 4
}
/**
 * Player event listener, used to receive one-shot events such as SEI data, playback errors, live ended, kicked out, etc. Register/remove listeners via `addListener` / `removeListener`.
 */
export declare class PlayerListener {
    seiReceived?: (data: Uint8Array) => void;
    playerError?: (code: PlayerCode, message: string) => void;
    liveEnded?: (reason: EndedReason) => void;
    kickedOut?: (reason: KickedOutReason, message: string) => void;
    constructor(seiReceived?: (data: Uint8Array) => void, playerError?: (code: PlayerCode, message: string) => void, liveEnded?: (reason: EndedReason) => void, kickedOut?: (reason: KickedOutReason, message: string) => void);
}
/**
 * Atomic player runtime statistics, containing real-time runtime metrics of an active player.
 */
export declare class PlayerStatistics {
    /**
     * Video width in pixels.
     */
    videoWidth: number;
    /**
     * Video height in pixels.
     */
    videoHeight: number;
    /**
     * Video frame rate in fps.
     */
    videoFps: number;
    /**
     * Video bitrate in bps.
     */
    videoBitrate: number;
    /**
     * Audio bitrate in bps.
     */
    audioBitrate: number;
}
/**
 * Atomic player reactive state. Carries the state of AtomicPlayer. You can read the current value or observe changes via `state`.
 */
@Observed
export declare class PlayerState {
    /**
     * Playback status. Reflects the current playback lifecycle.
     */
    playbackStatus: PlayerPlaybackStatus;
    /**
     * Playback runtime statistics, delivered periodically by the SDK.
     */
    statistics: PlayerStatistics;
    /**
     * Total viewer count.
     */
    totalViewerCount: number;
}
/**
 * Atomic player related interfaces, managing video stream playback, render view binding, and player event listening for low-latency live streaming and CDN streams.
 *
 * `AtomicPlayer` AtomicPlayer provides live streaming playback (downstream) capabilities, including stream pulling, render view binding, playback state management, and event callbacks.
 * `AtomicPlayer` manages video stream playback for low-latency live streaming and CDN streams.
 *
 * The render view is bound at runtime via `setView`; the video frames will be rendered into the given `AtomicLiveView` container. This binding is decoupled from the view's window-attachment timing: it is safe to call `setView` before the view is attached to a window (e.g. inside UICollectionView cells or RecyclerView), the binding will be completed automatically once the view is ready.
 *
 * Key Features:
 * - Stream pulling and playback (`startPlay` / `stopPlay`)
 * - Render view binding and rotation mode control (`setView` / `setRenderRotation`)
 * - Channel join and leave (`joinChannel` / `leaveChannel`)
 * - Playback control (`switchStream`)
 * - SEI message receiving (`enableReceiveSeiMessage`)
 * - Playback state and statistics (`state` real-time state, `PlayerStatistics` statistics)
 * - Event callbacks (SEI data, errors, live ended, kicked out, etc. via `playerEvent` on Swift or `addListener` on Kotlin)
 *
 * ### Key Features
 *
 * - **PlayerState**: Playback state, including playback lifecycle state and statistics.
 * - **PlayerEvent**: Player event callbacks, including SEI receiving, playback errors, live ended, kicked out, and other event types.
 *
 * ###
 *
 * ###
 *
 * ###
 *
 * @see AtomicPusher
 * @see AtomicLiveView
 */
export declare class AtomicPlayer {
    private impl;
    constructor();
    getState(): PlayerState;
    /**
     * Add player event callback listener.
     *
     * @param listener Listener.
     */
    addListener(listener?: PlayerListener): void;
    /**
     * Remove player event callback listener.
     *
     * @param listener Listener.
     */
    removeListener(listener?: PlayerListener): void;
    /**
     * Set the render view. The video frames will be rendered into the given `AtomicLiveView` container. This binding is decoupled from the view's window-attachment timing: it is safe to call this before the view is attached to a window (e.g. inside UICollectionView cells or RecyclerView), the binding will be completed automatically once the view is ready.
     *
     * @param view Render view container.
     */
    setView(view: AtomicLiveView): void;
    /**
     * Start playing the remote stream specified by URL. Calling this method on an already-playing instance will stop the previous stream and play the new one.
     *
     * @param url Stream URL.
     */
    startPlay(url: string): void;
    /**
     * Stop playback.
     */
    stopPlay(): void;
    /**
     * Join channel.
     *
     * On failure the returned promise is rejected with an `ErrorInfo` carrying `code` and `message`, so callers must handle the failure branch with `.catch`.
     *
     * @param liveID Live ID.
     */
    joinChannel(liveID: string): Promise<void>;
    /**
     * Leave channel.
     */
    leaveChannel(): void;
    /**
     * Set playback volume.
     *
     * @param volume Volume level, with a value range from 0 to 100; values outside the range will be clamped.
     */
    setVolume(volume: number): void;
    /**
     * Seamlessly switch to a new stream URL without tearing down the current render view. Suitable for quality switching (such as 720p → 1080p) and CDN line failover.
     *
     * On failure the returned promise is rejected with an `ErrorInfo` carrying `code` and `message`, so callers must handle the failure branch with `.catch`.
     *
     * @param url New stream URL.
     */
    switchStream(url: string): Promise<void>;
    /**
     * Set render rotation angle.
     *
     * @param rotation Render rotation angle.
     */
    setRenderRotation(rotation: PlayerRenderRotation): void;
    /**
     * Capture the current video frame.
     *
     * @param callback Snapshot result callback. The image is undefined if the snapshot fails.
     */
    snapshot(callback?: (pixelMap: image.PixelMap | undefined) => void): void;
    /**
     * Enable or disable receiving SEI messages. When enabled, SEI data embedded in the video stream will be delivered via the `PlayerEvent.seiReceived` event.
     *
     * @param enable Whether to enable SEI message receiving.
     * @param payloadType SEI payload type to filter. Common values: 243 (custom layout), 100 (volume layout), 245 (ASR message).
     */
    enableReceiveSeiMessage(enable: boolean, payloadType: number): void;
    /**
     * Enable an advanced feature by key-value pair. Supported keys depend on the underlying native player capability and may evolve over versions.
     *
     * @param key Feature key.
     * @param value Feature value, type depends on the specific key.
     */
    enableAdvancedFeature(key: string, value: Object): void;
}
