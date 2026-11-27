import audio from '@ohos.multimedia.audio';
export declare class LiteavAudioHardwareEarMonitor {
    private TAG;
    private audioLoopback;
    private isAudioLoopbackSupported;
    nativeIsAudioLoopbackSupported(): boolean;
    nativeCreateAudioLoopback(): void;
    private onAudioLoopbackStatusChange;
    private onAudioLoopbackAvailable;
    private onAudioLoopbackError;
    nativeStartEarMonitor(): void;
    private onStartEarMonitor;
    nativeStopEarMonitor(): void;
    private onStopEarMonitor;
    nativeSetEarMonitorVolume(volume: number): void;
    nativeSetReverbPreset(preset: number): void;
    nativeSetEqualizerPreset(preset: number): void;
    nativeNotifyAudioLoopbackStatusChange(status: audio.AudioLoopbackStatus): void;
    nativeNotifyAudioLoopbackAvailable(s14: boolean): void;
    nativeNotifyAudioLoopbackError(): void;
}
