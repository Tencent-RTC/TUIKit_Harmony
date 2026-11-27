import common from '@ohos.app.ability.common';
export declare class LiteavAudioEventMonitor {
    private TAG;
    private appStateChangeCallback;
    private callStateToString;
    private callStateChangeCallback;
    nativeStartMonitoring(context: common.ApplicationContext): void;
    nativeStopMonitoring(context: common.ApplicationContext): void;
    nativeNotifyBackgroundStateChange(state: number): void;
    nativeNotifyTelephoneStateChange(state: number): void;
}
