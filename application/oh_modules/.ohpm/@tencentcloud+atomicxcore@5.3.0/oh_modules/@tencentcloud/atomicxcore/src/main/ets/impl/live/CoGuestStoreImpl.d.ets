/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CoGuestStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of CoGuestStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { CoGuestStore, HostListener, GuestListener, CoGuestLayoutTemplate } from '../../api/live/CoGuestStore';
import { IStore } from '../common/IStore';
@Observed
export declare class CoGuestStoreImpl extends CoGuestStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private hostListeners;
    private guestListeners;
    constructor(roomID: string);
    applyForSeat(seatIndex: number, timeout: number, extraInfo: string): Promise<void>;
    cancelApplication(): Promise<void>;
    acceptApplication(userID: string): Promise<void>;
    rejectApplication(userID: string): Promise<void>;
    inviteToSeat(inviteeID: string, seatIndex: number, timeout: number, extraInfo: string): Promise<void>;
    cancelInvitation(inviteeID: string): Promise<void>;
    acceptInvitation(inviterID: string): Promise<void>;
    rejectInvitation(inviterID: string): Promise<void>;
    disconnect(): Promise<void>;
    setLayoutTemplate(template: CoGuestLayoutTemplate): Promise<void>;
    addHostListener(listener: HostListener): void;
    removeHostListener(listener: HostListener): void;
    addGuestListener(listener: GuestListener): void;
    removeGuestListener(listener: GuestListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private mergeUserList;
    private static applyListModify;
    private static mapToLiveUserInfo;
    private static intToNoResponseReason;
    private static parseObject;
    private static numberOf;
    private static stringOf;
    private static boolOf;
}
