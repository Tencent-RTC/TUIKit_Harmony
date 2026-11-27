/**
 * Room-scoped store lifecycle, mirroring StoreProvider / IStore on
 * iOS / Android / Dart.
 */
export interface IStore {
    beforeEnterRoom(roomID: string): void;
    afterEnterRoom(info: Object): void;
    didLeaveRoom(roomID: string): void;
}
