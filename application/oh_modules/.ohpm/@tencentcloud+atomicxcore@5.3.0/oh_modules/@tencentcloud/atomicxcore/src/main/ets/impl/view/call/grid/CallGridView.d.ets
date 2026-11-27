/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallGridView @ AtomicXCore
 * Function: Grid layout for multi-person call.
 */
import { CallInfo, CallParticipantInfo, CallState } from '../../../../api/call/CallStore';
import { DeviceState } from '../../../../api/device/DeviceStore';
import { CallCoreController } from '../../../../api/view/call/CallCoreView';
@Component
export declare struct CallGridView {
    controller: CallCoreController;
    @ObjectLink
    callState: CallState;
    @ObjectLink
    selfInfo: CallParticipantInfo;
    @ObjectLink
    activeCall: CallInfo;
    @ObjectLink
    deviceState: DeviceState;
    @Prop
    participantCount: number;
    @State
    private largeViewId;
    @State
    private containerWidth;
    @State
    private containerHeight;
    private onParticipantsChanged;
    build(): void;
    private buildPositionedCell;
    private buildCellContent;
    private buildGestureOverlay;
    private handleCellClick;
    private getLayoutItems;
    private createFrame;
    private getContentHeight;
    private getLargeIndex;
    private getAllUsers;
    private getParticipantById;
}
