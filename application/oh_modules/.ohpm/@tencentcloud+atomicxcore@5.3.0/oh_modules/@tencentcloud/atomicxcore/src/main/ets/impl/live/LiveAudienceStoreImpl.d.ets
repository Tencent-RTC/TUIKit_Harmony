/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveAudienceStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of LiveAudienceStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { LiveAudienceStore, LiveAudienceListener } from '../../api/live/LiveAudienceStore';
import { IStore } from '../common/IStore';
@Observed
export declare class LiveAudienceStoreImpl extends LiveAudienceStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    fetchAudienceList(): Promise<void>;
    setAdministrator(userID: string): Promise<void>;
    revokeAdministrator(userID: string): Promise<void>;
    kickUserOutOfRoom(userID: string): Promise<void>;
    disableSendMessage(userID: string, isDisable: boolean): Promise<void>;
    addLiveAudienceListener(listener: LiveAudienceListener): void;
    removeLiveAudienceListener(listener: LiveAudienceListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private notify;
    private mergeList;
    /**
     * Plain-array merge with upsert-style `add` (keyed dedup), mirroring the
     * Dart baseline for user lists — a user may not appear twice.
     */
    private static applyListModify;
    private static mapToLiveUserInfo;
    private static parseObject;
    private static numberOf;
    private static stringOf;
    private static boolOf;
}
