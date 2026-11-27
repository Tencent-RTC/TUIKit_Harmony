/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveSeatStore @ AtomicXCore
 * Function: Live seat management related interfaces, managing seat operations such as taking seat, leaving seat, locking seat, and releasing seat.
 */
import { Role } from './LiveAudienceStore';
import { DeviceStatus } from '../device/DeviceStore';
import BasicDataSource from '../common/BasicDataSource';
import BasicData from '../common/BasicData';
/**
 * Move seat policy.
 */
export declare enum MoveSeatPolicy {
    /**
     * Abort when occupied.
     */
    ABORT_WHEN_OCCUPIED = 0,
    /**
     * Force replace.
     */
    FORCE_REPLACE = 1,
    /**
     * Swap position.
     */
    SWAP_POSITION = 2
}
/**
 * Device control policy.
 */
export declare enum DeviceControlPolicy {
    /**
     * Unlock only.
     */
    UNLOCK_ONLY = 1
}
/**
 * User suspend status.
 */
export declare enum SuspendStatus {
    /**
     * Not suspended.
     */
    NONE = 0,
    /**
     * User suspended in background.
     */
    IN_BACKGROUND = 1,
    /**
     * User is on a phone call.
     */
    IN_CALLING = 2
}
/**
 * Take seat mode.
 */
export declare enum SeatMode {
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
 * Seat user information.
 *
 * Contains basic information of the seat user, such as user ID, user name, avatar URL, role, device status, etc.
 */
export declare class SeatUserInfo extends BasicData {
    /**
     * User ID.
     */
    userID: string;
    /**
     * User name.
     */
    userName: string;
    /**
     * Avatar URL.
     */
    avatarURL: string;
    /**
     * User role.
     */
    role: Role;
    /**
     * Live room ID.
     */
    liveID: string;
    /**
     * Microphone status.
     */
    microphoneStatus: DeviceStatus;
    /**
     * Whether microphone can be opened.
     */
    allowOpenMicrophone: boolean;
    /**
     * Camera status.
     */
    cameraStatus: DeviceStatus;
    /**
     * Whether camera can be opened.
     */
    allowOpenCamera: boolean;
    /**
     * User suspend status.
     */
    userSuspendStatus: SuspendStatus;
}
/**
 * Seat view coordinate information.
 *
 * Contains the coordinate information of the seat view, such as X coordinate, Y coordinate, width, height, z-order.
 */
export declare class RegionInfo {
    /**
     * X coordinate.
     */
    x: number;
    /**
     * Y coordinate.
     */
    y: number;
    /**
     * Width.
     */
    w: number;
    /**
     * Height.
     */
    h: number;
    /**
     * Z-order.
     */
    zorder: number;
}
/**
 * Audio and video statistics information.
 *
 * Contains audio and video related statistics, such as user ID, video bitrate, video width and height, frame rate, audio sample rate, audio bitrate, etc.
 */
export declare class AVStatistics extends BasicData {
    /**
     * User ID.
     */
    userID: string;
    /**
     * Local video bitrate.
     */
    videoBitrate: number;
    /**
     * Local video width.
     */
    videoWidth: number;
    /**
     * Local video height.
     */
    videoHeight: number;
    /**
     * Local video frame rate.
     */
    frameRate: number;
    /**
     * Audio sample rate.
     */
    audioSampleRate: number;
    /**
     * Audio bitrate.
     */
    audioBitrate: number;
}
/**
 * Seat information.
 *
 * Contains basic information of the seat, such as seat index, whether locked, user information, region information.
 */
export declare class SeatInfo extends BasicData {
    /**
     * Seat index.
     */
    index: number;
    /**
     * Whether locked.
     */
    isLocked: boolean;
    /**
     * User information.
     */
    userInfo: SeatUserInfo;
    /**
     * Region information.
     */
    region: RegionInfo;
    /**
     * Whether the user on this seat is currently a featured host. Can only be true in templates that support featured host slots.
     */
    isFeaturedHost: boolean;
}
/**
 * Live canvas.
 *
 * Contains basic information of the live canvas, such as width, height, template ID.
 */
export declare class LiveCanvas {
    /**
     * Width.
     */
    w: number;
    /**
     * Height.
     */
    h: number;
    /**
     * Template ID.
     */
    templateID: number;
}
/**
 * Seat state data provided by LiveSeatStore.
 *
 * Contains seat list, canvas information, speaking users, audio and video statistics, etc.
 */
@Observed
export declare class LiveSeatState {
    /**
     * Seat list.
     */
    seatList: SeatInfoDataSource;
    /**
     * Canvas information.
     */
    canvas: LiveCanvas;
    /**
     * Speaking users.
     */
    speakingUsers: Map<string, number>;
    /**
     * Audio and video statistics.
     */
    avStatistics: AVStatisticsDataSource;
    /**
     * Take seat mode of the current room, supports real-time updates and can be subscribed to.
     */
    seatMode: SeatMode;
}
/**
 * Seat related callback events.
 */
export declare class LiveSeatListener {
    onLocalCameraOpenedByAdmin?: (policy: DeviceControlPolicy) => void;
    onLocalCameraClosedByAdmin?: () => void;
    onLocalMicrophoneOpenedByAdmin?: (policy: DeviceControlPolicy) => void;
    onLocalMicrophoneClosedByAdmin?: () => void;
}
/**
 * Live seat management related interfaces, managing seat operations such as taking seat, leaving seat, locking seat, and releasing seat.
 *
 * `LiveSeatStore` Live seat management class for managing seat operations such as taking seat, leaving seat, locking seat, and releasing seat.
 * `LiveSeatStore` provides a complete set of seat management APIs, including taking seat, leaving seat, locking seat, unlocking seat, kicking user off seat, remote device control, etc.
 * Through this class, seat management functionality can be implemented in the live room.
 *
 * ### Key Features
 *
 * - **Seat Management**: Take seat, leave seat, lock seat, unlock seat operations.
 * - **User Management**: Kick user off seat, move user to specified seat.
 * - **Featured Host Management**: In templates that support a featured host slot, set a seated user as a featured host or remove a featured host.
 * - **Device Control**: Remote control of user's camera and microphone.
 * - **Event Listening**: Listen to seat-related events.
 *
 * > **Important**: Use the [LiveSeatStore.create] factory method to create a `LiveSeatStore` instance, passing a valid live room ID.
 *
 * > **Tip**: Seat state updates are delivered through the [liveSeatState] publisher. Subscribe to it to receive real-time updates of seat data in the room.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### Seat Operations
 *
 * ### User Management
 *
 * ### Seat Mode
 *
 * ### Featured Host Management
 *
 * ### Remote Device Control
 *
 */
export declare abstract class LiveSeatStore {
    protected state: LiveSeatState;
    get liveSeatState(): LiveSeatState;
    static create(liveID: string): LiveSeatStore;
    /**
     * Take seat
     *
     * @param seatIndex Seat index.
     */
    abstract takeSeat(seatIndex: number): Promise<void>;
    /**
     * Leave seat
     */
    abstract leaveSeat(): Promise<void>;
    /**
     * Mute microphone
     */
    abstract muteMicrophone(): void;
    /**
     * Unmute microphone
     */
    abstract unmuteMicrophone(): Promise<void>;
    /**
     * Kick user off seat
     *
     * @param userID User ID.
     */
    abstract kickUserOutOfSeat(userID: string): Promise<void>;
    /**
     * Move user to seat
     *
     * @param userID User ID.
     * @param targetIndex Target seat index.
     * @param policy Move policy.
     */
    abstract moveUserToSeat(userID: string, targetIndex: number, policy: MoveSeatPolicy): Promise<void>;
    /**
     * Set the take seat mode of the current room. After setting successfully, the ``LiveSeatState/seatMode`` state will be updated. Subscribe to it to receive real-time updates.
     *
     * @param mode Take seat mode (``SeatMode/free`` free to take seat / ``SeatMode/apply`` apply to take seat).
     */
    abstract setSeatMode(mode: SeatMode): Promise<void>;
    /**
     * Set featured host
     *
     * @param userID User ID.
     */
    abstract setFeaturedHost(userID: string): Promise<void>;
    /**
     * Revoke featured host
     *
     * @param userID User ID.
     */
    abstract revokeFeaturedHost(userID: string): Promise<void>;
    /**
     * Lock seat
     *
     * @param seatIndex Seat index.
     */
    abstract lockSeat(seatIndex: number): Promise<void>;
    /**
     * Unlock seat
     *
     * @param seatIndex Seat index.
     */
    abstract unlockSeat(seatIndex: number): Promise<void>;
    /**
     * Open remote camera
     *
     * @param userID User ID.
     * @param policy Device control policy.
     */
    abstract openRemoteCamera(userID: string, policy: DeviceControlPolicy): Promise<void>;
    /**
     * Close remote camera
     *
     * @param userID User ID.
     */
    abstract closeRemoteCamera(userID: string): Promise<void>;
    /**
     * Open remote microphone
     *
     * @param userID User ID.
     * @param policy Device control policy.
     */
    abstract openRemoteMicrophone(userID: string, policy: DeviceControlPolicy): Promise<void>;
    /**
     * Close remote microphone
     *
     * @param userID User ID.
     */
    abstract closeRemoteMicrophone(userID: string): Promise<void>;
    /**
     * Add seat event listener
     *
     * @param listener Listener.
     */
    abstract addLiveSeatEventListener(listener: LiveSeatListener): void;
    /**
     * Remove seat event listener
     *
     * @param listener Listener.
     */
    abstract removeLiveSeatEventListener(listener: LiveSeatListener): void;
}
export declare class SeatInfoDataSource extends BasicDataSource<SeatInfo> {
}
export declare class SeatUserInfoDataSource extends BasicDataSource<SeatUserInfo> {
}
export declare class AVStatisticsDataSource extends BasicDataSource<AVStatistics> {
}
