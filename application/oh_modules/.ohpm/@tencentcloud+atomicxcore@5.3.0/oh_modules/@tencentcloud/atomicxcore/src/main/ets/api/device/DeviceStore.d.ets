/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   DeviceStore @ AtomicXCore
 * Function: Device related interfaces, operating microphone, camera, etc.
 */
/**
 * Device type.
 */
export declare enum DeviceType {
    /**
     * Microphone type.
     */
    microphone = 1,
    /**
     * Camera type.
     */
    camera = 2,
    /**
     * Screen sharing type.
     */
    screenShare = 3
}
/**
 * Device related error codes.
 */
export declare enum DeviceError {
    /**
     * Operation successful.
     */
    noError = 0,
    /**
     * No device detected.
     */
    noDeviceDetected = 1,
    /**
     * No system permission.
     */
    noSystemPermission = 2,
    /**
     * Capture not supported.
     */
    notSupportCapture = 3,
    /**
     * Device occupied.
     */
    occupiedError = 4,
    /**
     * Unknown error.
     */
    unknownError = 5
}
/**
 * Device on/off status.
 */
export declare enum DeviceStatus {
    /**
     * Off.
     */
    off = 0,
    /**
     * On.
     */
    on = 1
}
/**
 * Audio route.
 */
export declare enum AudioRoute {
    /**
     * Speaker, using speaker to play (i.e., "hands-free"), located at the bottom of the phone, louder sound, suitable for playing music out loud.
     */
    speakerphone = 0,
    /**
     * Earpiece, using earpiece to play, located at the top of the phone, quieter sound, suitable for private call scenarios.
     */
    earpiece = 1
}
/**
 * Video quality level. The final encoding resolution is determined by the combination of this level and VideoOrientation: landscape keeps the base resolution (width x height), portrait swaps the width and height.
 */
export declare enum VideoQuality {
    /**
     * 360P. Landscape resolution is 640 x 360; portrait (width and height swapped) is 360 x 640.
     */
    quality360P = 1,
    /**
     * 540P. Landscape resolution is 960 x 540; portrait (width and height swapped) is 540 x 960.
     */
    quality540P = 2,
    /**
     * 720P. Landscape resolution is 1280 x 720; portrait (width and height swapped) is 720 x 1280.
     */
    quality720P = 3,
    /**
     * 1080P. Landscape resolution is 1920 x 1080; portrait (width and height swapped) is 1080 x 1920.
     */
    quality1080P = 4
}
/**
 * Video orientation. Combined with VideoQuality to determine the final encoding resolution: landscape keeps the base resolution (width x height), portrait swaps the width and height.
 */
export declare enum VideoOrientation {
    /**
     * Landscape, the encoding resolution width is greater than the height (e.g. 1280 x 720).
     */
    landscape = 0,
    /**
     * Portrait, the encoding resolution height is greater than the width (e.g. 720 x 1280).
     */
    portrait = 1
}
/**
 * Network quality.
 */
export declare enum NetworkQuality {
    /**
     * Unknown network.
     */
    unknown = 0,
    /**
     * Excellent.
     */
    excellent = 1,
    /**
     * Good.
     */
    good = 2,
    /**
     * Poor.
     */
    poor = 3,
    /**
     * Bad.
     */
    bad = 4,
    /**
     * Very bad.
     */
    veryBad = 5,
    /**
     * Disconnected.
     */
    down = 6
}
/**
 * Camera mirror state.
 */
export declare enum MirrorType {
    /**
     * Auto, front camera mirrored, rear camera not mirrored.
     */
    auto = 0,
    /**
     * Both front and rear cameras mirrored.
     */
    enable = 1,
    /**
     * Neither front nor rear camera mirrored.
     */
    disable = 2
}
/**
 * Network type.
 */
export declare enum NetworkType {
    /**
     * Unknown or unidentified network type.
     */
    unknown = 0,
    /**
     * WiFi network connection.
     */
    wifi = 1,
    /**
     * Cellular/mobile data network connection.
     */
    cellular = 2
}
/**
 * Device information.
 */
export declare class DeviceInfo {
    /**
     * Device ID.
     */
    deviceId: string;
    /**
     * Device name.
     */
    deviceName: string;
}
/**
 * Network information.
 *
 * Data structure for network status information, containing user ID, network quality, packet loss rate and latency.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [userID] | `String` | User unique ID |
 * | [quality] | [NetworkQuality] | Network quality |
 * | [upLoss] | `int` | Uplink packet loss rate, with a value range from 0 to 100 |
 * | [downLoss] | `int` | Downlink packet loss rate, with a value range from 0 to 100 |
 * | [delay] | `int` | {'Latency (unit': 'milliseconds)'} |
 */
export declare class NetworkInfo {
    /**
     * User unique ID.
     */
    userID: string;
    /**
     * Network quality.
     */
    quality: NetworkQuality;
    /**
     * Uplink packet loss rate, with a value range from 0 to 100.
     */
    upLoss: number;
    /**
     * Downlink packet loss rate, with a value range from 0 to 100.
     */
    downLoss: number;
    /**
     * Latency (unit: milliseconds).
     */
    delay: number;
    constructor(userID?: string, quality?: NetworkQuality, upLoss?: number, downLoss?: number, delay?: number);
}
/**
 * Device state.
 *
 * A comprehensive snapshot of device state, containing all device-related status information including microphone, camera, screen sharing and network.
 *
 * | Property | Type | Description |
 * |--------|------|-----------|
 * | [microphoneStatus] | `ValueListenable<DeviceStatus>` | Microphone status |
 * | [microphoneLastError] | `ValueListenable<DeviceError>` | Microphone error |
 * | [captureVolume] | `ValueListenable<int>` | Capture volume, with a value range from 0 to 100 |
 * | [currentMicVolume] | `ValueListenable<int>` | Current user's actual output volume |
 * | [outputVolume] | `ValueListenable<int>` | Maximum output volume, with a value range from 0 to 100 |
 * | [cameraStatus] | `ValueListenable<DeviceStatus>` | Camera status |
 * | [cameraLastError] | `ValueListenable<DeviceError>` | Camera error |
 * | [isFrontCamera] | `ValueListenable<bool>` | Whether it's front camera |
 * | [localMirrorType] | `ValueListenable<MirrorType>` | Mirror state |
 * | [localVideoQuality] | `ValueListenable<VideoQuality>` | Local video quality |
 * | [currentAudioRoute] | `ValueListenable<AudioRoute>` | Current audio route location |
 * | [screenStatus] | `ValueListenable<DeviceStatus>` | Screen sharing status |
 * | [networkInfo] | `ValueListenable<NetworkInfo>` | Network information |
 *
 * > **Tip**: Device state is automatically updated. Subscribe to [state] to receive real-time updates.
 */
@Observed
export declare class DeviceState {
    /**
     * Microphone status.
     */
    microphoneStatus: DeviceStatus;
    /**
     * Microphone error, used to extract error information when an error occurs.
     */
    microphoneLastError: DeviceError;
    /**
     * Capture volume, with a value range from 0 to 100.
     */
    /** @deprecated Use microphoneVolume instead. Will be removed in version 5.5. */
    captureVolume: number;
    /**
     * Current user's actual output volume.
     */
    /** @deprecated Use microphoneInputLevel instead. Will be removed in version 5.5. */
    currentMicVolume: number;
    /**
     * Maximum output volume, with a value range from 0 to 100.
     */
    /** @deprecated Use speakerVolume instead. Will be removed in version 5.5. */
    outputVolume: number;
    /**
     * Camera status.
     */
    cameraStatus: DeviceStatus;
    /**
     * Camera error, used to extract error information when an error occurs.
     */
    cameraLastError: DeviceError;
    /**
     * Whether it's front camera.
     */
    isFrontCamera: boolean;
    /**
     * Mirror state.
     */
    localMirrorType: MirrorType;
    /**
     * Local video quality.
     */
    localVideoQuality: VideoQuality;
    /**
     * Current audio route location.
     */
    /** @deprecated Use currentSpeaker instead. Will be removed in version 5.5. */
    currentAudioRoute: AudioRoute;
    /**
     * Screen sharing status.
     */
    /** @deprecated Use ScreenShareStore.state.screenStatus instead. Will be removed in version 5.5. */
    screenStatus: DeviceStatus;
    /**
     * Network information.
     */
    networkInfo: NetworkInfo;
    /**
     * Current network type.
     */
    networkType: NetworkType;
    /**
     * Current microphone device list. Only populated on desktop platforms, it is empty on mobile platforms.
     */
    microphoneList: DeviceInfo[];
    /**
     * Current microphone device, an empty deviceId means no microphone is selected.
     */
    currentMicrophone: DeviceInfo;
    /**
     * Microphone capture volume, with a value range from 0 to 100.
     */
    microphoneVolume: number;
    /**
     * Real-time level value used to display the microphone volume bar, range 0-100.
     * Only updated while the microphone test is running, see startMicrophoneTest.
     */
    microphoneInputLevel: number;
    /**
     * Camera device list. On desktop platforms it contains all the cameras, on mobile platforms it
     * contains the logical front camera and rear camera.
     */
    cameraList: DeviceInfo[];
    /**
     * Current camera device, an empty deviceId means no camera is selected.
     */
    currentCamera: DeviceInfo;
    /**
     * Speaker device list. On desktop platforms it contains all the speakers, on mobile platforms it
     * contains the logical speaker and earpiece.
     */
    speakerList: DeviceInfo[];
    /**
     * Current speaker device, an empty deviceId means no speaker is selected.
     */
    currentSpeaker: DeviceInfo;
    /**
     * Speaker playback volume, with a value range from 0 to 100.
     */
    speakerVolume: number;
    /**
     * Speaker real-time output level value, range 0-100.
     * Only updated while the speaker test is running, see startSpeakerTest.
     */
    speakerOutputLevel: number;
}
/**
 * Device related interfaces, operating microphone, camera, etc.
 *
 * `DeviceStore` Device management class for handling host camera, microphone and other business.
 * `DeviceStore` provides a comprehensive set of APIs to manage audio and video devices, including microphone, camera and screen sharing features.
 *
 * ### Key Features
 *
 * - **Microphone Management**: Open/close microphone, set capture volume and output volume.
 * - **Camera Management**: Open/close camera, switch front/rear camera, set mirror and video quality.
 * - **Audio Route**: Switch between speaker and earpiece.
 * - **Network Status**: Real-time monitoring of network quality information.
 *
 * > **Important**: Use [DeviceStore.shared] singleton to get the `DeviceStore` instance. Do not attempt to initialize directly.
 *
 * > **Tip**: Device state updates are delivered through the [state] publisher. Subscribe to it to receive real-time updates about microphone, camera, network and other states.
 *
 * ### Getting Instance
 * - [DeviceStore.shared] - Singleton object.
 *
 * ### Observing State
 * - [state] - Reactive state containing microphone, camera, network and other device states.
 *
 * ### Microphone Operations
 * - [openLocalMicrophone] - Open local microphone.
 * - [closeLocalMicrophone] - Close local microphone.
 * - [setCaptureVolume] - Set capture volume.
 * - [setOutputVolume] - Set output volume.
 * - [setMicrophoneVolume] - Set microphone capture volume.
 * - [setSpeakerVolume] - Set speaker playback volume.
 * - [setCurrentMicrophone] - Select microphone device.
 * - [startMicrophoneTest] - Start microphone test.
 * - [stopMicrophoneTest] - Stop microphone test.
 *
 * ### Speaker Operations
 * - [setCurrentSpeaker] - Select speaker device.
 * - [startSpeakerTest] - Start speaker test.
 * - [stopSpeakerTest] - Stop speaker test.
 *
 * ### Audio Route
 * - [setAudioRoute] - Set audio route.
 *
 * ### Camera Operations
 * - [openLocalCamera] - Open local camera.
 * - [closeLocalCamera] - Close local camera.
 * - [switchCamera] - Switch camera.
 * - [setCurrentCamera] - Select camera device.
 * - [switchMirror] - Switch mirror state.
 * - [updateVideoQuality] - Update video quality.
 *
 * ### Deprecated
 * - [setCaptureVolume] - Set capture volume, use setMicrophoneVolume instead.
 * - [setOutputVolume] - Set output volume, use setSpeakerVolume instead.
 * - [setAudioRoute] - Set audio route, use setCurrentSpeaker instead.
 * - [switchCamera] - Switch camera, use setCurrentCamera instead.
 *
 * ### Reset
 * - [reset] - Reset to default state.
 *
 * @see [DeviceType]
 * @see [DeviceError]
 * @see [DeviceStatus]
 * @see [AudioRoute]
 * @see [VideoQuality]
 * @see [VideoOrientation]
 * @see [NetworkQuality]
 * @see [MirrorType]
 * @see [DeviceInfo]
 * @see [DeviceState]
 * @see [NetworkInfo]
 * @see [ScreenShareStore]
 */
@Observed
export declare class DeviceStore {
    private static instance;
    private impl;
    private constructor();
    get state(): Readonly<DeviceState>;
    static shared(): DeviceStore;
    /**
     * Open local microphone
     *
     * @param completion Whether operation succeeded.
     */
    openLocalMicrophone(): Promise<void>;
    /**
     * Close local microphone
     */
    closeLocalMicrophone(): void;
    /**
     * Set capture volume
     *
     * @param volume Capture volume, with a value range from 0 to 100.
     */
    /** @deprecated Use setMicrophoneVolume instead. Will be removed in version 5.5. */
    setCaptureVolume(volume: number): void;
    /**
     * Set microphone capture volume
     *
     * @param volume Capture volume, with a value range from 0 to 100.
     */
    setMicrophoneVolume(volume: number): void;
    /**
     * Set maximum output volume
     *
     * @param volume Maximum volume, with a value range from 0 to 100.
     */
    /** @deprecated Use setSpeakerVolume instead. Will be removed in version 5.5. */
    setOutputVolume(volume: number): void;
    /**
     * Set speaker playback volume
     *
     * @param volume Playback volume, with a value range from 0 to 100.
     */
    setSpeakerVolume(volume: number): void;
    /**
     * Set audio route
     *
     * @param route Route location.
     */
    /** @deprecated Use setCurrentSpeaker instead. Will be removed in version 5.5. */
    setAudioRoute(route: AudioRoute): void;
    /**
     * Set current speaker device
     *
     * Supported on all platforms: on desktop platforms any device in speakerList can be selected,
     * on mobile platforms only the logical speaker/earpiece switch takes effect.
     *
     * @param speaker Speaker device, an element of speakerList.
     */
    setCurrentSpeaker(speaker: DeviceInfo): void;
    /**
     * Open local camera
     *
     * @param isFront Whether front camera.
     * @param completion Whether operation succeeded.
     */
    openLocalCamera(isFront: boolean): Promise<void>;
    /**
     * Close local camera
     */
    closeLocalCamera(): void;
    /**
     * Switch camera
     *
     * @param isFront Whether front camera.
     */
    /** @deprecated Use setCurrentCamera instead. Will be removed in version 5.5. */
    switchCamera(isFront: boolean): void;
    /**
     * Switch mirror state
     *
     * @param mirrorType Mirror state.
     */
    switchMirror(mirrorType: MirrorType): void;
    /**
     * Update video quality
     *
     * @param quality Video quality.
     * @param orientation Video orientation. Defaults to portrait. Pass landscape to use the base (width x height) resolution.
     */
    updateVideoQuality(quality: VideoQuality, orientation?: VideoOrientation): void;
    /**
     * Start screen sharing
     */
    /** @deprecated Use ScreenShareStore.startScreenShare instead. Will be removed in version 5.5. */
    startScreenShare(): void;
    /**
     * Stop screen capture
     */
    /** @deprecated Use ScreenShareStore.stopScreenShare instead. Will be removed in version 5.5. */
    stopScreenShare(): void;
    /**
     * Reset to default state
     */
    reset(): void;
    /**
     * Set current microphone device
     *
     * Only supported on desktop platforms, mobile platforms do not allow switching the microphone
     * device and calling it has no effect there. It takes effect only when the microphone is on.
     *
     * @param microphone Microphone device, an element of microphoneList.
     */
    setCurrentMicrophone(microphone: DeviceInfo): void;
    /**
     * Start microphone test, the capture level is reported to microphoneInputLevel in real time, with a capture interval in milliseconds
     *
     * @param interval Capture interval in milliseconds. Default is 200ms.
     */
    startMicrophoneTest(interval: number): void;
    /**
     * Stop microphone test
     */
    stopMicrophoneTest(): void;
    /**
     * Start speaker test, the playback level is reported to speakerOutputLevel in real time
     *
     * An audio file is played during the test, the speaker device in use can be verified.
     *
     * @param filePath Audio file path used for the test playback. Required; an empty value returns an invalid-parameter error.
     */
    startSpeakerTest(filePath: string): void;
    /**
     * Stop speaker test
     */
    stopSpeakerTest(): void;
    /**
     * Set current camera device
     *
     * Supported on all platforms: on desktop platforms any device in cameraList can be selected,
     * on mobile platforms it is equivalent to switching between the front and rear cameras.
     * It takes effect only when the camera is on.
     *
     * @param camera Camera device, an element of cameraList.
     */
    setCurrentCamera(camera: DeviceInfo): void;
}
