/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveSummaryStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of LiveSummaryStore. State-only store:
 *           a single stateChanged subscription, no event channel and no
 *           listeners, mirroring the iOS / Android / Dart baselines.
 */
import { LiveSummaryStore } from '../../api/live/LiveSummaryStore';
import { IStore } from '../common/IStore';
@Observed
export declare class LiveSummaryStoreImpl extends LiveSummaryStore implements IStore {
    private readonly roomID;
    private stateToken;
    constructor(roomID: string);
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleStateChanged;
    private static mapToLiveSummaryData;
    private static parseObject;
    private static numberOf;
}
