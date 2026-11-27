/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicSeatLayout @ AtomicXCore
 */
import { DeviceStatus } from '../../../api/device/DeviceStore';
import { AtomicLiveViewChangeAdapter, SuspendStatus, UnitInfo } from '../../../api/view/live/AtomicLiveView';
export declare const FEATURED_HOST_TEMPLATE_ID: number;
export declare enum AtomicViewListMode {
    SEAT_SINGLE = 0,
    SEI_MIXED = 1
}
export declare class LiveCanvas {
    width: number;
    height: number;
    templateID: number;
}
export declare class RegionInfo {
    x: number;
    y: number;
    w: number;
    h: number;
    zorder: number;
}
export declare class SeatUserInfo {
    userID: string;
    userName: string;
    avatarURL: string;
    role: number;
    liveID: string;
    microphoneStatus: DeviceStatus;
    allowOpenMicrophone: boolean;
    cameraStatus: DeviceStatus;
    allowOpenCamera: boolean;
    userSuspendStatus: SuspendStatus;
}
@Observed
export declare class SeatInfo {
    index: number;
    isLocked: boolean;
    isFeaturedHost: boolean;
    userInfo: SeatUserInfo;
    region: RegionInfo;
}
@Observed
export declare class AdapterHolder {
    adapter: AtomicLiveViewChangeAdapter | undefined;
}
export declare class AtomicSeatLayout {
    mode: AtomicViewListMode;
    canvas: LiveCanvas;
    seatList: SeatInfo[];
}
export declare function seatKeyOf(seat: SeatInfo): string;
export declare function buildUnitInfo(seat: SeatInfo): UnitInfo;
export declare class AtomicSeatLayoutDecoder {
    static decodeLayout(json: Record<string, Object>): AtomicSeatLayout | undefined;
    static decodeSeat(json: Record<string, Object>): SeatInfo;
    private static decodeCanvas;
    private static decodeUser;
    private static decodeRegion;
    private static intOf;
    private static boolOf;
    private static stringOf;
    private static deviceStatusOf;
}
export declare class Transform {
    scale: number;
    compensateX: number;
    compensateY: number;
    constructor(scale: number, compensateX: number, compensateY: number);
}
export declare class Multiplied {
    width: number;
    height: number;
    constructor(width: number, height: number);
}
export declare function isFullCanvas(region: RegionInfo, canvas: LiveCanvas): boolean;
export declare class SeatRect {
    left: number;
    top: number;
    right: number;
    bottom: number;
    constructor(left: number, top: number, right: number, bottom: number);
}
export declare function calculateSeatedRects(containerWidth: number, containerHeight: number, seatList: SeatInfo[], canvas: LiveCanvas, isOnSeat: boolean): SeatRect[] | undefined;
export declare function seatedRectsToPathCommands(rects: SeatRect[], scale?: number): string;
export declare function subtractRects(base: SeatRect, holes: SeatRect[]): SeatRect[];
export declare function isAbove(region: RegionInfo, other: RegionInfo, canvas: LiveCanvas): boolean;
export declare function calculateSeatVisibleRects(index: number, seatList: SeatInfo[], frames: SeatRect[], canvas: LiveCanvas): SeatRect[] | undefined;
export declare function calculateCanvasMultiplied(containerWidth: number, containerHeight: number, seatList: SeatInfo[], canvas: LiveCanvas): Multiplied;
export declare function calculateVideoTransform(containerWidth: number, containerHeight: number, seatList: SeatInfo[], canvas: LiveCanvas, isOnSeat: boolean): Transform;
