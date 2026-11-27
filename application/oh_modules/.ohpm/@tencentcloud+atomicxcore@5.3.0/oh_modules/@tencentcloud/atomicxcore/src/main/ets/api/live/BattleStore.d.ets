/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   BattleStore @ AtomicXCore
 * Function: Live PK management APIs for creating, joining, and leaving PK sessions.
 */
import { SeatUserInfo, SeatUserInfoDataSource } from './LiveSeatStore';
/**
 * Reason for PK ending received by users in an ongoing PK.
 */
export declare enum BattleEndedReason {
    /**
     * PK countdown ended.
     */
    TIME_OVER = 0,
    /**
     * All PK members exited.
     */
    ALL_MEMBER_EXIT = 1
}
/**
 * PK configuration information set when sending a PK request.
 *
 * PK configuration information for setting PK duration, whether response is needed, and other parameters.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [duration] | `int` | {'PK duration (unit': 'seconds)'} |
 * | [needResponse] | `bool` | Whether the invitee needs to reply with accept/reject |
 * | [extensionInfo] | `String` | Extension information |
 */
export declare class BattleConfig {
    /**
     * PK duration (unit: seconds).
     */
    duration: number;
    /**
     * Whether the invitee needs to reply with accept/reject.
     */
    needResponse: boolean;
    /**
     * Extension information.
     */
    extensionInfo: string;
}
/**
 * PK information.
 *
 * PK information, containing PK ID, configuration information, start time, and end time.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [battleID] | `String` | PK ID |
 * | [config] | [BattleConfig] | PK configuration information |
 * | [startTime] | `int` | {'PK start timestamp (unit': 'seconds)'} |
 * | [endTime] | `int` | {'PK end timestamp (unit': 'seconds)'} |
 */
export declare class BattleInfo {
    /**
     * PK ID.
     */
    battleID: string;
    /**
     * PK configuration information set when sending a PK request.
     */
    config: BattleConfig;
    /**
     * PK start marker timestamp (unit: seconds).
     */
    startTime: number;
    /**
     * PK end marker timestamp (unit: seconds).
     */
    endTime: number;
}
/**
 * PK-related state data provided by BattleStore.
 *
 * A comprehensive snapshot of the current PK session state. This structure contains all relevant information about current PK information, participating users, and scores.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [currentBattleInfo] | `ValueListenable<BattleInfo?>` | Current PK information |
 * | [battleUsers] | `ValueListenable<List<SeatUserInfo>>` | PK user list |
 * | [battleScore] | `ValueListenable<Map<String, int>>` | PK score mapping |
 *
 * > **Tip**: State is automatically updated when PK starts/ends, users join/exit PK, or scores are updated. Subscribe to [battleState] to receive real-time updates.
 */
@Observed
export declare class BattleState {
    /**
     * Current PK information.
     */
    currentBattleInfo: BattleInfo | undefined;
    /**
     * PK user list.
     */
    battleUsers: SeatUserInfoDataSource;
    /**
     * PK score mapping.
     */
    battleScore: Map<string, number>;
}
/**
 * PK-related callback events received.
 */
export declare class BattleListener {
    onBattleStarted?: (battleInfo: BattleInfo, inviter: SeatUserInfo, invitees: Array<SeatUserInfo>) => void;
    onBattleEnded?: (battleInfo: BattleInfo, reason: BattleEndedReason) => void;
    onUserJoinBattle?: (battleID: string, battleUser: SeatUserInfo) => void;
    onUserExitBattle?: (battleID: string, battleUser: SeatUserInfo) => void;
    onBattleRequestReceived?: (battleID: string, inviter: SeatUserInfo, invitee: SeatUserInfo) => void;
    onBattleRequestCancelled?: (battleID: string, inviter: SeatUserInfo, invitee: SeatUserInfo) => void;
    onBattleRequestTimeout?: (battleID: string, inviter: SeatUserInfo, invitee: SeatUserInfo) => void;
    onBattleRequestAccept?: (battleID: string, inviter: SeatUserInfo, invitee: SeatUserInfo) => void;
    onBattleRequestReject?: (battleID: string, inviter: SeatUserInfo, invitee: SeatUserInfo) => void;
}
/**
 * Live PK management APIs for creating, joining, and leaving PK sessions.
 *
 * `BattleStore` Manages all PK-related operations between hosts,
 * including initiating, accepting, rejecting, and exiting processes.
 * PK feature enables real-time interactive battles between hosts. `BattleStore` provides a comprehensive set of APIs to manage the entire PK lifecycle.
 *
 * ### Key Features
 *
 * - **PK Request Management**: Hosts can initiate PK requests, and invitees can accept or reject.
 * - **State Management**: Real-time tracking of PK information, participating users, and scores.
 * - **Event-Driven Architecture**: Provides complete PK event callbacks.
 * - **Timeout Handling**: Built-in timeout mechanism for PK requests.
 *
 * > **Important**: Always use the factory method {ref} with a valid live room ID to create a `BattleStore` instance. Do not attempt to initialize directly.
 *
 * > **Tip**: PK state updates are delivered through the [battleState] publisher. Subscribe to it to receive real-time updates about PK information, participating users, and scores.
 *
 * ### Creating Instance
 *
 * ### Observing State and Events
 *
 * ### PK Operations
 *
 */
export declare abstract class BattleStore {
    protected state: BattleState;
    get battleState(): BattleState;
    static create(liveID: string): BattleStore;
    /**
     * Initiate PK request
     *
     * @param config PK configuration.
     * @param userIDList List of user IDs to invite for PK. Please pass in the user IDs of the other hosts you wish to PK with. Note: do not include the current user's own ID in this list.
     * @param timeout Timeout in seconds. The maximum limit is 30 seconds.
     */
    abstract requestBattle(config: BattleConfig, userIDList: Array<string>, timeout: number): Promise<BattleRequestResult>;
    /**
     * Cancel PK request
     *
     * @param  PK ID.
     * @param  User ID list.
     */
    abstract cancelBattleRequest(battleID: string, userIDList: Array<string>): Promise<void>;
    /**
     * Accept PK request
     *
     * @param battleID PK ID.
     */
    abstract acceptBattle(battleID: string): Promise<void>;
    /**
     * Reject PK request
     *
     * @param battleID PK ID.
     */
    abstract rejectBattle(battleID: string): Promise<void>;
    /**
     * Exit PK
     *
     * @param battleID PK ID.
     */
    abstract exitBattle(battleID: string): Promise<void>;
    /**
     * Add PK callback listener
     *
     * @param listener Listener.
     */
    abstract addBattleListener(listener: BattleListener): void;
    /**
     * Remove PK callback listener
     *
     * @param listener Listener.
     */
    abstract removeBattleListener(listener: BattleListener): void;
}
export declare class BattleRequestResult {
    battleInfo: BattleInfo;
    resultMap: Map<string, number>;
}
