/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CoHostStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of CoHostStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { CoHostStore, CoHostListener, CoHostLayoutTemplate } from '../../api/live/CoHostStore';
import { IStore } from '../common/IStore';
@Observed
export declare class CoHostStoreImpl extends CoHostStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    requestHostConnection(targetHostLiveID: string, layoutTemplate: CoHostLayoutTemplate, timeout: number, extraInfo: string): Promise<void>;
    cancelHostConnection(toHostLiveID: string): Promise<void>;
    acceptHostConnection(fromHostLiveID: string): Promise<void>;
    rejectHostConnection(fromHostLiveID: string): Promise<void>;
    exitHostConnection(): Promise<void>;
    getCoHostCandidates(cursor: string): Promise<void>;
    muteRemoteHostAudio(liveID: string, isMuted: boolean): Promise<void>;
    addCoHostListener(listener: CoHostListener): void;
    removeCoHostListener(listener: CoHostListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private mergeUserList;
    private static applyListModify;
    /** A missing / empty payload maps to undefined, mirroring the Dart baseline. */
    private static mapToSeatUserInfoOrNull;
    private static parseObject;
    private static numberOf;
    private static stringOf;
}
