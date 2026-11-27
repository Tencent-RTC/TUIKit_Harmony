/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LikeStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of LikeStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { LikeStore, LikeListener } from '../../api/live/LikeStore';
import { IStore } from '../common/IStore';
@Observed
export declare class LikeStoreImpl extends LikeStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    sendLike(count: number): Promise<void>;
    addLikeListener(listener: LikeListener): void;
    removeLikeListener(listener: LikeListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private static mapToLiveUserInfo;
    private static parseObject;
    private static numberOf;
    private static stringOf;
}
