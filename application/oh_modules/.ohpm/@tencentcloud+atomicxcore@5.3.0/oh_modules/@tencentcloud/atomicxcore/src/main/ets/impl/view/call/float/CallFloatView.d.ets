/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallFloatView @ AtomicXCore
 * Function: Float layout for 1v1 call.
 */
import { CallInfo, CallParticipantInfo, CallState } from '../../../../api/call/CallStore';
import { DeviceState } from '../../../../api/device/DeviceStore';
import { CallCoreController } from '../../../../api/view/call/CallCoreView';
@Component
export declare struct CallFloatView {
    controller: CallCoreController;
    @ObjectLink
    callState: CallState;
    @ObjectLink
    selfInfo: CallParticipantInfo;
    @ObjectLink
    activeCall: CallInfo;
    @ObjectLink
    deviceState: DeviceState;
    @State
    private isViewReversed;
    @State
    private smallViewLeft;
    @State
    private smallViewTop;
    @State
    private containerWidth;
    @State
    private containerHeight;
    private dragStartLeft;
    private dragStartTop;
    build(): void;
    private buildPreAcceptLocalPreview;
    private buildParticipantSlot;
    private buildSmallWindowGestureOverlay;
    private isSlotBig;
    private localIsBig;
    private buildLocalParticipant;
    private buildRemoteParticipant;
    private getParticipantAvatarSize;
    private buildBlurBackground;
    private buildUserInfoOverlay;
    private mediaType;
    private selfStatus;
    private isAudioCall;
    private isAccepted;
    private shouldShowBlurBackground;
    private shouldShowUserInfo;
    private swapBigAndSmall;
    private getDefaultSmallViewLeft;
    private getLargeParticipantAvatarSize;
    private handleDrag;
    private getRemoteParticipant;
    private resolveRemoteIdFromActiveCall;
    private getRemoteAvatarSource;
    private hasRemoteAvatar;
    private getRemoteDisplayName;
}
