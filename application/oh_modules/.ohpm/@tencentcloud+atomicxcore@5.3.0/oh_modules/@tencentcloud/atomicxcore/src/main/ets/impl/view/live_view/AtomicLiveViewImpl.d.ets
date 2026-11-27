/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicLiveViewImpl @ AtomicXCore
 */
import { AtomicLiveView } from '../../../api/view/live/AtomicLiveView';
@Component
export declare struct AtomicLiveViewImpl {
    view: AtomicLiveView;
    private viewId;
    private mixSurfaceController;
    private mixSurfaceId;
    @State
    private layoutGeneration;
    @State
    private layoutMode;
    @State
    private seatList;
    @State
    private componentWidth;
    @State
    private componentHeight;
    @State
    private adapterVersion;
    private getCtrl;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    private onControllerUpdate;
    private canvasWidthPx;
    private canvasHeightPx;
    private canvasLeftPx;
    private mixXComponentId;
    private seatTransform;
    private multiSeat;
    private sortedSeats;
    private seatFrameLeft;
    private seatFrameTop;
    private seatFrameWidth;
    private seatFrameHeight;
    private pxPerVp;
    private seatFrameRects;
    private seatVisibleRects;
    private seatClipShape;
    private seatResponseRegion;
    build(): void;
    private mixClipPath;
    private buildMixStream;
    private onMixSurfaceReady;
    private onMixSurfaceReleased;
}
