/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   RoomParticipantView @ AtomicXCore
 * Function: Room participant video view for displaying participant video streams.
 */
import { RoomParticipantController } from './RoomParticipantController';
/**
 * View for displaying room participant video stream.
 *
 * This component renders the video stream of a room participant.
 * Use `RoomParticipantController` to control the video display.
 */
@Component
export declare struct RoomParticipantView {
    controller: RoomParticipantController;
    private log;
    private viewID;
    @State
    private lastWidth;
    @State
    private currentScale;
    @State
    private pivotX;
    @State
    private pivotY;
    private pressedPoint1X;
    private pressedPoint1Y;
    private pressedPoint2X;
    private pressedPoint2Y;
    private distBeforeMove;
    private distAfterMove;
    private activePointerCount;
    private touchDownX;
    private touchDownY;
    private isClickAction;
    private componentWidth;
    private componentHeight;
    private cameraSubscription;
    private getCtrl;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    build(): void;
    private handleTouchEvent;
    private resetDoubleTouchState;
    private handleTwoFingerScaling;
    private setSelfPivot;
    private spacing;
    private initializeEngine;
    private isReady;
    private onControllerUpdate;
    private initView;
    private initRemoteCameraView;
    private initRemoteScreenShareView;
    private applyFillMode;
    private stop;
    private destroy;
    private onLayoutWidthChanged;
}
