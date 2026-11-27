/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   BattleStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of BattleStore. Mirrors the iOS /
 *           Android / Dart baselines.
 */
import { BattleStore, BattleListener, BattleConfig, BattleInfo, BattleRequestResult } from '../../api/live/BattleStore';
import { IStore } from '../common/IStore';
@Observed
export declare class BattleStoreImpl extends BattleStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    requestBattle(config: BattleConfig, userIDList: Array<string>, timeout: number): Promise<BattleRequestResult>;
    cancelBattleRequest(battleID: string, userIDList: Array<string>): Promise<void>;
    acceptBattle(battleID: string): Promise<void>;
    rejectBattle(battleID: string): Promise<void>;
    exitBattle(battleID: string): Promise<void>;
    addBattleListener(listener: BattleListener): void;
    removeBattleListener(listener: BattleListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private notifyRequest;
    private onModuleStateChanged;
    private static applyListModify;
    private static mapToBattleRequestResult;
    static mapToBattleInfo(raw: Object | undefined | null): BattleInfo;
    private static intToBattleEndedReason;
    private static parseObject;
    private static numberOf;
    private static stringOf;
    private static boolOf;
}
