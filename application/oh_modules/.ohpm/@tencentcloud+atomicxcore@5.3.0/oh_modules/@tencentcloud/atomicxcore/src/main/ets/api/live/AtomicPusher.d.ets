/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicPusher @ AtomicXCore
 * Function: AtomicPusher main interface, providing local audio/video capture and push (streaming) capabilities.
 */
import { EndedReason, KickedOutReason } from './AtomicPlayer';
import { AtomicLiveView } from '../view/live/AtomicLiveView';
/**
 * Delegate interface consumed by [AtomicPusher]. The implementation module
 * (impl/live/AtomicPusherImpl.ets) implements it and registers a factory via
 * [registerPusherImplFactory]; the api layer itself never imports the
 * implementation, keeping the dependency graph acyclic.
 */
export interface IAtomicPusherImpl {
    getState(): PusherState;
    addListener(listener?: PusherListener): void;
    removeListener(listener?: PusherListener): void;
    setView(view: AtomicLiveView): void;
    startPush(config: PusherInfo): void;
    stopPush(): void;
    updateConfig(config: PusherInfo, modifyFlagList: Array<PusherInfoModifyFlag>): void;
    enableAdvancedFeature(key: string, value: Object): void;
    release(): void;
}
/**
 * Register the pusher impl factory. Called by the internal implementation
 * module when it is loaded; business code never needs to call this.
 */
export declare function registerPusherImplFactory(factory: () => IAtomicPusherImpl): void;
/**
 * Atomic pusher error code enum, used to report push operation results and runtime errors.
 */
export declare enum PusherCode {
    /**
     * No error, operation succeeded.
     */
    OK = 0,
    /**
     * Invalid parameter.
     */
    ERROR_INVALID_PARAMETER = -1,
    /**
     * The operation is not allowed in the current state (e.g. startPush again while pushing, updateConfig before startPush).
     */
    ERROR_INVALID_STATE = -2,
    /**
     * The startPush request chain failed (server / signaling / TRTC). See message for details.
     */
    ERROR_START_PUSH_REQUEST_FAILED = -3,
    /**
     * The updateConfig request chain failed (server / signaling). See message for details.
     */
    ERROR_UPDATE_CONFIG_REQUEST_FAILED = -4
}
/**
 * The connection state between the pusher and the push target.
 *
 * State machine (typical transitions):
 * ```
 *                     startPush
 *   DISCONNECTED ─────────────▶ CONNECTING
 *       ▲                           │
 *       │                           │ join/push succeeded
 *       │                           ▼
 *       │                       CONNECTED
 *       │                           │
 *       │            network jitter / dropped, SDK auto-reconnects
 *       │                           ▼
 *       │                       CONNECTING
 *       │                           │
 *       │    reconnect succeeded ─▶ CONNECTED
 *       └─────  reconnect failed / stopPush / release
 * ```
 *
 * > Note: `DISCONNECTED` is the initial state; it is also returned to after calling `stopPush` / `release`.
 * > The auto-reconnect process reuses `CONNECTING`, without distinguishing "first connection" from "reconnecting".
 */
export declare enum PusherConnectState {
    /**
     * Not connected. Initial state, or after actively stopping the push / final reconnect failure.
     */
    DISCONNECTED = 0,
    /**
     * Establishing connection. Used for both the first room-join handshake and auto-reconnect after a disconnection.
     */
    CONNECTING = 1,
    /**
     * Connected, the push link is normal.
     */
    CONNECTED = 2
}
/**
 * Fields that can be updated via `updateConfig`.
 *
 * Each flag is a bit value aligned with the underlying engine's field flags, so the raw values are
 * intentionally non-contiguous (bits used by unrelated fields are skipped).
 */
export declare enum PusherInfoModifyFlag {
    /**
     * Update the live name.
     */
    LIVE_NAME = 1,
    /**
     * Update the notice.
     */
    NOTICE = 2,
    /**
     * Update whether the live is publicly visible.
     */
    IS_PUBLIC_VISIBLE = 32,
    /**
     * Update the cover URL.
     */
    COVER_URL = 128,
    /**
     * Update the background URL.
     */
    BACKGROUND_URL = 256,
    /**
     * Update the category list.
     */
    CATEGORY_LIST = 512,
    /**
     * Update the custom metadata.
     */
    META_DATA = 4096
}
/**
 * Pusher event listener, used to receive one-shot events such as push errors, live ended, kicked out, etc. Register/remove listeners via `addListener` / `removeListener`.
 */
export declare class PusherListener {
    pusherError?: (code: PusherCode, message: string) => void;
    liveEnded?: (reason: EndedReason, summary: PusherSummary | undefined) => void;
    kickedOut?: (reason: KickedOutReason, message: string) => void;
    constructor(pusherError?: (code: PusherCode, message: string) => void, liveEnded?: (reason: EndedReason, summary: PusherSummary | undefined) => void, kickedOut?: (reason: KickedOutReason, message: string) => void);
}
/**
 * Statistics data of this live session, reported when the live ends. Used to display summarized data such as views, interactions, and gifts.
 */
export declare class PusherSummary {
    /**
     * Cumulative view count.
     */
    totalViewers: number;
    /**
     * Total number of gifts sent.
     */
    totalGiftsSent: number;
    /**
     * Total gift amount.
     */
    totalGiftCoins: number;
    /**
     * Number of gift senders.
     */
    totalUniqueGiftSenders: number;
    /**
     * Total likes.
     */
    totalLikesReceived: number;
    /**
     * Total messages.
     */
    totalMessageCount: number;
    /**
     * Live duration (seconds).
     */
    liveDuration: number;
}
/**
 * Pusher runtime statistics.
 *
 * Periodically called back by the SDK to the upper layer, used to display push quality or for troubleshooting.
 */
export declare class PusherStatistics {
    /**
     * Video width (pixels).
     */
    videoWidth: number;
    /**
     * Video height (pixels).
     */
    videoHeight: number;
    /**
     * Video frame rate (fps).
     */
    videoFps: number;
    /**
     * Video bitrate (bps).
     */
    videoBitrate: number;
    /**
     * Audio bitrate (bps).
     */
    audioBitrate: number;
    /**
     * Network round-trip time (milliseconds).
     */
    rtt: number;
    /**
     * Network packet loss rate (percentage).
     */
    packetLossRate: number;
}
/**
 * Atomic pusher reactive state. Carries the state of AtomicPusher. You can read the current value or subscribe to changes via `state`.
 */
@Observed
export declare class PusherState {
    /**
     * Connection state.
     */
    networkState: PusherConnectState;
    /**
     * Pusher runtime statistics.
     */
    statistics: PusherStatistics;
    /**
     * Pusher live room info.
     */
    pusherInfo: PusherInfo;
    /**
     * Total viewer count.
     */
    totalViewerCount: number;
}
/**
 * Pusher live room info. Used both as the input parameter of `startPush` / `updateConfig`, and carried in `state.pusherInfo` as the live room info returned from the engine.
 */
export declare class PusherInfo {
    /**
     * Live ID.
     */
    liveID: string;
    /**
     * Live name.
     */
    liveName: string;
    /**
     * Cover URL.
     */
    coverURL: string;
    /**
     * Background URL.
     */
    backgroundURL: string;
    /**
     * Notice.
     */
    notice: string;
    /**
     * Create time.
     */
    createTime: number;
    /**
     * Category list.
     */
    categoryList: Array<number>;
    /**
     * Whether publicly visible.
     */
    isPublicVisible: boolean;
    /**
     * Custom metadata.
     */
    metaData: Map<string, string>;
}
/**
 * AtomicPusher main interface, providing local audio/video capture and push (streaming) capabilities.
 *
 * `AtomicPusher` AtomicPusher provides live streaming push (upstream) capabilities, including local audio/video capture, push state management, and event callbacks.
 * Typical usage flow: bind the preview view via `AtomicPusher.shared().setView(view)`, start pushing via `startPush(config)`, monitor `getState()` for state changes, and release resources via `release()`.
 *
 * ### Key Features
 *
 * - **PusherState**: Real-time pusher state, including connection state, statistics, and live room info.
 * - **PusherEvent**: Pusher event callbacks, including error, live ended, kicked out, and other event types.
 *
 * ###
 *
 * ###
 *
 * ###
 *
 * @see AtomicPlayer
 * @see AtomicLiveView
 */
export declare class AtomicPusher {
    private static instance;
    private impl;
    private constructor();
    static shared(): AtomicPusher;
    getState(): PusherState;
    /**
     * Add pusher event callback listener.
     *
     * @param listener Listener.
     */
    addListener(listener?: PusherListener): void;
    /**
     * Remove pusher event callback listener.
     *
     * @param listener Listener.
     */
    removeListener(listener?: PusherListener): void;
    /**
     * Set the render view. The locally captured video frames will be rendered into the given `AtomicLiveView` container.
     *
     * @param view The render view container.
     */
    setView(view: AtomicLiveView): void;
    /**
     * Start pushing (streaming). Pass in the live room configuration; the SDK will create the push link accordingly.
     *
     * @param config Live room configuration.
     */
    startPush(config: PusherInfo): void;
    /**
     * Stop pushing (streaming).
     */
    stopPush(): void;
    /**
     * Update live room configuration. Call this after `startPush` to update live room info such as name, cover, category etc.
     *
     * @param config Updated configuration.
     * @param modifyFlagList Modify flags.
     */
    updateConfig(config: PusherInfo, modifyFlagList: Array<PusherInfoModifyFlag>): void;
    /**
     * Advanced feature. Enable an advanced feature by key-value pair. Supported keys depend on the underlying native pusher capability and may evolve over versions.
     *
     * @param key Feature key.
     * @param value Feature value, type depends on the specific key.
     */
    enableAdvancedFeature(key: string, value: Object): void;
    /**
     * Actively release the pusher. After calling, all APIs become no-ops, and internally held underlying resources, state, and event subscriptions will be cleaned up.
     */
    release(): void;
}
