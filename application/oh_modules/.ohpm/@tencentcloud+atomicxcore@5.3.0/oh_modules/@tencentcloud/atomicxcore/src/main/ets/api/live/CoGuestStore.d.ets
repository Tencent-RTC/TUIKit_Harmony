/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CoGuestStore @ AtomicXCore
 * Function: Live co-guest management related interfaces, managing co-guest application, invitation, acceptance, rejection and other operations between hosts and audience.
 */
import { SeatUserInfoDataSource } from './LiveSeatStore';
import { LiveUserInfo, LiveUserInfoDataSource } from './LiveAudienceStore';
/**
 * Reason for no response to co-guest invitation sent by host or co-guest request initiated by audience.
 */
export declare enum NoResponseReason {
    /**
     * Request timeout.
     */
    TIMEOUT = 0,
    /**
     * User already on seat.
     */
    ALREADY_SEATED = 1
}
/**
 * Co-guest seat layout template for simplifying co-guest seat configuration in a live room.
 *
 * This is a lightweight type that wraps a template ID (``templateId``). Use the predefined
 * constants (such as ``dynamicLayout``) for the built-in layouts, or construct an instance
 * directly with a custom template ID for a server-side configured layout.
 */
export declare class CoGuestLayoutTemplate {
    /**
     * Template ID of the co-guest seat layout.
     */
    readonly templateId: number;
    constructor(templateId: number);
    static readonly dynamicLayout: CoGuestLayoutTemplate;
    static readonly floatLayout: CoGuestLayoutTemplate;
    static readonly gridLayout: CoGuestLayoutTemplate;
    static readonly columnLayout: CoGuestLayoutTemplate;
}
/**
 * Co-guest related state data provided externally by CoGuestStore.
 *
 * A comprehensive snapshot of the current co-guest session state. This structure contains all relevant information about connected users, pending invitations and applications.
 *
 * | Property | Type | Role | Description |
 * |--------|------|------|-----------|
 * | [connected] | `ValueListenable<List<SeatUserInfo>>` | Both | List of users currently on seats |
 * | [invitees] | `ValueListenable<List<LiveUserInfo>>` | Host | Users invited by host (waiting for response) |
 * | [applicants] | `ValueListenable<List<LiveUserInfo>>` | Host | Users who applied (waiting for host decision) |
 * | [candidates] | `ValueListenable<List<LiveUserInfo>>` | Host | List of potential users available for invitation |
 *
 * > **Tip**: State is automatically updated when users join/leave seats, send/cancel invitations, or apply/cancel applications. Subscribe to [coGuestState] to receive real-time updates.
 */
@Observed
export declare class CoGuestState {
    /**
     * List of users already on seats.
     */
    connected: SeatUserInfoDataSource;
    /**
     * List of users invited by host.
     */
    invitees: LiveUserInfoDataSource;
    /**
     * List of users who applied for co-guest received by host.
     */
    applicants: LiveUserInfoDataSource;
    /**
     * List of candidate users for co-guest.
     */
    candidates: LiveUserInfoDataSource;
}
/**
 * Callback events received on host side.
 */
export declare class HostListener {
    onGuestApplicationReceived?: (guestUser: LiveUserInfo) => void;
    onGuestApplicationCancelled?: (guestUser: LiveUserInfo) => void;
    onGuestApplicationProcessedByOtherHost?: (guestUser: LiveUserInfo, hostUser: LiveUserInfo) => void;
    onHostInvitationResponded?: (isAccept: boolean, guestUser: LiveUserInfo) => void;
    onHostInvitationNoResponse?: (guestUser: LiveUserInfo, reason: NoResponseReason) => void;
}
/**
 * Callback events received on guest side.
 */
export declare class GuestListener {
    onHostInvitationReceived?: (hostUser: LiveUserInfo) => void;
    onHostInvitationCancelled?: (hostUser: LiveUserInfo) => void;
    onGuestApplicationResponded?: (isAccept: boolean, hostUser: LiveUserInfo) => void;
    onGuestApplicationNoResponse?: (reason: NoResponseReason) => void;
    onKickedOffSeat?: (seatIndex: number, hostUser: LiveUserInfo) => void;
}
/**
 * Live co-guest management related interfaces, managing co-guest application, invitation, acceptance, rejection and other operations between hosts and audience.
 *
 * `CoGuestStore` Manages all co-guest related operations between hosts and audience, including application, invitation, acceptance and rejection processes.
 * Co-guest feature enables real-time interaction between hosts and audience members through a seat-based system. `CoGuestStore` provides a comprehensive set of APIs to manage the entire co-guest lifecycle.
 *
 * ### Key Features
 *
 * - **Bidirectional Invitation**: Hosts can invite audience members, and audience members can also apply to join.
 * - **State Management**: Real-time tracking of connected users, invitations and applications.
 * - **Event-Driven Architecture**: Provides separate event streams for host and guest roles.
 * - **Timeout Handling**: Built-in timeout mechanism for invitations and applications.
 *
 * > **Important**: Always use the factory method [CoGuestStore.create] with a valid live room ID to create a `CoGuestStore` instance. Do not attempt to initialize directly.
 *
 * > **Tip**: Co-guest state updates are delivered through the [coGuestState] publisher. Subscribe to it to receive real-time updates about connected users, invitations and applications.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### Guest Operations
 *
 * ### Host Operations
 *
 * ### Connection Control
 *
 */
export declare abstract class CoGuestStore {
    protected state: CoGuestState;
    get coGuestState(): CoGuestState;
    static create(liveID: string): CoGuestStore;
    /**
     * Apply to go on seat
     *
     * Request to join co-guest session as an audience member.
     *
     * After calling this method, a co-guest request is sent to all hosts in the live room. The request will remain active until:
     * • Host accepts via [acceptApplication]
     * • Host rejects via [rejectApplication]
     * • Timeout expires
     * • You cancel via [cancelApplication]
     *
     * @param seatIndex Seat index, -1 means auto-assign seat.
     * @param timeout Timeout (unit: seconds).
     * @param extraInfo Extra information.
     */
    abstract applyForSeat(seatIndex: number, timeout: number, extraInfo: string): Promise<void>;
    /**
     * Cancel seat application
     *
     * Cancel a previously sent co-guest application. After calling this method, all hosts will be notified of the application cancellation.
     */
    abstract cancelApplication(): Promise<void>;
    /**
     * Accept seat application
     *
     * @param userID User ID.
     */
    abstract acceptApplication(userID: string): Promise<void>;
    /**
     * Reject seat application
     *
     * @param userID User ID.
     */
    abstract rejectApplication(userID: string): Promise<void>;
    /**
     * Invite audience to seat
     *
     * @param  Invited user ID.
     * @param seatIndex Seat index, -1 means auto-assign seat.
     * @param timeout Timeout in seconds. Please set a value between 5 and 1800 seconds.
     * @param extraInfo Extra information.
     */
    abstract inviteToSeat(inviteeID: string, seatIndex: number, timeout: number, extraInfo: string): Promise<void>;
    /**
     * Cancel seat invitation
     *
     * @param inviteeID Invited user ID.
     */
    abstract cancelInvitation(inviteeID: string): Promise<void>;
    /**
     * Accept seat invitation
     *
     * @param inviterID Inviter user ID.
     */
    abstract acceptInvitation(inviterID: string): Promise<void>;
    /**
     * Reject seat invitation
     *
     * @param inviterID Inviter user ID.
     */
    abstract rejectInvitation(inviterID: string): Promise<void>;
    /**
     * Disconnect co-guest
     */
    abstract disconnect(): Promise<void>;
    /**
     * Set co-guest seat layout template
     *
     * Update the co-guest seat layout template to change how seats are arranged in the current co-guest session.
     */
    abstract setLayoutTemplate(template: CoGuestLayoutTemplate): Promise<void>;
    /**
     * Add host-side event callback listener
     *
     * @param listener Listener.
     */
    abstract addHostListener(listener: HostListener): void;
    /**
     * Remove host-side event callback listener
     *
     * @param listener Listener.
     */
    abstract removeHostListener(listener: HostListener): void;
    /**
     * Add guest-side event callback listener
     *
     * @param listener Listener.
     */
    abstract addGuestListener(listener: GuestListener): void;
    /**
     * Remove guest-side event callback listener
     *
     * @param listener Listener.
     */
    abstract removeGuestListener(listener: GuestListener): void;
}
