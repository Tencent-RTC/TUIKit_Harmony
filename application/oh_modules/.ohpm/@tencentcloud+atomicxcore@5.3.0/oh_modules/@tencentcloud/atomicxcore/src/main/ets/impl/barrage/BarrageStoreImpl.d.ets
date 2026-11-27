/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   BarrageStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of BarrageStore. Mirrors the iOS /
 *           Android / Dart baselines: room-scoped store with passive
 *           event / state channels and active bridge calls.
 */
import { BarrageStore, Barrage, BarrageListener } from '../../api/barrage/BarrageStore';
import { IStore } from '../common/IStore';
@Observed
export declare class BarrageStoreImpl extends BarrageStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    sendTextMessage(text: string, extensionInfo: Map<string, string>): Promise<void>;
    sendCustomMessage(businessID: string, data: string): Promise<void>;
    setMessageDisable(disable: boolean): Promise<void>;
    appendLocalTip(message: Barrage): void;
    addBarrageListener(listener: BarrageListener): void;
    removeBarrageListener(listener: BarrageListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    /**
     * Plain-array merge with append-style `add` (no key dedup), mirroring the
     * Dart baseline exactly — a barrage list may legitimately hold repeated
     * sequences, unlike gift / audience lists.
     */
    private static applyListModify;
    private static barrageToMap;
    private static mapToBarrage;
    private static mapToLiveUserInfo;
    private static parseObject;
    private static numberOf;
    private static stringOf;
    private static boolOf;
}
