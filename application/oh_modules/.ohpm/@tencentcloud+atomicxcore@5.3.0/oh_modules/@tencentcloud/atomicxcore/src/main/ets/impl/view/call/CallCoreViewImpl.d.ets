/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallCoreViewImpl @ AtomicXCore
 * Function: Internal implementation of CallCoreView.
 */
import { CallInfo, CallParticipantInfo, CallState } from '../../../api/call/CallStore';
import { DeviceState } from '../../../api/device/DeviceStore';
import { CallCoreController, CallLayoutTemplate } from '../../../api/view/call/CallCoreView';
@Component
export declare struct CallCoreViewImpl {
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
    currentTemplate: CallLayoutTemplate;
    aboutToAppear(): void;
    aboutToDisappear(): void;
    build(): void;
    private isGroupCall;
}
