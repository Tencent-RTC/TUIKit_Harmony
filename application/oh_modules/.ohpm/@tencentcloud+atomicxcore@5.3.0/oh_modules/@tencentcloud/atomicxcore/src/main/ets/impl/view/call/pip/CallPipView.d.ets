/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallPipView @ AtomicXCore
 * Function: Picture-in-picture layout.
 *   - Video call: only show video frame (CallParticipantView), nothing else
 *   - Audio call: only show avatar centered + blur background + mask (CallParticipantView handles this)
 *   - Multi call: switch to active speaker based on speakerVolumes
 *   - No nickname overlay; only call duration text overlaid on top.
 */
import { CallInfo, CallParticipantInfo, CallState } from '../../../../api/call/CallStore';
import { DeviceState } from '../../../../api/device/DeviceStore';
import { CallCoreController } from '../../../../api/view/call/CallCoreView';
@Component
export declare struct CallPipView {
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
    @Prop
    volumeUpdateTick: number;
    @State
    private showingUserId;
    @State
    private containerWidth;
    @State
    private containerHeight;
    aboutToAppear(): void;
    private onParticipantsChanged;
    private onSpeakerVolumesChanged;
    build(): void;
    private getAvatarSize;
    private updateShowingUser;
    private updateSingleCallLayout;
    private updateMultiCallLayout;
    private getShowingParticipant;
    private getRemoteUserId;
    private isMultiCall;
}
