/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicPusherImpl @ AtomicXCore
 */
import { IAtomicPusherImpl, PusherInfo, PusherInfoModifyFlag, PusherListener, PusherState } from '../../api/live/AtomicPusher';
import { AtomicLiveView } from '../../api/view/live/AtomicLiveView';
export declare class AtomicPusherImpl implements IAtomicPusherImpl {
    private readonly state;
    private readonly listeners;
    private view;
    private liveID;
    private eventToken;
    private stateToken;
    constructor();
    private ensureSubscribed;
    private safeCall;
    getState(): PusherState;
    addListener(listener?: PusherListener): void;
    removeListener(listener?: PusherListener): void;
    setView(view: AtomicLiveView): void;
    startPush(config: PusherInfo): void;
    /**
     * Binds the live ID to the render view. `setLiveID` is SDK-internal on the
     * controller (mirrors Android, where it is an `internal` API).
     */
    private bindView;
    stopPush(): void;
    updateConfig(config: PusherInfo, modifyFlagList: Array<PusherInfoModifyFlag>): void;
    enableAdvancedFeature(key: string, value: Object): void;
    private static advancedFeatureParam;
    release(): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private resetState;
    private liveInfoMap;
    /**
     * Parses a JSON object payload. Mirrors `as? [String: Any]` on iOS and
     * `as? Map` on Android: any non-object payload is dropped.
     */
    private parseObject;
    /**
     * Reads a nested object, mirroring the checked casts on iOS / Android: a
     * scalar `statisticsData` yields undefined instead of an all-zero object.
     */
    private recordOf;
    /** Reads a number field with a runtime type check (`as?` equivalent). */
    private numberOf;
    /** Reads a string field with a runtime type check (`as?` equivalent). */
    private stringOf;
    /** Reads a boolean field with a runtime type check (`as?` equivalent). */
    private boolOf;
    private mapToPusherStatistics;
    private mapToPusherInfo;
    private mapToPusherSummary;
    private static statisticsEquals;
    private static pusherInfoEquals;
    private static numberListEquals;
    private static stringMapEquals;
    private pusherCodeFromValue;
    private pusherConnectStateFromValue;
    private endedReasonFromValue;
    private kickedOutReasonFromValue;
}
