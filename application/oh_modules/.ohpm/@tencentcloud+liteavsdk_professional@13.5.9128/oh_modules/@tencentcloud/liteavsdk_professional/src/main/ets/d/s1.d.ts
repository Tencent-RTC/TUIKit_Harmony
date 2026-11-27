export declare class LiteavAppRotationMonitor {
    private tag;
    private lastSensorOrientation;
    private sensorRotation;
    private displayRotation;
    private displayCallback;
    private sensorCallback;
    nativeStart(): void;
    nativeStop(): void;
    nativeGetCurrentDisplayRotation(): number;
    nativeGetCurrentSensorRotation(): number;
    nativeNotifyDisplayRotationChanged(): void;
    nativeNotifySensorRotationChanged(): void;
}
