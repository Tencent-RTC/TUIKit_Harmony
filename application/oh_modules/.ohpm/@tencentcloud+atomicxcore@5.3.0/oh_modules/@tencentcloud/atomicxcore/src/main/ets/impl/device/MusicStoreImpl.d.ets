/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   MusicStoreImpl @ AtomicEngine
 * Function: HarmonyOS implementation of MusicStore. Lives in the device
 *           package (matching the other platforms) but is assembled per
 *           room, mirroring the iOS / Android / Dart baselines.
 */
import { MusicStore, AudioMusicParam, MusicListener } from '../../api/device/MusicStore';
import { IStore } from '../common/IStore';
@Observed
export declare class MusicStoreImpl extends MusicStore implements IStore {
    private readonly roomID;
    private eventToken;
    private stateToken;
    private listeners;
    constructor(roomID: string);
    startPlay(param: AudioMusicParam): Promise<void>;
    pausePlay(): void;
    resumePlay(): void;
    stopPlay(): void;
    seek(ms: number): void;
    setMusicVolume(volume: number): void;
    setPitch(pitch: number): void;
    addMusicListener(listener: MusicListener): void;
    removeMusicListener(listener: MusicListener): void;
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(_info: Object): void;
    didLeaveRoom(roomID: string): void;
    private onModuleEvent;
    private onModuleStateChanged;
    private static parseObject;
    private static numberOf;
    private static stringOf;
}
