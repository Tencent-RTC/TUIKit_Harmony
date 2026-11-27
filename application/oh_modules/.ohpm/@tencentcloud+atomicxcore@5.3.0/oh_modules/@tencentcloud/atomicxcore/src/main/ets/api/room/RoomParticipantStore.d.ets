/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   RoomParticipantStore @ AtomicXCore
 * Function: Room participant management related interfaces, managing participant permissions, device control, message muting and other operations.
 */
import { DeviceType, DeviceStatus, NetworkInfo } from '../device/DeviceStore';
import { RoomUser, ListResult } from './RoomStore';
import BasicData from '../common/BasicData';
import { RoomParticipantDataSource } from './RoomParticipantDataSource';
import { RoomAudienceDataSource } from './RoomParticipantDataSource';
/**
 * Participant role.
 */
export declare enum ParticipantRole {
    /**
     * Owner.
     */
    owner = 0,
    /**
     * Admin.
     */
    admin = 1,
    /**
     * General user.
     */
    generalUser = 2
}
/**
 * Participant status.
 */
export declare enum RoomParticipantStatus {
    scheduled = 1,
    inCalling = 2,
    callTimeout = 3,
    callRejected = 4,
    inRoom = 5
}
/**
 * Reason for being kicked out of room.
 */
export declare enum KickedOutOfRoomReason {
    kickedByAdmin = 0,
    replacedByAnotherDevice = 1,
    kickedByServer = 2,
    connectionTimeout = 3,
    invalidStatusOnReconnect = 4,
    roomLimitExceeded = 5
}
/**
 * Room participant info.
 *
 * Represents complete information of a participant in the room, including basic info and device status.
 */
@Observed
export declare class RoomParticipant extends BasicData {
    userID: string;
    userName: string;
    avatarURL: string;
    nameCard: string;
    role: ParticipantRole;
    roomStatus: RoomParticipantStatus;
    microphoneStatus: DeviceStatus;
    cameraStatus: DeviceStatus;
    screenShareStatus: DeviceStatus;
    isMessageDisabled: boolean;
    metaData: Map<string, string>;
    constructor(userID?: string, userName?: string, avatarURL?: string, nameCard?: string, role?: ParticipantRole, roomStatus?: RoomParticipantStatus, microphoneStatus?: DeviceStatus, cameraStatus?: DeviceStatus, screenShareStatus?: DeviceStatus, isMessageDisabled?: boolean, metaData?: Map<string, string>);
}
/**
 * Device request info.
 *
 * Represents device request or invitation information.
 */
export declare class DeviceRequestInfo {
    readonly timestamp: number;
    readonly senderUserID: string;
    readonly senderUserName: string;
    readonly senderNameCard: string;
    readonly senderAvatarURL: string;
    readonly content: string;
    readonly device: DeviceType;
    constructor(timestamp?: number, senderUserID?: string, senderUserName?: string, senderNameCard?: string, senderAvatarURL?: string, content?: string, device?: DeviceType);
}
/**
 * Participant related state data provided by RoomParticipantStore.
 *
 * Comprehensive snapshot of current room participant state. This structure contains all relevant information about participant list, device requests, etc.
 */
@Observed
export declare class RoomParticipantState {
    /**
     * Participant list.
     */
    participantList: RoomParticipantDataSource;
    /**
     * Participant list cursor.
     */
    participantListCursor: string;
    /**
     * Audience list (for webinar room).
     */
    audienceList: RoomAudienceDataSource;
    /**
     * Audience list cursor.
     */
    audienceListCursor: string;
    /**
     * Admin list.
     */
    adminList: RoomUser[];
    /**
     * Message disabled user list.
     */
    messageDisabledUserList: RoomUser[];
    /**
     * Participant list with video.
     */
    participantListWithVideo: RoomParticipant[];
    /**
     * Participant sharing screen.
     */
    participantWithScreen?: RoomParticipant;
    /**
     * Pending device application list.
     */
    pendingDeviceApplications: DeviceRequestInfo[];
    /**
     * Pending device invitation list.
     */
    pendingDeviceInvitations: DeviceRequestInfo[];
    /**
     * Speaking users and their volume.
     */
    speakingUsers: Map<string, number>;
    /**
     * User network quality info.
     */
    networkQualities: Map<string, NetworkInfo>;
    /**
     * Pending participant list.
     */
    pendingParticipantList: RoomParticipant[];
    /**
     * Local participant info.
     */
    localParticipant?: RoomParticipant;
}
/**
 * Participant event callback.
 */
export declare class RoomParticipantListener {
    /**
     * Triggered when a participant joins the room.
     *
     * @param participant Joined participant info.
     */
    onParticipantJoined?: (participant: RoomUser) => void;
    /**
     * Triggered when a participant leaves the room.
     *
     * @param participant Left participant info.
     */
    onParticipantLeft?: (participant: RoomUser) => void;
    /**
     * Triggered when an audience is promoted to participant.
     *
     * @param userInfo Promoted user info.
     */
    onAudiencePromotedToParticipant?: (userInfo: RoomUser) => void;
    /**
     * Triggered when a participant is demoted to audience.
     *
     * @param userInfo Demoted user info.
     */
    onParticipantDemotedToAudience?: (userInfo: RoomUser) => void;
    /**
     * Triggered when the owner changes.
     *
     * @param newOwner New owner info.
     * @param oldOwner Old owner info.
     */
    onOwnerChanged?: (newOwner: RoomUser, oldOwner: RoomUser) => void;
    /**
     * Triggered when an admin is set.
     *
     * @param userInfo User info set as admin.
     */
    onAdminSet?: (userInfo: RoomUser) => void;
    /**
     * Triggered when an admin is revoked.
     *
     * @param userInfo User info revoked from admin.
     */
    onAdminRevoked?: (userInfo: RoomUser) => void;
    /**
     * Triggered when kicked from the room.
     *
     * @param reason Reason for being kicked.
     * @param message Additional message.
     */
    onKickedFromRoom?: (reason: KickedOutOfRoomReason, message: string) => void;
    /**
     * Triggered when a participant's device is closed.
     *
     * @param device Device type.
     * @param operator Operator info.
     */
    onParticipantDeviceClosed?: (device: DeviceType, operator: RoomUser) => void;
    /**
     * Triggered when a user is muted.
     *
     * @param disable Whether muted.
     * @param operator Operator info.
     */
    onUserMessageDisabled?: (disable: boolean, operator: RoomUser) => void;
    /**
     * Triggered when all devices are disabled.
     *
     * @param device Device type.
     * @param disable Whether disabled.
     * @param operator Operator info.
     */
    onAllDevicesDisabled?: (device: DeviceType, disable: boolean, operator: RoomUser) => void;
    /**
     * Triggered when all users are muted.
     *
     * @param disable Whether muted.
     * @param operator Operator info.
     */
    onAllMessagesDisabled?: (disable: boolean, operator: RoomUser) => void;
    /**
     * Triggered when a device request is received.
     *
     * @param request Device request info.
     */
    onDeviceRequestReceived?: (request: DeviceRequestInfo) => void;
    /**
     * Triggered when a device request is cancelled.
     *
     * @param request Device request info.
     */
    onDeviceRequestCancelled?: (request: DeviceRequestInfo) => void;
    /**
     * Triggered when a device request times out.
     *
     * @param request Device request info.
     */
    onDeviceRequestTimeout?: (request: DeviceRequestInfo) => void;
    /**
     * Triggered when a device request is approved.
     *
     * @param request Device request info.
     * @param operator Operator info.
     */
    onDeviceRequestApproved?: (request: DeviceRequestInfo, operator: RoomUser) => void;
    /**
     * Triggered when a device request is rejected.
     *
     * @param request Device request info.
     * @param operator Operator info.
     */
    onDeviceRequestRejected?: (request: DeviceRequestInfo, operator: RoomUser) => void;
    /**
     * Triggered when a device request is processed.
     *
     * @param request Device request info.
     * @param operator Operator info.
     */
    onDeviceRequestProcessed?: (request: DeviceRequestInfo, operator: RoomUser) => void;
    /**
     * Triggered when a device invitation is received.
     *
     * @param invitation Device invitation info.
     */
    onDeviceInvitationReceived?: (invitation: DeviceRequestInfo) => void;
    /**
     * Triggered when a device invitation is cancelled.
     *
     * @param invitation Device invitation info.
     */
    onDeviceInvitationCancelled?: (invitation: DeviceRequestInfo) => void;
    /**
     * Triggered when a device invitation times out.
     *
     * @param invitation Device invitation info.
     */
    onDeviceInvitationTimeout?: (invitation: DeviceRequestInfo) => void;
    /**
     * Triggered when a device invitation is accepted.
     *
     * @param invitation Device invitation info.
     * @param operator Operator info.
     */
    onDeviceInvitationAccepted?: (invitation: DeviceRequestInfo, operator: RoomUser) => void;
    /**
     * Triggered when a device invitation is declined.
     *
     * @param invitation Device invitation info.
     * @param operator Operator info.
     */
    onDeviceInvitationDeclined?: (invitation: DeviceRequestInfo, operator: RoomUser) => void;
}
/**
 * Room participant management related interfaces, managing participant permissions, device control, message muting and other operations.
 *
 * `RoomParticipantStore` Manage participant permissions, device control, message muting and other operations in the room.
 * Room participant management provides complete participant lifecycle management, including permission management, device control, message muting and other features. `RoomParticipantStore` provides a comprehensive set of APIs to manage room participant related operations.
 *
 * ### Key Features
 *
 * - **Permission Management**: Supports transferring owner, setting/revoking admin, kicking users and other operations.
 * - **Device Control**: Supports closing participant devices, disabling all devices and other operations.
 * - **Message Muting**: Supports muting individual users or all users.
 * - **Device Request/Invitation**: Supports requesting to open device, inviting to open device and other bidirectional interactions.
 *
 * > **Tip**: Participant status updates are delivered through `state` publisher. Subscribe to it to receive real-time updates about participant list.
 *
 * ### Creating Instance
 * - `create` - Create object instance.
 *
 * ### Observing State and Events
 * - `state` - Reactive state containing participant list and device request info.
 * - `addRoomParticipantListener`/`removeRoomParticipantListener` - Participant event callback
 *
 * ### Participant List
 * - `getParticipantList` - Get participant list.
 * - `getAudienceList` - Get audience list (for webinar room).
 * - `searchUsers` - Search users by keyword.
 *
 * ### Audience/Participant Role Management
 * - `promoteAudienceToParticipant` - Promote audience to participant (for webinar room).
 * - `demoteParticipantToAudience` - Demote participant to audience (for webinar room).
 *
 * ### Permission Management
 * - `transferOwner` - Transfer owner.
 * - `setAdmin` - Set admin.
 * - `revokeAdmin` - Revoke admin.
 * - `kickUser` - Kick user.
 * - `updateParticipantNameCard` - Update participant name card.
 * - `updateParticipantMetaData` - Update participant metadata.
 *
 * ### Local Microphone Control
 * - `muteMicrophone` - Mute microphone.
 * - `unmuteMicrophone` - Unmute microphone.
 *
 * ### Device Control
 * - `closeParticipantDevice` - Close participant device.
 * - `disableUserMessage` - Mute user.
 * - `disableAllDevices` - Disable all devices.
 * - `disableAllMessages` - Mute all users.
 *
 * ### Device Request Operations
 * - `requestToOpenDevice` - Request to open device.
 * - `cancelOpenDeviceRequest` - Cancel open device request.
 * - `approveOpenDeviceRequest` - Approve open device request.
 * - `rejectOpenDeviceRequest` - Reject open device request.
 *
 * ### Device Invitation Operations
 * - `inviteToOpenDevice` - Invite to open device.
 * - `cancelOpenDeviceInvitation` - Cancel open device invitation.
 * - `acceptOpenDeviceInvitation` - Accept open device invitation.
 * - `declineOpenDeviceInvitation` - Decline open device invitation.
 *
 * @see ParticipantRole
 * @see RoomParticipant
 * @see RoomParticipantListener
 * @see DeviceRequestInfo
 * @see KickedOutOfRoomReason
 */
@Observed
export declare abstract class RoomParticipantStore {
    protected participantState: RoomParticipantState;
    get state(): Readonly<RoomParticipantState>;
    static create(roomID: string): RoomParticipantStore;
    /**
     * Add participant event callback listener
     *
     * @param listener Listener.
     */
    abstract addRoomParticipantListener(listener: RoomParticipantListener): void;
    /**
     * Remove participant event callback listener
     *
     * @param listener Listener.
     */
    abstract removeRoomParticipantListener(listener: RoomParticipantListener): void;
    /**
     * Get participant list
     *
     * @param cursor Pagination cursor.
     * @returns Operation result containing participant list.
     */
    abstract getParticipantList(cursor?: string): Promise<ListResult<RoomParticipant>>;
    /**
     * Get audience list (for webinar room)
     *
     * @param cursor Pagination cursor.
     * @returns Operation result containing audience list.
     */
    abstract getAudienceList(cursor?: string): Promise<ListResult<RoomUser>>;
    /**
     * Search users by keyword
     *
     * @param keyword Search keyword.
     * @returns Operation result containing user list.
     */
    abstract searchUsers(keyword: string): Promise<ListResult<RoomUser>>;
    /**
     * Promote audience to participant (for webinar room)
     *
     * @param userID User ID.
     */
    abstract promoteAudienceToParticipant(userID: string): Promise<void>;
    /**
     * Demote participant to audience (for webinar room)
     *
     * @param userID User ID.
     */
    abstract demoteParticipantToAudience(userID: string): Promise<void>;
    /**
     * Transfer owner
     *
     * @param userID User ID.
     */
    abstract transferOwner(userID: string): Promise<void>;
    /**
     * Set admin
     *
     * @param userID User ID.
     */
    abstract setAdmin(userID: string): Promise<void>;
    /**
     * Revoke admin
     *
     * @param userID User ID.
     */
    abstract revokeAdmin(userID: string): Promise<void>;
    /**
     * Kick user
     *
     * @param userID User ID.
     */
    abstract kickUser(userID: string): Promise<void>;
    /**
     * Update participant name card
     *
     * @param userID User ID.
     * @param nameCard Name card.
     */
    abstract updateParticipantNameCard(userID: string, nameCard: string): Promise<void>;
    /**
     * Update participant metadata
     *
     * @param userID User ID.
     * @param metaData Metadata.
     */
    abstract updateParticipantMetaData(userID: string, metaData: Map<string, string>): Promise<void>;
    /**
     * Mute microphone
     */
    abstract muteMicrophone(): void;
    /**
     * Unmute microphone
     */
    abstract unmuteMicrophone(): Promise<void>;
    /**
     * Close participant device
     *
     * @param userID User ID.
     * @param device Device type.
     */
    abstract closeParticipantDevice(userID: string, device: DeviceType): Promise<void>;
    /**
     * Mute user
     *
     * @param userID User ID.
     * @param disable Whether to mute.
     */
    abstract disableUserMessage(userID: string, disable: boolean): Promise<void>;
    /**
     * Disable all devices
     *
     * @param device Device type.
     * @param disable Whether to disable.
     */
    abstract disableAllDevices(device: DeviceType, disable: boolean): Promise<void>;
    /**
     * Mute all users
     *
     * @param disable Whether to mute.
     */
    abstract disableAllMessages(disable: boolean): Promise<void>;
    /**
     * Request to open device
     *
     * @param device Device type.
     * @param timeout Timeout (in seconds).
     */
    abstract requestToOpenDevice(device: DeviceType, timeout?: number): Promise<void>;
    /**
     * Cancel open device request
     *
     * @param device Device type.
     */
    abstract cancelOpenDeviceRequest(device: DeviceType): Promise<void>;
    /**
     * Approve open device request
     *
     * @param device Device type.
     * @param userID User ID.
     */
    abstract approveOpenDeviceRequest(device: DeviceType, userID: string): Promise<void>;
    /**
     * Reject open device request
     *
     * @param device Device type.
     * @param userID User ID.
     */
    abstract rejectOpenDeviceRequest(device: DeviceType, userID: string): Promise<void>;
    /**
     * Invite to open device
     *
     * @param userID User ID.
     * @param device Device type.
     * @param timeout Timeout (in seconds).
     */
    abstract inviteToOpenDevice(userID: string, device: DeviceType, timeout?: number): Promise<void>;
    /**
     * Cancel open device invitation
     *
     * @param userID User ID.
     * @param device Device type.
     */
    abstract cancelOpenDeviceInvitation(userID: string, device: DeviceType): Promise<void>;
    /**
     * Accept open device invitation
     *
     * @param userID User ID.
     * @param device Device type.
     */
    abstract acceptOpenDeviceInvitation(userID: string, device: DeviceType): Promise<void>;
    /**
     * Decline open device invitation
     *
     * @param userID User ID.
     * @param device Device type.
     */
    abstract declineOpenDeviceInvitation(userID: string, device: DeviceType): Promise<void>;
}
