/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveListStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of LiveListStore. Mirrors the iOS /
 *           Android / Dart baselines: a process-wide singleton that owns the
 *           live list, the current live and the live-list lifecycle calls.
 */
import { LiveListStore, LiveInfo, LiveListListener, LiveStatisticsData, ModifyFlag } from '../../api/live/LiveListStore';
import { ExperimentalEventCallback } from '../../api/Define';
import { SubscriptionToken } from '../../engine/EngineBridge';
import { IStore } from '../common/IStore';
@Observed
export declare class LiveListStoreImpl extends LiveListStore implements IStore {
    private static readonly log;
    private static instance;
    static shared(): LiveListStoreImpl;
    private listeners;
    private constructor();
    beforeEnterRoom(_roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(_roomID: string): void;
    fetchLiveList(cursor: string, count: number): Promise<void>;
    fetchLiveInfo(liveID: string): Promise<LiveInfo>;
    startLive(liveInfo: LiveInfo): Promise<LiveInfo>;
    joinLive(liveID: string): Promise<LiveInfo>;
    leaveLive(): Promise<void>;
    endLive(): Promise<LiveStatisticsData>;
    updateLiveInfo(liveInfo: LiveInfo, modifyFlagList: Array<ModifyFlag>): Promise<void>;
    queryMetaData(keys: Array<string>): Promise<Map<string, string>>;
    updateLiveMetaData(metaData: Map<string, string>): Promise<void>;
    callExperimentalAPI(jsonMap: Record<string, Object>, callback?: (code: number, message: string, data: string) => void): void;
    subscribeExperimentalEvent(event: string, callback: ExperimentalEventCallback): SubscriptionToken;
    unsubscribeExperimentalEvent(token: SubscriptionToken): void;
    reset(): void;
    addLiveListListener(listener: LiveListListener): void;
    removeLiveListListener(listener: LiveListListener): void;
    private onModuleEvent;
    private onModuleStateChanged;
    /**
     * Plain-array list merge, mirroring the Dart `_applyListModify` and the
     * room participant store on this platform. Applied to the data source as a
     * whole: full replaces, add upserts by key, remove filters, replace
     * substitutes matching keys while keeping the current order.
     */
    private static applyListModify;
    private callAsLiveInfo;
    private static parseObject;
    private static recordOf;
    private static numberOf;
    private static stringOf;
    private static intToLiveEndedReason;
    private static intToLiveKickedOutReason;
    private static intToLiveStatus;
    private static intToTakeSeatMode;
    /** Reverse-resolves a template from its ID and seat count. */
    private static mapToSeatLayoutTemplate;
    private static mapToLiveUserInfo;
    private static liveUserInfoToMap;
    private static mapToLiveInfo;
    private static liveInfoToMap;
    private static mapToLiveStatisticsData;
    private static boolOf;
    private static numberListOf;
}
