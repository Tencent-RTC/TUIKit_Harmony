/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   GiftStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of GiftStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { GiftStore, GiftListener } from '../../api/gift/GiftStore';
import { IStore } from '../common/IStore';
@Observed
export declare class GiftStoreImpl extends GiftStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    setLanguage(language: string): void;
    refreshUsableGifts(): Promise<void>;
    sendGift(giftID: string, count: number, receiver: string): Promise<void>;
    setGiftEnabled(enabled: boolean): Promise<void>;
    addGiftListener(listener: GiftListener): void;
    removeGiftListener(listener: GiftListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    /**
     * Plain-array merge with upsert-style `add` (keyed dedup), mirroring the
     * Dart baseline — a gift category / a receiver statistic may not appear
     * twice.
     */
    private static applyListModify;
    private static mapToGift;
    private static mapToGiftCategory;
    private static mapToGiftStatisticInfo;
    private static mapToLiveUserInfo;
    private static stringMapOf;
    private static parseObject;
    private static numberOf;
    private static stringOf;
    private static boolOf;
}
