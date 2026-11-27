/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveSeatStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of LiveSeatStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { LiveSeatStore, LiveSeatListener, SeatUserInfo, SeatInfo, RegionInfo, AVStatistics, MoveSeatPolicy, DeviceControlPolicy, SuspendStatus, SeatMode } from '../../api/live/LiveSeatStore';
import { DeviceStatus } from '../../api/device/DeviceStore';
import { IStore } from '../common/IStore';
@Observed
export declare class LiveSeatStoreImpl extends LiveSeatStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    takeSeat(seatIndex: number): Promise<void>;
    leaveSeat(): Promise<void>;
    muteMicrophone(): void;
    unmuteMicrophone(): Promise<void>;
    kickUserOutOfSeat(userID: string): Promise<void>;
    moveUserToSeat(userID: string, targetIndex: number, policy: MoveSeatPolicy): Promise<void>;
    setSeatMode(mode: SeatMode): Promise<void>;
    setFeaturedHost(userID: string): Promise<void>;
    revokeFeaturedHost(userID: string): Promise<void>;
    lockSeat(seatIndex: number): Promise<void>;
    unlockSeat(seatIndex: number): Promise<void>;
    openRemoteCamera(userID: string, policy: DeviceControlPolicy): Promise<void>;
    closeRemoteCamera(userID: string): Promise<void>;
    openRemoteMicrophone(userID: string, policy: DeviceControlPolicy): Promise<void>;
    closeRemoteMicrophone(userID: string): Promise<void>;
    addLiveSeatEventListener(listener: LiveSeatListener): void;
    removeLiveSeatEventListener(listener: LiveSeatListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private static applyListModify;
    static intToDeviceControlPolicy(value: Object | undefined): DeviceControlPolicy;
    static intToDeviceStatus(value: Object | undefined): DeviceStatus;
    static intToSuspendStatus(value: Object | undefined): SuspendStatus;
    static mapToSeatInfo(raw: Record<string, Object> | undefined | null): SeatInfo;
    static mapToSeatUserInfo(raw: Object | undefined | null): SeatUserInfo;
    static mapToRegionInfo(raw: Object | undefined | null): RegionInfo;
    static mapToAVStatistics(raw: Record<string, Object> | undefined | null): AVStatistics;
    static parseObject(json: string): Record<string, Object> | undefined;
    static numberOf(dict: Record<string, Object>, key: string, fallback: number): number;
    static stringOf(dict: Record<string, Object>, key: string, fallback: string): string;
    static boolOf(dict: Record<string, Object>, key: string, fallback: boolean): boolean;
}
