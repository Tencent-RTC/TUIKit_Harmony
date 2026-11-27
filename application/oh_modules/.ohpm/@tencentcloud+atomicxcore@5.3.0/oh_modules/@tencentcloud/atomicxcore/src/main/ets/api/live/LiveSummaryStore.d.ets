/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   LiveSummaryStore @ AtomicEngine
 * Function: Live summary state for a finished live. Handwritten (no YAML
 *           contract — this store is state-only, mirroring iOS / Android /
 *           Dart).
 */
/**
 * Aggregated statistics of a live, delivered when the live ends.
 */
export declare class LiveSummaryData {
    totalDuration: number;
    totalViewers: number;
    totalGiftsSent: number;
    totalGiftUniqueSenders: number;
    totalGiftCoins: number;
    totalLikesReceived: number;
    totalMessageSent: number;
}
@Observed
export declare class LiveSummaryState {
    summaryData: LiveSummaryData;
}
export declare abstract class LiveSummaryStore {
    protected summaryState: LiveSummaryState;
    get liveSummaryState(): LiveSummaryState;
    static create(liveID: string): LiveSummaryStore;
}
