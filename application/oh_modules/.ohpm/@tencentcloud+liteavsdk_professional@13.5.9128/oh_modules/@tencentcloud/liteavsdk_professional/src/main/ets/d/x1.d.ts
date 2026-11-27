import audio from '@ohos.multimedia.audio';
export declare class LiteavAudioRoutingManager {
    private TAG;
    nativeGetOutputDevices(): Array<audio.DeviceType>;
    nativeGetCurrentOutputDevice(): audio.DeviceType;
    nativeGetAudioScene(): audio.AudioScene;
    nativeCheckAudioSceneUpdate(): void;
    nativeStartMonitoring(): void;
    nativeStopMonitoring(): void;
    nativeNotifyTrackedAudioUsageChange(): void;
    private onPreferOutputDeviceChangeForRendererInfo;
    nativeNotifyAudioSceneChange(): void;
    nativeNotifyPreferredOutputDeviceChange(): void;
    nativeGetTrackedAudioUsage(): audio.StreamUsage;
    private audioScene;
    private intervalId;
}
