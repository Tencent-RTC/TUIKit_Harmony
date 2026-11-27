/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicLiveControllerImpl @ AtomicXCore
 */
import { AtomicLiveController, AtomicLiveViewChangeAdapter, AtomicLiveViewType } from '../../../api/view/live/AtomicLiveView';
import { AdapterHolder, AtomicSeatLayout, AtomicViewListMode, LiveCanvas, SeatInfo } from './AtomicSeatLayout';
export declare class AtomicLiveControllerImpl extends AtomicLiveController {
    private liveID;
    private readonly viewType;
    private mode;
    private canvas;
    private seatList;
    readonly adapterHolder: AdapterHolder;
    private subscriptions;
    private seatViewIds;
    private userVolumes;
    private isViewReady;
    private adapterVersion;
    private mixSurfaceId;
    private boundMixSurfaceId;
    private mixViewIdResolvers;
    private layoutGeneration;
    onUpdate: (() => void) | undefined;
    constructor(viewType: AtomicLiveViewType);
    get moduleName(): string;
    get engineID(): string;
    get hasEngineInstance(): boolean;
    getLayoutGeneration(): number;
    getMode(): AtomicViewListMode;
    getCanvas(): LiveCanvas;
    getSeatList(): SeatInfo[];
    getAdapter(): AtomicLiveViewChangeAdapter | undefined;
    getAdapterVersion(): number;
    isOnSeat(): boolean;
    setLiveID(liveID: string): void;
    setViewChangeAdapter(adapter: AtomicLiveViewChangeAdapter): void;
    init(): void;
    unInit(): void;
    private settleMixStreamWaiters;
    private clearMixStreamState;
    subscribeEvents(): void;
    unsubscribeEvents(): void;
    private handleVolumeChanged;
    private notifyVolumeChanged;
    private handleSeatChanged;
    fetchLayout(): void;
    applyLayout(layout: AtomicSeatLayout): void;
    private hasCanvasChanged;
    private hasSeatLayoutChanged;
    updateSeat(seat: SeatInfo): void;
    private rebindSeatView;
    rebindVideoViews(): void;
    private bindMixStream;
    bind(seatIndex: string, viewId: string): void;
    unbindAll(): void;
    reset(): void;
    onMixStreamViewCreated(surfaceId: string): void;
    onMixStreamViewDisposed(surfaceId: string): void;
    getMixStreamViewId(): Promise<string>;
    onSeatViewCreated(seat: SeatInfo, viewId: string): void;
    onSeatViewDisposed(seat: SeatInfo, viewId: string): void;
    private decodeObject;
}
