/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   RoomStore @ AtomicXCore
 * Function: Room management related interfaces, managing room creation, joining, leaving, scheduling and other operations.
 */
import BasicData from '../common/BasicData';
import BasicDataSource from '../common/BasicDataSource';
import { ExperimentalEventCallback, SubscriptionToken } from '../Define';
/**
 * Room type.
 */
export declare enum RoomType {
    /**
     * Standard room.
     */
    standard = 1,
    /**
     * Webinar room.
     */
    webinar = 2
}
/**
 * Room status.
 */
export declare enum RoomStatus {
    /**
     * Scheduled.
     */
    scheduled = 1,
    /**
     * Running.
     */
    running = 2
}
/**
 * Room call status.
 */
export declare enum RoomCallStatus {
    /**
     * No call.
     */
    none = 0,
    /**
     * Calling.
     */
    calling = 1,
    /**
     * Call timeout.
     */
    timeout = 2,
    /**
     * Call rejected.
     */
    rejected = 3
}
/**
 * Call user to room result.
 */
export declare enum RoomCallResult {
    /**
     * Call success.
     */
    success = 0,
    /**
     * User already in calling.
     */
    alreadyInCalling = 1,
    /**
     * User already in room.
     */
    alreadyInRoom = 2
}
/**
 * Call rejection reason.
 */
export declare enum CallRejectionReason {
    /**
     * User actively rejected.
     */
    rejected = 0,
    /**
     * User in another room.
     */
    inOtherRoom = 1
}
/**
 * Recording status.
 */
export declare enum RecordingStatus {
    /**
     * Not recording.
     */
    none = 0,
    /**
     * Recording in progress.
     */
    recording = 1
}
/**
 * Recording stop reason.
 */
export declare enum RecordingStopReason {
    /**
     * Manually stopped by user.
     */
    stoppedByUser = 0,
    /**
     * The recording bot has left the room.
     */
    recorderLeftRoom = 1
}
/**
 * Schedule room options modify flag.
 *
 * Flags for specifying which fields to modify when updating scheduled room options.
 */
export declare enum ScheduleRoomOptionsModifyFlag {
    roomName = 1,
    scheduleStartTime = 2,
    scheduleEndTime = 4
}
/**
 * Update room options modify flag.
 *
 * Flags for specifying which fields to modify when updating room options.
 */
export declare enum UpdateRoomOptionsModifyFlag {
    roomName = 8,
    password = 8192
}
/**
 * Start recording options.
 *
 * Configuration options when starting cloud recording.
 */
export declare class StartRecordingOptions {
}
/**
 * Room user info.
 *
 * Represents basic information of a user in the room.
 */
@Observed
export declare class RoomUser extends BasicData {
    /**
     * User ID.
     */
    userID: string;
    /**
     * User name.
     */
    userName: string;
    /**
     * User avatar URL.
     */
    avatarURL: string;
    constructor(userID?: string, userName?: string, avatarURL?: string);
}
/**
 * Recording info.
 *
 * Represents recording state of the current room.
 */
@Observed
export declare class RecordingInfo {
    /**
     * Recording status.
     */
    status: RecordingStatus;
    /**
     * User who started the recording.
     */
    operatorUser: RoomUser;
    /**
     * Recording start timestamp, in milliseconds.
     */
    startTime: number;
    constructor(status?: RecordingStatus, operatorUser?: RoomUser, startTime?: number);
}
/**
 * Room info.
 *
 * Represents complete room information, including basic info and configuration options.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | roomID | `string` | Room ID |
 * | roomName | `string` | Room name |
 * | roomOwner | `RoomUser` | Room owner |
 * | participantCount | `number` | Participant count |
 * | roomStatus | `RoomStatus` | Room status |
 */
@Observed
export declare class RoomInfo extends BasicData {
    /**
     * Room ID.
     */
    roomID: string;
    getKey(): string;
    /**
     * Room name.
     */
    roomName: string;
    /**
     * Room owner.
     */
    roomOwner: RoomUser;
    /**
     * Room type.
     */
    roomType: RoomType;
    /**
     * Participant count.
     */
    participantCount: number;
    /**
     * Audience count (for webinar room).
     */
    audienceCount: number;
    /**
     * Create time, in milliseconds.
     */
    createTime: number;
    /**
     * Room status.
     */
    roomStatus: RoomStatus;
    /**
     * Scheduled start time, in seconds.
     */
    scheduledStartTime: number;
    /**
     * Scheduled end time, in seconds.
     */
    scheduledEndTime: number;
    /**
     * Reminder seconds before start.
     */
    startReminderInSeconds: number;
    /**
     * Scheduled attendees list.
     */
    scheduleAttendees: RoomUser[];
    /**
     * Room password.
     */
    password?: string;
    /**
     * Whether all microphones are disabled.
     */
    isAllMicrophoneDisabled: boolean;
    /**
     * Whether all cameras are disabled.
     */
    isAllCameraDisabled: boolean;
    /**
     * Whether all messages are disabled.
     */
    isAllMessageDisabled: boolean;
    /**
     * Whether all screen sharing is disabled.
     */
    isAllScreenShareDisabled: boolean;
    /**
     * Recording info.
     */
    recordingInfo: RecordingInfo;
    constructor(roomID?: string, roomName?: string, roomOwner?: RoomUser, roomType?: RoomType, participantCount?: number, audienceCount?: number, createTime?: number, roomStatus?: RoomStatus, scheduledStartTime?: number, scheduledEndTime?: number, startReminderInSeconds?: number, scheduleAttendees?: RoomUser[], password?: string, isAllMicrophoneDisabled?: boolean, isAllCameraDisabled?: boolean, isAllMessageDisabled?: boolean, isAllScreenShareDisabled?: boolean, recordingInfo?: RecordingInfo);
    get isEmpty(): boolean;
}
/**
 * Schedule room options.
 *
 * Configuration options when scheduling a room.
 */
export declare class ScheduleRoomOptions {
    /**
     * Room name.
     */
    roomName: string;
    /**
     * Room password.
     */
    password: string;
    /**
     * Scheduled start time, in seconds.
     */
    scheduleStartTime: number;
    /**
     * Scheduled end time, in seconds.
     */
    scheduleEndTime: number;
    /**
     * Reminder seconds before start.
     */
    reminderSecondsBeforeStart: number;
    /**
     * Scheduled attendee ID list.
     */
    scheduleAttendees: string[];
    /**
     * Whether all microphones are disabled.
     */
    isAllMicrophoneDisabled: boolean;
    /**
     * Whether all cameras are disabled.
     */
    isAllCameraDisabled: boolean;
    /**
     * Whether all screen sharing is disabled.
     */
    isAllScreenShareDisabled: boolean;
    /**
     * Whether all messages are disabled.
     */
    isAllMessageDisabled: boolean;
    constructor(roomName?: string, password?: string, scheduleStartTime?: number, scheduleEndTime?: number, reminderSecondsBeforeStart?: number, scheduleAttendees?: string[], isAllMicrophoneDisabled?: boolean, isAllCameraDisabled?: boolean, isAllScreenShareDisabled?: boolean, isAllMessageDisabled?: boolean);
}
/**
 * Create room options.
 *
 * Configuration options when creating an instant room.
 */
export declare class CreateRoomOptions {
    /**
     * Room name.
     */
    roomName: string;
    /**
     * Room password.
     */
    password: string;
    /**
     * Whether all microphones are disabled.
     */
    isAllMicrophoneDisabled: boolean;
    /**
     * Whether all cameras are disabled.
     */
    isAllCameraDisabled: boolean;
    /**
     * Whether all screen sharing is disabled.
     */
    isAllScreenShareDisabled: boolean;
    /**
     * Whether all messages are disabled.
     */
    isAllMessageDisabled: boolean;
    constructor(roomName?: string, password?: string, isAllMicrophoneDisabled?: boolean, isAllCameraDisabled?: boolean, isAllScreenShareDisabled?: boolean, isAllMessageDisabled?: boolean);
}
/**
 * Update room options.
 *
 * Configuration options when updating room info.
 */
export declare class UpdateRoomOptions {
    /**
     * Room name.
     */
    roomName: string;
    /**
     * Room password.
     */
    password: string;
    constructor(roomName?: string, password?: string);
}
/**
 * Room call info.
 *
 * Represents room call information, including caller, callee and call status.
 */
@Observed
export declare class RoomCall {
    /**
     * Caller info.
     */
    caller: RoomUser;
    /**
     * Callee info.
     */
    callee: RoomUser;
    /**
     * Call status.
     */
    status: RoomCallStatus;
    constructor(caller?: RoomUser, callee?: RoomUser, status?: RoomCallStatus);
}
/**
 * Room related state data provided by RoomStore.
 *
 * Comprehensive snapshot of current room session state. This structure contains all relevant information about current room and scheduled room list.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | scheduledRoomList | `BasicDataSource<RoomInfo>` | Scheduled room list |
 * | scheduledRoomListCursor | `string` | Scheduled room list cursor |
 * | currentRoom | `RoomInfo` | Current room info |
 *
 * > **Tip**: State is automatically updated when room status changes. Subscribe to `state` to receive real-time updates.
 */
@Observed
export declare class RoomState {
    /**
     * Scheduled room list.
     */
    scheduledRoomList: BasicDataSource<RoomInfo>;
    /**
     * Scheduled room list cursor.
     */
    scheduledRoomListCursor: string;
    /**
     * Current room info.
     */
    currentRoom?: RoomInfo;
}
/**
 * Room event callback.
 */
export declare class RoomListener {
    /**
     * Triggered when added to a scheduled room.
     *
     * @param roomInfo Room info.
     */
    onAddedToScheduledRoom?: (roomInfo: RoomInfo) => void;
    /**
     * Triggered when removed from a scheduled room.
     *
     * @param roomInfo Room info.
     * @param operator Operator info.
     */
    onRemovedFromScheduledRoom?: (roomInfo: RoomInfo, operator: RoomUser) => void;
    /**
     * Triggered when a scheduled room is cancelled.
     *
     * @param roomInfo Room info.
     * @param operator Operator info.
     */
    onScheduledRoomCancelled?: (roomInfo: RoomInfo, operator: RoomUser) => void;
    /**
     * Triggered when a scheduled room is about to start.
     *
     * @param roomInfo Room info.
     */
    onScheduledRoomStartingSoon?: (roomInfo: RoomInfo) => void;
    /**
     * Triggered when a room ends.
     *
     * @param roomInfo Room info.
     */
    onRoomEnded?: (roomInfo: RoomInfo) => void;
    /**
     * Triggered when a room call is received.
     *
     * @param roomInfo Room info.
     * @param call Call info.
     * @param extensionInfo Extension info.
     */
    onCallReceived?: (roomInfo: RoomInfo, call: RoomCall, extensionInfo: string) => void;
    /**
     * Triggered when a room call is cancelled.
     *
     * @param roomInfo Room info.
     * @param call Call info.
     */
    onCallCancelled?: (roomInfo: RoomInfo, call: RoomCall) => void;
    /**
     * Triggered when a room call times out.
     *
     * @param roomInfo Room info.
     * @param call Call info.
     */
    onCallTimeout?: (roomInfo: RoomInfo, call: RoomCall) => void;
    /**
     * Triggered when a room call is accepted.
     *
     * @param roomInfo Room info.
     * @param call Call info.
     */
    onCallAccepted?: (roomInfo: RoomInfo, call: RoomCall) => void;
    /**
     * Triggered when a room call is rejected.
     *
     * @param roomInfo Room info.
     * @param call Call info.
     * @param reason Rejection reason.
     */
    onCallRejected?: (roomInfo: RoomInfo, call: RoomCall, reason: CallRejectionReason) => void;
    /**
     * Triggered when a room call is handled by another device.
     *
     * @param roomInfo Room info.
     * @param isAccepted Whether accepted.
     */
    onCallHandledByOtherDevice?: (roomInfo: RoomInfo, isAccepted: boolean) => void;
    /**
     * Triggered when a room call is revoked by admin.
     *
     * @param roomInfo Room info.
     * @param call Call info.
     * @param operator Operator info.
     */
    onCallRevokedByAdmin?: (roomInfo: RoomInfo, call: RoomCall, operator: RoomUser) => void;
    /**
     * Triggered when recording starts.
     *
     * @param roomInfo Room info.
     * @param operator The user who started the recording.
     */
    onRecordingStarted?: (roomInfo: RoomInfo, operator: RoomUser) => void;
    /**
     * Triggered when recording stops.
     *
     * @param roomInfo Room info.
     * @param operator The user who stopped the recording.
     * @param reason Recording stop reason.
     */
    onRecordingStopped?: (roomInfo: RoomInfo, operator: RoomUser, reason: RecordingStopReason) => void;
}
/**
 * List result
 */
export declare class ListResult<T> {
    data: T[];
    cursor: string;
}
/**
 * Room management related interfaces, managing room creation, joining, leaving, scheduling and other operations.
 *
 * `RoomStore` Manage room creation, joining, leaving, scheduling and other operations.
 * Room management provides complete room lifecycle management, including instant rooms and scheduled rooms. `RoomStore` provides a comprehensive set of APIs to manage room-related operations.
 *
 * ### Key Features
 *
 * - **Instant Room**: Supports creating and joining instant rooms.
 * - **Scheduled Room**: Supports scheduling rooms, modifying schedules, canceling schedules and other operations.
 * - **Room Call**: Supports calling users to join rooms, accepting/rejecting calls and other operations.
 * - **State Management**: Real-time tracking of current room status and scheduled room list.
 *
 * > **Tip**: Room status updates are delivered through `state` publisher. Subscribe to it to receive real-time updates about current room and scheduled room list.
 *
 * ### Getting Instance
 * - `RoomStore.shared` - Get singleton object.
 *
 * ### Observing State and Events
 * - `state` - Reactive state containing current room and scheduled room list.
 * - `addRoomListener`/`removeRoomListener` - Room event callback
 *
 * ### Scheduled Room Operations
 * - `getScheduledRoomList` - Get scheduled room list.
 * - `getScheduledAttendees` - Get scheduled room attendees.
 * - `scheduleRoom` - Schedule a room.
 * - `updateScheduledRoom` - Update scheduled room.
 * - `addScheduledAttendees` - Add scheduled attendees.
 * - `removeScheduledAttendees` - Remove scheduled attendees.
 * - `cancelScheduledRoom` - Cancel scheduled room.
 *
 * ### Instant Room Operations
 * - `createAndJoinRoom` - Create and join room.
 * - `joinRoom` - Join room.
 * - `leaveRoom` - Leave room.
 * - `endRoom` - End room.
 * - `updateRoomInfo` - Update room info.
 * - `getRoomInfo` - Get room info.
 *
 * ### Room Call Operations
 * - `getPendingCalls` - Get pending calls list.
 * - `callUserToRoom` - Call user to join room.
 * - `cancelCall` - Cancel call.
 * - `acceptCall` - Accept call.
 * - `rejectCall` - Reject call.
 *
 * ### Recording Operations
 * - `startRecording` - Start cloud recording.
 * - `stopRecording` - Stop cloud recording.
 *
 * @see RoomStatus
 * @see RoomInfo
 * @see RoomUser
 * @see RoomListener
 * @see RoomCall
 */
@Observed
export declare abstract class RoomStore {
    protected roomState: RoomState;
    get state(): Readonly<RoomState>;
    static shared(): RoomStore;
    /**
     * Add room event callback listener
     *
     * @param listener Listener.
     */
    abstract addRoomListener(listener: RoomListener): void;
    /**
     * Remove room event callback listener
     *
     * @param listener Listener.
     */
    abstract removeRoomListener(listener: RoomListener): void;
    /**
     * Get scheduled room list
     *
     * @param cursor Pagination cursor.
     * @returns Operation result containing scheduled room list.
     */
    abstract getScheduledRoomList(cursor: string | undefined): Promise<ListResult<RoomInfo>>;
    /**
     * Get scheduled room attendees
     *
     * @param roomID Room ID.
     * @param cursor Pagination cursor.
     * @returns Operation result containing attendees list.
     */
    abstract getScheduledAttendees(roomID: string, cursor: string | undefined): Promise<ListResult<RoomUser>>;
    /**
     * Schedule a room
     *
     * @param roomID Room ID.
     * @param options Schedule options.
     */
    abstract scheduleRoom(roomID: string, options: ScheduleRoomOptions): Promise<void>;
    /**
     * Update scheduled room
     *
     * @param roomID Room ID.
     * @param options Schedule options.
     * @param modifyFlagList Modify flag list.
     */
    abstract updateScheduledRoom(roomID: string, options: ScheduleRoomOptions, modifyFlagList: ScheduleRoomOptionsModifyFlag[]): Promise<void>;
    /**
     * Add scheduled attendees
     *
     * @param roomID Room ID.
     * @param userIDList User ID list.
     */
    abstract addScheduledAttendees(roomID: string, userIDList: string[]): Promise<void>;
    /**
     * Remove scheduled attendees
     *
     * @param roomID Room ID.
     * @param userIDList User ID list.
     */
    abstract removeScheduledAttendees(roomID: string, userIDList: string[]): Promise<void>;
    /**
     * Cancel scheduled room
     *
     * @param roomID Room ID.
     */
    abstract cancelScheduledRoom(roomID: string): Promise<void>;
    /**
     * Create and join room
     *
     * @param roomID Room ID.
     * @param roomType Room type (standard or webinar).
     * @param options Create options.
     */
    abstract createAndJoinRoom(roomID: string, roomType: RoomType, options: CreateRoomOptions): Promise<void>;
    /**
     * Join room
     *
     * @param roomID Room ID.
     * @param roomType Room type (standard or webinar).
     * @param password Room password.
     */
    abstract joinRoom(roomID: string, roomType: RoomType, password?: string): Promise<void>;
    /**
     * Leave room
     */
    abstract leaveRoom(): Promise<void>;
    /**
     * End room
     */
    abstract endRoom(): Promise<void>;
    /**
     * Update room info
     *
     * @param roomID Room ID.
     * @param options Update options.
     * @param modifyFlagList Modify flag list.
     */
    abstract updateRoomInfo(roomID: string, options: UpdateRoomOptions, modifyFlagList: UpdateRoomOptionsModifyFlag[]): Promise<void>;
    /**
     * Get room info
     *
     * @param roomID Room ID.
     * @returns Operation result containing room info.
     */
    abstract getRoomInfo(roomID: string): Promise<RoomInfo>;
    /**
     * Get pending calls list
     *
     * @param roomID Room ID.
     * @param cursor Pagination cursor.
     * @returns Operation result containing call list.
     */
    abstract getPendingCalls(roomID: string, cursor: string | undefined): Promise<ListResult<RoomCall>>;
    /**
     * Call user to join room
     *
     * @param roomID Room ID.
     * @param userIDList User ID list.
     * @param timeout Timeout (in seconds).
     * @param extensionInfo Extension info.
     * @returns Operation result containing call result.
     */
    abstract callUserToRoom(roomID: string, userIDList: string[], timeout?: number, extensionInfo?: string | undefined): Promise<Map<string, RoomCallResult>>;
    /**
     * Cancel call
     *
     * @param roomID Room ID.
     * @param userIDList User ID list.
     */
    abstract cancelCall(roomID: string, userIDList: string[]): Promise<void>;
    /**
     * Accept call
     *
     * @param roomID Room ID.
     */
    abstract acceptCall(roomID: string): Promise<void>;
    /**
     * Reject call
     *
     * @param roomID Room ID.
     * @param reason Rejection reason.
     */
    abstract rejectCall(roomID: string, reason: CallRejectionReason): Promise<void>;
    /**
     * Start cloud recording
     *
     * Only Owner and Admin have permission to call.
     *
     * @param options Recording options, reserved for future extensions.
     */
    abstract startRecording(options?: StartRecordingOptions): Promise<void>;
    /**
     * Stop cloud recording
     *
     * Only Owner and Admin have permission to call.
     */
    abstract stopRecording(): Promise<void>;
    /**
     * Call experimental API
     *
     * @param jsonStr JSON string containing the API name and parameters.
     */
    abstract callExperimentalAPI(jsonStr: string): Promise<string>;
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
     * Reset room state
     *
     * Reset all state data of RoomStore, clear current room info and scheduled room list. Usually called when user logs out or needs to clean up state.
     */
    abstract reset(): void;
}
