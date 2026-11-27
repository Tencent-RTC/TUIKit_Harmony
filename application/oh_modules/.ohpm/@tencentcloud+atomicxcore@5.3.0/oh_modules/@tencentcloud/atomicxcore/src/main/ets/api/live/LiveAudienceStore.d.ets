/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveAudienceStore @ AtomicXCore
 * Function: Live audience related interfaces, managing audience list, permission settings and other operations.
 */
import BasicDataSource from '../common/BasicDataSource';
import BasicData from '../common/BasicData';
/**
 * User role.
 */
export declare enum Role {
    /**
     * Room owner.
     */
    OWNER = 0,
    /**
     * Administrator.
     */
    ADMIN = 1,
    /**
     * General user.
     */
    GENERAL_USER = 2
}
/**
 * Live user information.
 *
 * Contains basic user information including unique user ID, name, and avatar URL.
 */
export declare class LiveUserInfo extends BasicData {
    /**
     * User unique identifier ID.
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
    /**
     * User level.
     */
    level: number;
}
/**
 * Live audience state.
 *
 * Contains audience list, audience count, admin list, and muted user list information.
 */
@Observed
export declare class LiveAudienceState {
    /**
     * Audience list.
     */
    audienceList: LiveUserInfoDataSource;
    /**
     * Audience count.
     */
    audienceCount: number;
    /**
     * Administrator list.
     */
    adminList: LiveUserInfoDataSource;
    /**
     * List of users banned from sending messages.
     */
    messageBannedUserList: LiveUserInfoDataSource;
}
export declare class LiveAudienceListener {
    onOwnerJoined?: (owner: LiveUserInfo) => void;
    onOwnerLeft?: (owner: LiveUserInfo) => void;
    onAdminJoined?: (admin: LiveUserInfo) => void;
    onAdminLeft?: (admin: LiveUserInfo) => void;
    onAudienceJoined?: (audience: LiveUserInfo) => void;
    onAudienceLeft?: (audience: LiveUserInfo) => void;
    onAudienceMessageDisabled?: (audience: LiveUserInfo, isDisable: boolean) => void;
}
/**
 * Live audience related interfaces, managing audience list, permission settings and other operations.
 *
 * `LiveAudienceStore` Live audience management class for managing audience list, permission settings and related business.
 * `LiveAudienceStore` provides a complete set of audience management APIs, including fetching audience list, setting administrators, kicking users, muting, etc.
 * Through this class, you can implement audience management functions in live rooms.
 *
 * ### Key Features
 *
 * - **Audience List**: Get and manage the audience list of the current room.
 * - **Permission Management**: Set and revoke administrator permissions.
 * - **User Management**: Kick users, mute, and other operations.
 * - **Event Listening**: Listen for owner, admin, and audience join/leave events.
 *
 * > **Important**: Use the [LiveAudienceStore.create] factory method to create a `LiveAudienceStore` instance, which requires a valid live room ID.
 *
 * > **Tip**: Audience state updates are delivered through the [liveAudienceState] publisher. Subscribe to it to receive real-time updates of audience data in the room.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### Audience Management
 *
 */
export declare abstract class LiveAudienceStore {
    protected state: LiveAudienceState;
    get liveAudienceState(): LiveAudienceState;
    static create(liveID: string): LiveAudienceStore;
    /**
     * Fetch audience list
     */
    abstract fetchAudienceList(): Promise<void>;
    /**
     * Set administrator
     *
     * @param userID User ID to be set as administrator.
     */
    abstract setAdministrator(userID: string): Promise<void>;
    /**
     * Revoke administrator
     *
     * @param userID User ID to revoke administrator permission.
     */
    abstract revokeAdministrator(userID: string): Promise<void>;
    /**
     * Kick user out of room
     *
     * @param userID User ID to be kicked out.
     */
    abstract kickUserOutOfRoom(userID: string): Promise<void>;
    /**
     * Disable/enable user message sending
     *
     * @param userID Target user ID.
     * @param isDisable true to disable message sending, false to enable.
     */
    abstract disableSendMessage(userID: string, isDisable: boolean): Promise<void>;
    /**
     * Add audience event listener
     *
     * @param listener Listener.
     */
    abstract addLiveAudienceListener(listener: LiveAudienceListener): void;
    /**
     * Remove audience event listener
     *
     * @param listener Listener.
     */
    abstract removeLiveAudienceListener(listener: LiveAudienceListener): void;
}
export declare class LiveUserInfoDataSource extends BasicDataSource<LiveUserInfo> {
}
