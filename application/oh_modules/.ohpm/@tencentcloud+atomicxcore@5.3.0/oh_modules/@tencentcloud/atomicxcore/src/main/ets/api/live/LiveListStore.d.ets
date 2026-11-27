/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveListStore @ AtomicXCore
 * Function: Live list related interfaces, managing live room creation, joining, leaving and other operations.
 */
import BasicDataSource from '../common/BasicDataSource';
import { ExperimentalEventCallback, SubscriptionToken } from '../Define';
import { LiveUserInfo } from './LiveAudienceStore';
import BasicData from '../common/BasicData';
/**
 * Live state.
 */
export declare enum LiveStatus {
    /**
     * Scheduled.
     */
    SCHEDULED = 1,
    /**
     * Running.
     */
    RUNNING = 2,
    /**
     * Suspended.
     */
    SUSPENDED = 3
}
/**
 * Take seat mode.
 */
export declare enum TakeSeatMode {
    /**
     * Free to take seat.
     */
    FREE = 1,
    /**
     * Apply to take seat.
     */
    APPLY = 2
}
/**
 * Seat layout template for simplifying seat configuration when creating a live room.
 */
export declare abstract class SeatLayoutTemplate {
}
/**
 * Portrait dynamic 9-grid layout for video live streaming.
 */
export declare class VideoDynamicGrid9Seats extends SeatLayoutTemplate {
}
/**
 * Portrait dynamic 1v6 floating layout for video live streaming.
 */
export declare class VideoDynamicFloat7Seats extends SeatLayoutTemplate {
}
/**
 * Portrait left focus 9-grid layout for video live streaming.
 */
export declare class VideoLeftFocus9Seats extends SeatLayoutTemplate {
}
/**
 * Portrait uniform 9-grid layout for video live streaming.
 */
export declare class VideoUniformGrid9Seats extends SeatLayoutTemplate {
}
/**
 * Portrait static 9-grid layout for video live streaming.
 */
export declare class VideoFixedGrid9Seats extends SeatLayoutTemplate {
}
/**
 * Portrait static 1v6 floating layout for video live streaming.
 */
export declare class VideoFixedFloat7Seats extends SeatLayoutTemplate {
}
/**
 * Landscape layout with 1 video seat and 3 audio seats for video live streaming.
 */
export declare class VideoLandscape4Seats extends SeatLayoutTemplate {
}
/**
 * Landscape layout with 1 video seat and 9 audio seats for video live streaming.
 */
export declare class VideoLandscape10Seats extends SeatLayoutTemplate {
}
/**
 * Portrait layout with 1 video seat and 9 audio seats for video live streaming.
 */
export declare class VideoPortrait10Seats extends SeatLayoutTemplate {
}
/**
 * Audio KTV layout for karaoke scenes with configurable seat count.
 */
export declare class Karaoke extends SeatLayoutTemplate {
    seatCount: number;
    constructor(seatCount: number);
}
/**
 * Audio salon layout for voice chat scenes with configurable seat count.
 */
export declare class AudioSalon extends SeatLayoutTemplate {
    seatCount: number;
    constructor(seatCount: number);
}
/**
 * Live ended reason.
 */
export declare enum LiveEndedReason {
    /**
     * Ended by host.
     */
    ENDED_BY_HOST = 1,
    /**
     * Ended by server.
     */
    ENDED_BY_SERVER = 2
}
/**
 * Kicked out of live room reason.
 */
export declare enum LiveKickedOutReason {
    /**
     * Kicked out by admin.
     */
    BY_ADMIN = 0,
    /**
     * Logged on other device.
     */
    BY_LOGGED_ON_OTHER_DEVICE = 1,
    /**
     * Kicked out by server.
     */
    BY_SERVER = 2,
    /**
     * Network disconnected.
     */
    FOR_NETWORK_DISCONNECTED = 3,
    /**
     * Join room status invalid during offline.
     */
    FOR_JOIN_ROOM_STATUS_INVALID_DURING_OFFLINE = 4,
    /**
     * Count of joined rooms exceed limit.
     */
    FOR_COUNT_OF_JOINED_ROOMS_EXCEED_LIMIT = 5
}
/**
 * Live information.
 *
 * Contains complete property information of the live room, including live ID, name, cover, owner info, etc.
 */
export declare class LiveInfo extends BasicData {
    /**
     * Live ID.
     */
    liveID: string;
    /**
     * Live name.
     */
    liveName: string;
    /**
     * Live status.
     */
    status: LiveStatus;
    /**
     * Live notice.
     */
    notice: string;
    /**
     * Whether message is disabled.
     */
    isMessageDisable: boolean;
    /**
     * Whether publicly visible.
     */
    isPublicVisible: boolean;
    /**
     * Whether to keep owner on seat.
     */
    keepOwnerOnSeat: boolean;
    /**
     * Take seat mode.
     */
    seatMode: TakeSeatMode;
    /**
     * Seat layout template for simplifying seat configuration.
     */
    seatTemplate: SeatLayoutTemplate;
    /**
     * Cover URL.
     */
    coverURL: string;
    /**
     * Background URL.
     */
    backgroundURL: string;
    /**
     * Category list.
     */
    categoryList: Array<number>;
    /**
     * Activity status.
     */
    activityStatus: number;
    /**
     * Live owner info.
     */
    liveOwner: LiveUserInfo;
    /**
     * Create time.
     */
    createTime: number;
    /**
     * Total viewer count.
     */
    totalViewerCount: number;
    /**
     * Whether gift is enabled.
     */
    isGiftEnabled: boolean;
    /**
     * Metadata.
     */
    metaData: Map<string, string>;
    /**
     * Whether seat is enabled.
     */
    isSeatEnabled: boolean;
    /**
     * Maximum seat count.
     */
    maxSeatCount: number;
    /**
     * Seat layout template ID.
     */
    seatLayoutTemplateID: number;
    constructor(seatTemplate?: SeatLayoutTemplate);
    isEmpty(): boolean;
}
/**
 * Live list state.
 *
 * Contains live list, cursor and current live info.
 */
@Observed
export declare class LiveListState {
    /**
     * Live list.
     */
    liveList: LiveListDataSource;
    /**
     * Live list cursor.
     */
    liveListCursor: string;
    /**
     * Current live info.
     */
    currentLive: LiveInfo;
}
export declare class LiveListListener {
    onLiveEnded?: (liveID: string, reason: LiveEndedReason, message: string) => void;
    onKickedOutOfLive?: (liveID: string, reason: LiveKickedOutReason, message: string) => void;
}
@Observed
export declare class LiveStatisticsData {
    totalViewers: number;
    totalGiftsSent: number;
    totalGiftCoins: number;
    totalUniqueGiftSenders: number;
    totalLikesReceived: number;
    totalMessageCount: number;
    liveDuration: number;
}
/**
 * Live list related interfaces, managing live room creation, joining, leaving and other operations.
 *
 * `LiveListStore` Live room list management class for managing live room related business.
 * `LiveListStore` provides a complete set of live room management APIs, including starting live, joining live, leaving live, ending live and other functions.
 * Through this class, you can manage the lifecycle of live rooms. The host calls startLive/endLive to start and dismiss a live room, while the audience calls joinLive/leaveLive to join and leave a live room.
 *
 * ### Key Features
 *
 * - **Live List**: Get and manage live room list.
 * - **Start Live**: Host starts broadcasting. If the live room ID is new, a new live room will be created; if the live room ID already exists on the server, the host will join and start broadcasting.
 * - **Live Joining**: Join existing live rooms.
 * - **Live Management**: Update live info, end live and other operations.
 * - **Event Listening**: Listen for live ended, kicked out and other events.
 *
 * > **Important**: Use the [LiveListStore.shared] singleton object to get the `LiveListStore` instance.
 *
 * > **Tip**: Live state updates are delivered through the [liveState] publisher. Subscribe to it to receive real-time updates of live data.
 *
 * ### Getting Instance
 *
 * ### Observing State and Events
 *
 * ### Live List
 *
 * ### Live Operations
 *
 * ### Metadata Operations
 *
 */
@Observed
export declare abstract class LiveListStore {
    static shared(): LiveListStore;
    protected liveListState: LiveListState;
    get liveState(): Readonly<LiveListState>;
    /**
     * Get live list
     *
     * @param cursor Cursor.
     * @param count Count.
     */
    abstract fetchLiveList(cursor: string, count: number): Promise<void>;
    /**
     * Get live info
     *
     * @param liveID Live room ID.
     * @param completion Completion callback.
     */
    abstract fetchLiveInfo(liveID: string): Promise<LiveInfo>;
    /**
     * Start live (Host only)
     *
     * Host starts broadcasting. If the live room ID is new, a new live room will be created; if the live room ID already exists on the server, the host will join and start broadcasting.
     *
     * @param liveInfo Live info.
     */
    abstract startLive(liveInfo: LiveInfo): Promise<LiveInfo>;
    /**
     * Join live (Audience only)
     *
     * Called by the audience to join an existing live room.
     *
     * @param liveID Live ID.
     */
    abstract joinLive(liveID: string): Promise<LiveInfo>;
    /**
     * Leave live (Audience only)
     *
     * Called by the audience to leave the current live room.
     * If the host only needs to leave the room without dismissing it, this API can also be called.
     */
    abstract leaveLive(): Promise<void>;
    /**
     * End live (Host only)
     *
     * Called by the host to end the current live and dismiss the room.
     */
    abstract endLive(): Promise<LiveStatisticsData>;
    /**
     * Update live info
     *
     * @param liveInfo Live info.
     * @param modifyFlag Modify flag.
     */
    abstract updateLiveInfo(liveInfo: LiveInfo, modifyFlagList: Array<ModifyFlag>): Promise<void>;
    /**
     * Query metadata
     *
     * @param keys Key list.
     */
    abstract queryMetaData(keys: Array<string>): Promise<Map<string, string>>;
    /**
     * Update live metadata
     *
     * @param metaData Metadata.
     */
    abstract updateLiveMetaData(metaData: Map<string, string>): Promise<void>;
    /**
     * Call experimental API
     *
     * @param jsonMap JSON parameter map.
     * @param callback Called with the error code, message and the JSON string returned by the engine when the invocation completes.
     */
    abstract callExperimentalAPI(jsonMap: Record<string, Object>, callback?: (code: number, message: string, data: string) => void): void;
    /**
     * Subscribe to experimental event
     *
     * @param event Event name.
     * @param callback Event callback delivering (roomID, jsonStr).
     * @returns Subscription token for unsubscribing.
     */
    abstract subscribeExperimentalEvent(event: string, callback: ExperimentalEventCallback): SubscriptionToken;
    /**
     * Unsubscribe from experimental event
     *
     * @param token Subscription token.
     */
    abstract unsubscribeExperimentalEvent(token: SubscriptionToken): void;
    /**
     * Reset to default state
     */
    abstract reset(): void;
    /**
     * Add live list event listener
     *
     * @param listener Listener.
     */
    abstract addLiveListListener(listener: LiveListListener): void;
    /**
     * Remove live list event listener
     *
     * @param listener Listener.
     */
    abstract removeLiveListListener(listener: LiveListListener): void;
}
declare class SeatConfiguration {
    isSeatEnabled: boolean;
    maxSeatCount: number | undefined;
    seatLayoutTemplateID: number;
    keepOwnerOnSeat: boolean | undefined;
    constructor(isSeatEnabled: boolean, maxSeatCount: number | undefined, seatLayoutTemplateID: number, keepOwnerOnSeat: boolean | undefined);
}
export declare function getSeatConfiguration(template: SeatLayoutTemplate): SeatConfiguration;
export declare enum ModifyFlag {
    NONE = 0,
    LIVE_NAME = 1,
    NOTICE = 2,
    IS_MESSAGE_DISABLE = 4,
    IS_PUBLIC_VISIBLE = 32,
    SEAT_MODE = 64,
    COVER_URL = 128,
    BACKGROUND_URL = 256,
    CATEGORY_LIST = 512,
    ACTIVITY_STATUS = 1024,
    SEAT_LAYOUT_TEMPLATE_ID = 2048,
    SEAT_TEMPLATE = 2048
}
export declare class LiveListDataSource extends BasicDataSource<LiveInfo> {
}
export {};
