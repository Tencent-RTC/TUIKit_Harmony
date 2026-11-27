export const napiOnLoad: (uiContext: object, cls: object) => number;
export declare class TXLiteAVBase {
    static setGlobalEnv(envConfig: string): number;
    static updateNetworkTime(): number;
    static getNetworkTimestamp(): number;
    static setCallback(callback: TXLiteAVBaseCallback): void;
    static setRootDirectory(path: string): void;
}
export declare class TXDeviceManager {
    constructor(instance: number);
    destroy(): undefined;
    isFrontCamera(): boolean;
    switchCamera(frontCamera: boolean): number;
    getCameraZoomMaxRatio(): number;
    setCameraZoomRatio(zoomRatio: number): number;
    enableCameraTorch(enabled: boolean): number;
    setAudioRoute(route: number): number;
}
export declare class TXBeautyManager {
    constructor(instance: number);
    destroy(): undefined;
    setBeautyStyle(beautyStyle: number): void;
    setBeautyLevel(beautyLevel: number): void;
    setWhitenessLevel(whitenessLevel: number): void;
    setRuddyLevel(ruddyLevel: number): void;
    setFilter(rcData: ArrayBuffer | null, pixelFormat: number, nWidth: number, nHeight: number): void;
    setFilterStrength(strength: number): void;
}
export declare class TXAudioEffectManager {
    constructor(instance: number);
    destroy(): undefined;
    enableVoiceEarMonitor(enable: boolean): void;
    setVoiceEarMonitorVolume(volume: number): void;
    setVoiceReverbType(type: number): void;
    setVoiceChangerType(type: number): void;
    setVoiceCaptureVolume(volume: number): void;
    setVoicePitch(pitch: number): void;
    setMusicObserver(musicId: number, observer: (event: string, params: object) => void): undefined;
    startPlayMusic(musicParam: object): void;
    stopPlayMusic(id: number): void;
    pausePlayMusic(id: number): void;
    resumePlayMusic(id: number): void;
    setAllMusicVolume(id: number): void;
    setMusicPublishVolume(id: number, volume: number): void;
    setMusicPlayoutVolume(id: number, volume: number): void;
    setMusicPitch(id: number, pitch: number): void;
    setMusicSpeedRate(id: number, speedRate: number): void;
    getMusicCurrentPosInMS(id: number): number;
    getMusicDurationInMS(path: string): number;
    seekMusicToPosInTime(id: number, pts: number): void;
    setMusicScratchSpeedRate(id: number, scratchSpeedRate: number): void;
    setPreloadObserver(observer: (event: string, params: object) => void): undefined;
    preloadMusic(preloadParam: object): void;
    getMusicTrackCount(id: number): number;
    setMusicTrack(id: number, trackIndex: number): void;
}
export declare class TRTCCloud {
    constructor(instance: number);
    destroy(): undefined;
    getTRTCCloud(): number;
    setTRTCCloudCallback(callback: (args: Array<string | {
        [key: string]: never;
    }>) => void): undefined;
    enterRoom(params: object, scene: number): undefined;
    exitRoom(): undefined;
    switchRole(role: number, privateMapKey: string | undefined): undefined;
    switchRoom(params: object): undefined;
    connectOtherRoom(params: string): undefined;
    disconnectOtherRoom(): undefined;
    setDefaultStreamRecvMode(autoRecvAudio: boolean, autoRecvVideo: boolean): undefined;
    updateOtherRoomForwardMode(param: string): undefined;
    startPublishMediaStream(target: object, params: object, config: object): undefined;
    updatePublishMediaStream(taskId: string, target: object, params: object, config: object): undefined;
    stopPublishMediaStream(taskId: string): undefined;
    startLocalPreview(frontCamera: boolean, view: string): undefined;
    updateLocalView(view: string): undefined;
    stopLocalPreview(): undefined;
    muteLocalVideo(streamType: number, mute: boolean): undefined;
    setVideoMuteImage(srcData: ArrayBuffer | null, pixelFormat: number, nWidth: number, nHeight: number, fps: number): undefined;
    startRemoteView(userId: string, streamType: number, view: string): undefined;
    updateRemoteView(userId: string, streamType: number, view: string): undefined;
    stopRemoteView(userId: string, streamType: number): undefined;
    stopAllRemoteView(): undefined;
    muteRemoteVideoStream(userId: string, streamType: number, mute: boolean): undefined;
    muteAllRemoteVideoStreams(mute: boolean): undefined;
    setVideoEncoderParam(params: object): undefined;
    setNetworkQosParam(params: object): undefined;
    setLocalRenderParams(params: object): undefined;
    setRemoteRenderParams(userId: string, streamType: number, params: object): undefined;
    setVideoEncoderRotation(rotation: number): undefined;
    setVideoEncoderMirror(mirror: boolean): undefined;
    enableSmallVideoStream(enable: boolean, params: object): undefined;
    setRemoteVideoStreamType(userId: string, streamType: number): undefined;
    snapshotVideo(userId: string, streamType: number, sourceType: number): undefined;
    setGravitySensorAdaptiveMode(mode: number): undefined;
    setAudioQuality(quality: number): undefined;
    startLocalAudio(quality: number): undefined;
    stopLocalAudio(): undefined;
    muteLocalAudio(mute: boolean): undefined;
    muteRemoteAudio(userId: string, mute: boolean): undefined;
    muteAllRemoteAudio(mute: boolean): undefined;
    setRemoteAudioVolume(userId: string, volume: number): undefined;
    setAudioCaptureVolume(volume: number): undefined;
    getAudioCaptureVolume(): number;
    setAudioPlayoutVolume(volume: number): undefined;
    getAudioPlayoutVolume(): number;
    enableAudioVolumeEvaluation(enable: boolean, params: object): undefined;
    startAudioRecording(params: object): number;
    stopAudioRecording(): undefined;
    startLocalRecording(enable: object): undefined;
    stopLocalRecording(): undefined;
    setRemoteAudioParallelParams(params: object): undefined;
    enable3DSpatialAudioEffect(enabled: boolean): undefined;
    updateSelf3DSpatialPosition(position: number[], axisForward: number[], axisRight: number[], axisUp: number[]): undefined;
    updateRemote3DSpatialPosition(userId: string, position: number[]): undefined;
    set3DSpatialReceivingRange(userId: string, range: number): undefined;
    setBeautyStyle(style: number, beauty: number, white: number, ruddiness: number): undefined;
    setWaterMark(streamType: number, srcData: ArrayBuffer | null, srcType: number, nWidth: number, nHeight: number, xOffset: number, yOffset: number, fWidthRatio: number, visibleOnLocalView: boolean): undefined;
    startSystemAudioLoopback(path?: string | null): undefined;
    stopSystemAudioLoopback(): undefined;
    setSystemAudioLoopbackVolume(volume: number): undefined;
    startScreenCapture(type: number, params: object | null): undefined;
    stopScreenCapture(): undefined;
    pauseScreenCapture(): undefined;
    resumeScreenCapture(): undefined;
    setSubStreamEncoderParam(params: object): undefined;
    setSubStreamMixVolume(volume: number): undefined;
    enableCustomAudioCapture(enable: boolean): undefined;
    sendCustomAudioData(frame: object): undefined;
    enableMixExternalAudioFrame(enablePublish: boolean, enablePlayout: boolean): undefined;
    mixExternalAudioFrame(frame: object): undefined;
    setMixExternalAudioVolume(publishVolume: number, playoutVolume: number): undefined;
    generateCustomPTS(): number;
    enableCustomVideoCapture(streamType: number, enable: boolean): undefined;
    sendCustomVideoData(streamType: number, frame: object): undefined;
    enableLocalVideoCustomProcess(enable: boolean, pixelFormat: number, bufferType: number): number;
    setLocalVideoCustomProcessCallback(callback: object): undefined;
    setLocalVideoRenderCallback(pixelFormat: number, bufferType: number, callback: object): number;
    setRemoteVideoRenderCallback(userId: string, pixelFormat: number, bufferType: number, callback: object): number;
    setAudioFrameCallback(callback: object): undefined;
    setCapturedAudioFrameCallbackFormat(format: object): number;
    setLocalProcessedAudioFrameCallbackFormat(format: object): number;
    setMixedPlayAudioFrameCallbackFormat(format: object): number;
    enableCustomAudioRendering(enable: boolean): void;
    getCustomAudioRenderingFrame(frame: object): void;
    sendCustomCmdMsg(cmdId: number, msg: ArrayBuffer, reliable: boolean, ordered: boolean): boolean;
    sendSEIMsg(msg: ArrayBuffer, repeatCount: number): boolean;
    startSpeedTest(params: object): number;
    stopSpeedTest(): undefined;
    getSDKVersion(): string;
    setLogLevel(level: number): undefined;
    setConsoleEnabled(enable: boolean): undefined;
    setLogCompressEnabled(enable: boolean): undefined;
    setLogDirPath(path: string): undefined;
    setLogCallback(callback: (log: string, level: number, module: string) => void): undefined;
    showDebugView(showType: number): void;
    callExperimentalAPI(jsonStr: string): string;
    getDeviceManager(): number;
    getAudioEffectManager(): number;
    getBeautyManager(): number;
}
export declare class V2TXLivePlayer {
    destroy(): undefined;
    setObserver(observer: (args: Array<string | {
        [key: string]: never;
    }>) => void): undefined;
    setRenderView(view: string): number;
    setRenderRotation(rotation: number): number;
    setRenderFillMode(mode: number): number;
    setRenderMirrorMode(enable: boolean): number;
    startPlay(url: string): number;
    stopPlay(): number;
    isPlaying(): number;
    pauseAudio(): number;
    resumeAudio(): number;
    pauseVideo(): number;
    resumeVideo(): number;
    setPlayoutVolume(volume: number): number;
    setCacheParams(minTime: number, maxTime: number): number;
    switchStream(newUrl: string): number;
    enableVolumeEvaluation(intervalMs: number): number;
    snapshot(): number;
    enableReceiveSeiMessage(enable: boolean, payloadType: number): number;
    showDebugView(isShow: boolean): undefined;
    setProperty(key: string, value: Object): number;
    startLocalRecording(params: object): number;
    stopLocalRecording(): undefined;
}
export declare class V2TXLivePremier {
    getSDKVersionStr(): string;
    setObserver(observer: (args: Array<string | {
        [key: string]: never;
    }>) => void): undefined;
    setLogConfig(config: object): undefined;
    setEnvironment(env: string): undefined;
    setLicence(url: string, key: string): undefined;
    setUserId(userId: string): undefined;
    callExperimentalAPI(jsonStr: string): number;
}
export declare class V2TXLivePusher {
    constructor(mode: number): V2TXLivePusher;
    destroy(): undefined;
    setObserver(observer: (args: Array<string | {
        [key: string]: never;
    }>) => void): undefined;
    setVideoObserver(observer: object): undefined;
    setRenderView(view: string): number;
    setRenderMirror(mirrorType: V2TXLiveMirrorType): number;
    setEncoderMirror(mirror: boolean): number;
    setRenderRotation(rotation: V2TXLiveRotation): number;
    setRenderFillMode(mode: V2TXLiveFillMode): number;
    startCamera(frontCamera: boolean): number;
    stopCamera(): number;
    startMicrophone(): number;
    stopMicrophone(): number;
    startVirtualCamera(srcType: number, srcData: ArrayBuffer | null, nWidth: number, nHeight: number): number;
    stopVirtualCamera(): number;
    startScreenCapture(): number;
    stopScreenCapture(): number;
    pauseAudio(): number;
    resumeAudio(): number;
    pauseVideo(): number;
    resumeVideo(): number;
    startPush(url: string): number;
    stopPush(): number;
    isPushing(): number;
    setAudioQuality(quality: V2TXLiveAudioQuality): number;
    setVideoQuality(param: V2TXLiveVideoEncoderParam): number;
    snapshot(): number;
    setWatermark(watermarkPath: string, x: number, y: number, scale: number): number;
    enableVolumeEvaluation(intervalMs: number): number;
    sendSeiMessage(payloadType: number, data: ArrayBuffer): number;
    enableCustomVideoProcess(enable: boolean, pixelFormat: number, bufferType: number): number;
    enableCustomVideoCapture(enable: boolean): number;
    enableCustomAudioCapture(enable: boolean): number;
    sendCustomVideoFrame(frame: object): number;
    sendCustomAudioFrame(frame: object): number;
    showDebugView(isShow: boolean): void;
    getDeviceManager(): number;
    getAudioEffectManager(): number;
    getBeautyManager(): number;
    setProperty(key: string, value: Object): number;
    getProperty(key: string): string;
    setMixTranscodingConfig(config: object): number;
    startLocalRecording(params: object): number;
    stopLocalRecording(): undefined;
}
export declare class PlayerAppletProxy {
    destroy(): undefined;
    init(properties: object): object;
    uninit(): object;
    setObserver(observer: (args: Array<string | {
        [key: string]: never;
    }>) => void): undefined;
    updateProperties(properties: PlayerAppletProperties): object;
    setRenderView(view: string): undefined;
    startPlay(): object;
    stopPlay(): object;
    isPlaying(): boolean;
    pause(): object;
    resume(): object;
    snapshot(): object;
}
export declare class PusherAppletProxy {
    destroy(): undefined;
    init(properties: object): object;
    updateProperties(properties: PlayerAppletProperties): object;
    uninit(): object;
    setObserver(observer: (args: Array<string | {
        [key: string]: never;
    }>) => void): undefined;
    setRenderView(view: string): object;
    startPush(): object;
    stopPush(): object;
    pausePush(): object;
    resumePush(): object;
    isPushing(): boolean;
    startPreview(): object;
    stopPreview(): object;
    toggleTorch(): object;
    snapshot(): object;
    playBGM(bgmPath: string, startTime: number, endTime: number): object;
    stopBGM(): object;
    pauseBGM(): object;
    resumeBGM(): object;
    setBGMVolume(volume: number): object;
    setMICVolume(volume: number): object;
    sendMessage(message: string): object;
    setFocusPosition(x: number, y: number): object;
    setZoom(ratio: number): object;
    getMaxZoom(): number;
}
export class GMEContext {
    getNativeInstance();
    getAuthBuffer(appId: number, roomId: string, userId: string, key: string): string;
    setTMGDelegate(delegate: (eventType: number, data: string) => void): void;
    setRegion(region: string): void;
    init(appId: string, userID: string): number;
    poll(): void;
    pause(): number;
    resume(): number;
    uninit(): number;
    setScene(scene: number): number;
    setAudioRole(role: number): number;
    setRangeAudioMode(mode: number): number;
    setRangeAudioTeamID(teamId: number): number;
    enterRoom(roomId: string, roomType: number, userSig: string): number;
    exitRoom(): number;
    isRoomEntered(): boolean;
    setLogLevel(logLevel: number, consoleLogLevel: number): number;
    setLogPath(logDir: string): number;
    getLogPath(): string;
    getSDKVersion(): string;
    setAppVersion(appVersion: string): void;
    showDebugView(show: boolean): number;
    setRecvMixStreamCount(count: number): number;
    setAdvanceParams(key: string, value: string): number;
    getAdvanceParams(key: string): string;
    checkMicPermission(): number;
}
export class GMEAudioCtrl {
    constructor(instance: number);
    enableMic(enable: boolean): number;
    getMicState(): number;
    enableSpeaker(enable: boolean): number;
    getSpeakerState(): number;
    enableAudioCaptureDevice(enable: boolean): number;
    isAudioCaptureDeviceEnabled(): boolean;
    enableAudioPlayDevice(enable: boolean): number;
    isAudioPlayDeviceEnabled(): boolean;
    enableAudioSend(enable: boolean): number;
    isAudioSendEnabled(): boolean;
    enableAudioRecv(enable: boolean): number;
    isAudioRecvEnabled(): boolean;
    setMicVolume(volume: number): number;
    getMicVolume(): number;
    setSpeakerVolume(volume: number): number;
    getSpeakerVolume(): number;
    setSpeakerVolumeByUserID(userID: string, volume: number): number;
    getSpeakerVolumeByUserID(userID: string): number;
    enableLoopBack(enable: boolean): number;
    addAudioBlackList(userID: string): number;
    removeAudioBlackList(userID: string): number;
    isUserIDInAudioBlackList(userID: string): boolean;
    initSpatializer(modelPath: string): number;
    enableSpatializer(enable: boolean): number;
    isEnableSpatializer(): boolean;
    enableCustomAudioCapture(enable: boolean): number;
    sendCustomAudioData(data: Uint8Array, sample_rate: number, channel: number, timestamp: number, bits_type: number): number;
    enableCustomAudioRendering(enable: boolean): number;
    getCustomAudioRenderingFrame(data: Uint8Array, sample_rate: number, channel: number, timestamp: number, bits_type: number): number;
    trackingVolume(interval: number): number;
    stopTrackingVolume(): number;
    getMicLevel(): number;
    getSpeakerLevel(): number;
    getSendStreamLevel(): number;
    getRecvStreamLevel(userID: string): number;
    startPlayMusic(soundId: number, filePath: string, loopCount: number): number;
    stopPlayMusic(soundId: number): number;
    pausePlayMusic(soundId: number): number;
    resumePlayMusic(soundId: number): number;
    isMusicPlayEnd(soundId: number): boolean;
    setAllMusicVolume(volume: number): number;
    setMusicPublishVolume(soundId: number, volume: number): number;
    getMusicPublishVolume(soundId: number): number;
    setMusicPlayoutVolume(soundId: number, volume: number): number;
    getMusicPlayoutVolume(soundId: number): number;
    setMusicPitch(soundId: number, pitch: number): number;
    getMusicDurationInMS(soundId: number): number;
    getMusicCurrentPosInMS(soundId: number): number;
    seekMusicToPosInTime(soundId: number, time: number): number;
    enableMusicPublish(soundId: number, enable: boolean): number;
    enableMusicPlayout(soundId: number, enable: boolean): number;
    setVoiceType(type: number): number;
    setKaraokeType(type: number): number;
    startRecord(filePath: string, content: number): number;
    stopRecord(): number;
    startSystemAudioLoopback(playerPath: string): number;
    stopSystemAudioLoopback(): number;
    setSystemAudioLoopbackVolume(volume: number): number;
}
export class GMEAudioEffectCtrl {
    constructor(instance: number);
    startPlayMusic(soundId: number, filePath: string, loopCount: number): number;
    stopPlayMusic(soundId: number): number;
    pausePlayMusic(soundId: number): number;
    resumePlayMusic(soundId: number): number;
    isMusicPlayEnd(soundId: number): boolean;
    setAllMusicVolume(volume: number): number;
    setMusicPublishVolume(soundId: number, volume: number): number;
    getMusicPublishVolume(soundId: number): number;
    setMusicPlayoutVolume(soundId: number, volume: number): number;
    getMusicPlayoutVolume(soundId: number): number;
    setMusicPitch(soundId: number, pitch: number): number;
    getMusicDurationInMS(soundId: number): number;
    getMusicCurrentPosInMS(soundId: number): number;
    seekMusicToPosInTime(soundId: number, time: number): number;
    enableMusicPublish(soundId: number, enable: boolean): number;
    enableMusicPlayout(soundId: number, enable: boolean): number;
    setVoiceType(type: number): number;
    setKaraokeType(type: number): number;
    startRecord(filePath: string, content: number): number;
    stopRecord(): number;
    startSystemAudioLoopback(playerPath: string): number;
    stopSystemAudioLoopback(): number;
    setSystemAudioLoopbackVolume(volume: number): number;
}
export class GMEPTT {
    constructor(instance: number);
    applyPTTAuthbuffer(userSig: string): number;
    setMaxMessageLength(msTime: number): number;
    startRecording(filePath: string): number;
    stopRecording(): number;
    cancelRecording(): number;
    uploadRecordedFile(filePath: string): number;
    downloadRecordedFile(fileId: string, filePath: string): number;
    playRecordedFile(filePath: string): number;
    playRecordedFile(filePath: string, voiceType: number): number;
    stopPlayFile(): number;
    speechToText(fileID: string, speechLanguage?: string, translateLanguage?: string): number;
    translateText(text: string, sourceLanguage: string, translateLanguage: string): number;
    getFileSize(filePath: string): number;
    getVoiceFileDuration(filePath: string): number;
    startRecordingWithStreamingRecognition(filePath: string, speechLanguage?: string, translateLanguage?: string): number;
    setPTTSourceLanguage(sourceLanguage: string): number;
    textToSpeech(serialNumber: number, text: string, voiceName: string, languageCode: string, speakingRate: number): number;
}
export class GMERoom {
    constructor(instance: number);
    getRoomID(): string;
    changeRoomType(roomType: number): number;
    getRoomType(): number;
    startRoomSharing(targetRoomID: string, targetUserID: string, userSig: string): number;
    stopRoomSharing(): number;
    switchRoom(targetRoomID: string, userSig: string): number;
    sendCustomData(data: ArrayBuffer, repeatCount: number): number;
    stopSendCustomData(): number;
    updateAudioRecvRange(range: number): number;
    updateSpatializerRecvRange(range: number): number;
    updateSelfPosition(position: number[], axisForward: number[], axisRight: number[], axisUp: number[]): number;
    updateOtherPosition(userID: string, position: number[]): number;
}
export class GMEAuthBuffer {
    static getAuthBuffer(appId: number, roomId: string, userId: string, key: string): string;
}
export class TXCopyrightedMediaNapi {
    constructor(instance: number);
    setLicense(context: Context, licenceUrl: string, key: string): void;
    genMusicURI(musicId: string, bgmType: number, bitrateDefinition: string): string;
    setMusicPreloadCallback(callback: object): void;
    preloadMusic(musicId: string, bitrateDefinition: string, playToken: string): void;
    preloadClimaxSegment(musicId: string, bitrateDefinition: string, playToken: string): void;
    preloadPitchAndLyricFile(musicId: string, bitrateDefinition: string, playToken: string): void;
    getClimaxSegmentTimeRange(musicId: string, bgmType: number, bitrateDefinition: string): TXClimaxTimeRange;
    cancelPreloadMusic(musicId: string, bitrateDefinition: string): void;
    isMusicPreload(musicId: string, bitrateDefinition: string): boolean;
    clearMusicCache(): void;
    clearMusicCacheByMusicId(musicId: string, bitrateDefinition: string): void;
    setMusicCacheMaxCount(maxCount: number): void;
    release(): void;
}
export class TXCopyrightedSongScoreNapi {
    constructor(instance: number, copyrightedMedia: TXCopyrightedMediaNative.TXCopyrightedMediaNapi, musicId: string, sampleRate: number, channel: number, playToken: string, noteFilePath: string, lyricFilePath: string);
    setSongScoreCallback(callback: object): void;
    prepare(): void;
    finish(): void;
    process(pcmData: ArrayBuffer, timeStamp: number): void;
    setKeyShift(shiftKey: number): void;
    calculateTotalScore(): number;
    getAllGrove(): Array<TXSongScoreNoteItem>;
    release(): void;
}
export class TXChorusMusicPlayerNapi {
    constructor(cloudInstancePointer: number, roomId: string);
    setChorusEventCallback(callback: object): void;
    setChorusRole(role: number, trtcParamsForPlayer: object | null): void;
    loadExternalMusic(params: object): void;
    start(): void;
    stop(): void;
    pause(): void;
    resume(): void;
    seek(timestampMs: number): void;
    switchMusicTrack(track: number): void;
    setPlayoutVolume(volume: number): void;
    setPublishVolume(volume: number): void;
    setMusicPitch(pitch: number): void;
    callExperimentalAPI(jsonStr: string): void;
    destroy(): void;
}
export class IoTEngineNapi {
    constructor();
    setClient(callback: object): void;
    login(appKey: string, userId: string, userSignature: object): void;
    logout(): void;
    getLoginUserInfo(): object | null;
    destroy(): void;
}
export class IoTFamilyManagerNapi {
    constructor();
    createFamily(name: string, callback: object): void;
    deleteFamily(familyId: string, callback: object): void;
    getFamilyList(callback: object): void;
    updateFamilyInfo(familyInfo: object, callback: object): void;
    createRoom(familyId: string, name: string, callback: object): void;
    deleteRoom(familyId: string, roomId: string, callback: object): void;
    setRoomName(familyId: string, roomId: string, name: string, callback: object): void;
    getRoomList(familyId: string, callback: object): void;
    createFamilyInviteToken(familyId: string, callback: object): void;
    joinFamilyAsMember(inviteToken: string, callback: object): void;
    removeMemberFromFamily(familyId: string, userId: string, callback: object): void;
    getMemberList(familyId: string, callback: object): void;
    destroy(): void;
}
export class IoTDeviceManagerNapi {
    constructor();
    bindDevice(familyId: string, deviceBindSignature: string, callback: object): void;
    unbindDevice(familyId: string, deviceId: object, callback: object): void;
    addDeviceToRoom(deviceId: object, familyId: string, roomId: string, callback: object): void;
    removeDeviceFromRoom(deviceId: object, familyId: string, callback: object): void;
    getDeviceList(familyId: string, nextPageToken: string, callback: object): void;
    createDeviceSharingToken(familyId: string, deviceId: object, callback: object): void;
    bindDeviceSharedWithMe(deviceId: object, shareToken: string, callback: object): void;
    unbindDeviceSharedWithMe(deviceId: object, callback: object): void;
    getDeviceSharedUsers(deviceId: object, callback: object): void;
    removeDeviceSharedUser(deviceId: object, userId: string, callback: object): void;
    getDeviceListSharedWithMe(nextPageToken: string, callback: object): void;
    sendCommand(deviceId: object, jsonData: string, callback: object): void;
    getProperties(deviceId: object, callback: object): void;
    modifyAliasName(deviceId: object, aliasName: string, callback: object): void;
    createTimer(deviceId: object, timerName: string, repeat: boolean, timerPlan: object, jsonData: string, callback: object): void;
    updateTimer(deviceId: object, timerInfo: object, callback: object): void;
    deleteTimer(deviceId: object, timerId: string, callback: object): void;
    enableTimer(deviceId: object, timerId: string, enable: boolean, callback: object): void;
    getTimerList(deviceId: object, nextPageToken: string, callback: object): void;
    destroy(): void;
}
export class IoTCloudStorageNapi {
    constructor(deviceId: object);
    getDayList(channelId: number, timeZone: string, callback: object): void;
    getEventList(channelId: number, timeZone: string, date: string, nextPageToken: string, callback: object): void;
    destroy(): void;
}
export class IoTCallSessionNapi {
    constructor();
    setListener(listener: object): void;
    callDevice(deviceId: object, callType: number): void;
    hangup(): void;
    startRemoteView(callUser: object, view: string): void;
    stopRemoteView(callUser: object): void;
    openMicrophone(): void;
    closeMicrophone(): void;
    openCamera(camera: number, view: string): void;
    closeCamera(): void;
    switchCamera(camera: number): void;
    selectAudioPlaybackDevice(device: number): void;
    destroy(): void;
}
export class IoTMonitorSessionNapi {
    constructor();
    setListener(listener: object): void;
    startSession(deviceId: object): void;
    stopSession(): void;
    startRemoteView(channelId: number, streamType: number, view: string): void;
    stopRemoteView(channelId: number): void;
    switchRemoteStream(channelId: number, streamType: number): void;
    muteRemoteAudio(channelId: number, mute: boolean): void;
    muteAllRemoteAudio(mute: boolean): void;
    startLocalAudio(): void;
    stopLocalAudio(): void;
    muteLocalAudio(mute: boolean): void;
    startLocalVideo(view: string, videoEncoderParams: object): void;
    stopLocalVideo(): void;
    sendPTZCommand(channelId: number, command: number, speed: number): void;
    takeSnapshot(channelId: number): void;
    startLocalRecording(channelId: number, params: object): void;
    stopLocalRecording(channelId: number): void;
    destroy(): void;
}
export declare class HouseBuilder {
    private constructor();
    static valid(functionType: number): number;
}
export declare class TXRealtimeASRNapi {
    constructor();
    setListener(listener: object): void;
    startRealtimeASR(params: object): void;
    stopRealtimeASR(): void;
    feedPcmData(pcmData: ArrayBuffer, sampleRate: number, channels: number): void;
    callExperimentalAPI(jsonStr: string): string;
}
export declare class TXRealtimeTTSNapi {
    constructor();
    setListener(listener: object): void;
    start(param: object): number;
    stop(): number;
    pause(): number;
    resume(): number;
    clear(): number;
    appendText(textId: string, text: string, isEnd: boolean): number;
    setVolume(volume: number): number;
    setSpeed(speed: number): number;
    callExperimentalAPI(jsonParams: string): string;
}
