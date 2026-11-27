/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CoHostStore @ AtomicXCore
 * Function: Live host connection management related interfaces, managing creation, joining, leaving and other operations for host-to-host connections.
 */
import { SeatUserInfo, SeatUserInfoDataSource } from './LiveSeatStore';
/**
 * Current user's cross-room connection status.
 */
export declare enum CoHostStatus {
    /**
     * Currently connected with other hosts.
     */
    CONNECTED = 0,
    /**
     * Not connected with other hosts.
     */
    DISCONNECTED = 1
}
/**
 * Connection layout template.
 */
export declare enum CoHostLayoutTemplate {
    /**
     * Voice chat room connection layout.
     */
    HOST_VOICE_CONNECTION = 2,
    /**
     * Host video landscape fixed 2 seats layout.
     */
    HOST_VIDEO_LANDSCAPE_FIXED_2_SEATS = 400,
    /**
     * Host dynamic grid layout.
     */
    HOST_DYNAMIC_GRID = 600,
    /**
     * Host dynamic 1v6 layout.
     */
    HOST_DYNAMIC_1V6 = 601,
    /**
     * Host video left focus 9 seats layout.
     */
    HOST_VIDEO_LEFT_FOCUS_9_SEATS = 602,
    /**
     * Host video uniform grid 9 seats layout.
     */
    HOST_VIDEO_UNIFORM_GRID_9_SEATS = 603
}
/**
 * Cross-room connection related state data provided externally by CoHostStore.
 *
 * A comprehensive snapshot of the current cross-room connection session state. This structure contains all relevant information about connection status, connected hosts, pending invitations and applications.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [coHostStatus] | `ValueListenable<CoHostStatus>` | Real-time cross-room connection status |
 * | [connected] | `ValueListenable<List<SeatUserInfo>>` | List of hosts currently connected with current live room |
 * | [invitees] | `ValueListenable<List<SeatUserInfo>>` | List of hosts to whom requests have been sent |
 * | [applicant] | `ValueListenable<SeatUserInfo?>` | Host who initiated connection request to current live room |
 * | [candidatesCursor] | `ValueListenable<String>` | Recommended user list cursor |
 * | [candidates] | `ValueListenable<List<SeatUserInfo>>` | Recommended user list |
 *
 * > **Tip**: State is automatically updated when hosts join/leave connection, send/cancel invitations, or receive applications. Subscribe to [coHostState] to receive real-time updates.
 */
@Observed
export declare class CoHostState {
    /**
     * Real-time cross-room connection status.
     */
    coHostStatus: CoHostStatus;
    /**
     * List of hosts currently connected with current live room.
     */
    connected: SeatUserInfoDataSource;
    /**
     * List of hosts to whom requests have been sent.
     */
    invitees: SeatUserInfoDataSource;
    /**
     * Host who initiated connection request to current live room.
     */
    applicant: SeatUserInfo | undefined;
    /**
     * Recommended user list cursor.
     */
    candidatesCursor: string;
    /**
     * Recommended user list.
     */
    candidates: SeatUserInfoDataSource;
}
/**
 * Connection request callback events.
 */
export declare class CoHostListener {
    onCoHostRequestReceived?: (inviter: SeatUserInfo, extensionInfo: string) => void;
    onCoHostRequestCancelled?: (inviter: SeatUserInfo, invitee: SeatUserInfo | undefined) => void;
    onCoHostRequestAccepted?: (invitee: SeatUserInfo) => void;
    onCoHostRequestRejected?: (invitee: SeatUserInfo) => void;
    onCoHostRequestTimeout?: (inviter: SeatUserInfo, invitee: SeatUserInfo) => void;
    onCoHostUserJoined?: (userInfo: SeatUserInfo) => void;
    onCoHostUserLeft?: (userInfo: SeatUserInfo) => void;
}
/**
 * Live host connection management related interfaces, managing creation, joining, leaving and other operations for host-to-host connections.
 *
 * `CoHostStore` Manages all host-to-host connection related operations, including initiating connection requests, cancelling, accepting, rejecting and exiting connections.
 * Cross-room connection feature allows hosts from different live rooms to interact in real-time. `CoHostStore` provides a comprehensive set of APIs to manage the entire cross-room connection lifecycle.
 *
 * ### Key Features
 *
 * - **Bidirectional Connection**: Hosts can initiate connection requests to other hosts, and also receive connection requests from other hosts.
 * - **State Management**: Real-time tracking of connection status, connected hosts, invitation list and applicants.
 * - **Event-Driven Architecture**: Provides connection event stream for monitoring various connection state changes.
 * - **Layout Templates**: Supports multiple connection layout templates, such as dynamic grid layout and 1-to-6 layout.
 *
 * > **Important**: Always use the factory method [CoHostStore.create] with a valid live room ID to create a `CoHostStore` instance. Do not attempt to initialize directly.
 *
 * > **Tip**: Connection state updates are delivered through the [coHostState] publisher. Subscribe to it to receive real-time updates about connection status, connected hosts, invitations and applications.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### Connection Operations
 *
 */
export declare abstract class CoHostStore {
    protected state: CoHostState;
    get coHostState(): CoHostState;
    static create(liveID: string): CoHostStore;
    /**
     * Initiate host connection request
     *
     * Initiate a cross-room connection request to target host.
     *
     * After calling this method, a connection request is sent to the target host. The request will remain active until:
     * • Target host accepts via ``acceptHostConnection(fromHostLiveID:completion:)``
     * • Target host rejects via ``rejectHostConnection(fromHostLiveID:completion:)``
     * • Timeout expires
     * • You cancel via ``cancelHostConnection(toHostLiveID:completion:)``
     *
     * @param  Target host's live room ID.
     * @param layoutTemplate Connection layout template.
     * @param timeout Timeout in seconds. The maximum limit is 30 seconds.
     * @param extraInfo Extension information.
     */
    abstract requestHostConnection(targetHostLiveID: string, layoutTemplate: CoHostLayoutTemplate, timeout: number, extraInfo: string): Promise<void>;
    /**
     * Cancel host connection request
     *
     * @param toHostLiveID Target host's live room ID.
     */
    abstract cancelHostConnection(toHostLiveID: string): Promise<void>;
    /**
     * Accept host connection request
     *
     * @param fromHostLiveID Live room ID of the host initiating connection request.
     */
    abstract acceptHostConnection(fromHostLiveID: string): Promise<void>;
    /**
     * Reject host connection request
     *
     * @param fromHostLiveID Live room ID of the host initiating connection request.
     */
    abstract rejectHostConnection(fromHostLiveID: string): Promise<void>;
    /**
     * Exit host connection
     */
    abstract exitHostConnection(): Promise<void>;
    /**
     * Get recommended host list that can connect with current host
     *
     * @param cursor Cursor.
     */
    abstract getCoHostCandidates(cursor: string): Promise<void>;
    /**
     * Mute or unmute the audio of a remote host
     *
     * @param liveID Live ID of the remote host.
     * @param isMuted Whether to mute the remote host's audio. `true` means mute, `false` means unmute.
     */
    abstract muteRemoteHostAudio(liveID: string, isMuted: boolean): Promise<void>;
    /**
     * Add connection callback listener
     *
     * @param listener Listener.
     */
    abstract addCoHostListener(listener: CoHostListener): void;
    /**
     * Remove connection callback listener
     *
     * @param listener Listener.
     */
    abstract removeCoHostListener(listener: CoHostListener): void;
}
