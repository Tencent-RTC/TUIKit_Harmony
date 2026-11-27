/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   StoreFactory @ AtomicXCore
 * Function: Scene-aware store assembly and lifecycle driver, mirroring StoreFactory on iOS / Android / Dart.
 */
import { StoreType } from './StoreRegistry';
import '../live/AtomicPlayerImpl';
import '../live/AtomicPusherImpl';
/**
 * Scene type of a room session, mirroring `SceneType` on iOS / Android / Dart.
 */
export declare enum SceneType {
    /** Live streaming scene (play / push). */
    LIVE = 0,
    /** Room scene (group-call style room). */
    ROOM = 1,
    /** Call scene (1v1 call). */
    CALL = 2
}
/**
 * Store factory: assembles scene stores around the enter/leave room
 * lifecycle and caches room-scoped store instances, mirroring StoreFactory
 * on iOS / Android / Dart.
 */
export declare class StoreFactory {
    static readonly shared: StoreFactory;
    private storeMap;
    private constructor();
    private registerStoreCreators;
    private registerControllerFactory;
    getStore(storeType: StoreType, roomID?: string): Object;
    beforeEnterRoom(roomID: string, sceneType: SceneType): void;
    afterEnterRoom(roomID: string, info: Object): void;
    didLeaveRoom(roomID: string): void;
    removeAllStores(): void;
}
