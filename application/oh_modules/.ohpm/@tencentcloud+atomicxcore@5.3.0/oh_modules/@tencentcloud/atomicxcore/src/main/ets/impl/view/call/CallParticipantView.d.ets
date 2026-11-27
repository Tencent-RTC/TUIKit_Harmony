/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallParticipantView @ AtomicXCore
 * Function: Single participant video view with avatar, volume and network indicators.
 */
import { VolumeLevel } from './CallViewConstants';
import { CallParticipantInfo, CallState } from '../../../api/call/CallStore';
import { DeviceState, NetworkQuality } from '../../../api/device/DeviceStore';
@Component
export declare struct CallParticipantView {
    @ObjectLink
    participant: CallParticipantInfo;
    @ObjectLink
    callState: CallState;
    @ObjectLink
    selfInfo: CallParticipantInfo;
    @ObjectLink
    deviceState: DeviceState;
    @Prop
    waitingAnimationSource: ResourceStr;
    volumeLevelIcons: Map<VolumeLevel, ResourceStr>;
    networkQualityIcons: Map<NetworkQuality, ResourceStr>;
    @Prop
    avatarSource: ResourceStr;
    @Prop
    defaultAvatarSource: ResourceStr;
    @Prop
    showName: boolean;
    @Prop
    showStatusIcons: boolean;
    @Prop
    isShowAvatar: boolean;
    @Prop
    avatarWidth: number;
    @Prop
    avatarHeight: number;
    @Prop
    avatarBorderRadius: number;
    @Prop
    isLocal: boolean;
    private videoViewId;
    private videoManager;
    private boundRemoteUserId;
    private localBound;
    private lastCameraOn;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    build(): void;
    private isCameraOn;
    private buildVideoView;
    private bindCurrent;
    private unbindAll;
    private onParticipantChanged;
    private onDeviceStateChanged;
    private buildAvatarBackground;
    private buildForegroundAvatar;
    private buildWaitingAnimation;
    private buildBottomInfoBar;
    private isLoginUser;
    private getVolume;
    private getVolumeLevel;
    private getNetworkQuality;
    private shouldShowVolumeIcon;
    private hasAvatarSource;
    private getAvatarSource;
    private static hasSource;
    private getDisplayName;
    private getVolumeIcon;
    private getNetworkIcon;
    private hasNetworkIcon;
}
