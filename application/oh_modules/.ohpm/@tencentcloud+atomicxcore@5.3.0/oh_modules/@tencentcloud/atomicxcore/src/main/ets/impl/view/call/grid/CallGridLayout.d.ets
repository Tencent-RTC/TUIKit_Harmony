/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallGridLayout @ AtomicXCore
 * Function: Android CallGridLayout-compatible segment layout algorithm.
 */
export declare enum SegmentStyle {
    fullWidth = 0,
    oneThird = 1,
    fiftyFifty = 2,
    threeOneThirds = 3,
    oneThirdTwoThirds = 4,
    twoThirdsOneThirdCenter = 5,
    twoThirdsOneThirdRight = 6
}
export interface GridLayoutFrame {
    x: number;
    y: number;
    width: number;
    height: number;
}
export declare class CallGridLayout {
    static readonly defaultIndex: number;
    static calculateFrames(count: number, largeIndex: number, containerWidth: number, containerHeight: number): GridLayoutFrame[];
    static getMeasureSize(index: number, count: number, largeIndex: number, measureWidth: number): number;
    static getTopMargin(count: number, largeIndex: number, width: number, height: number): number;
    static getLocation(count: number, largeIndex: number, measureWidth: number): GridLayoutFrame[];
    static getSegment(count: number, currentIndex: number, largeIndex: number): SegmentStyle;
    private static getSegmentFrames;
    private static getSegmentHeightMultiplier;
    private static getSegmentStep;
    private static oneThirdTwoThirds;
    private static threeOneThird;
    private static fullWidth;
    private static twoThirdsOneThirdCenter;
    private static twoThirdsOneThirdRight;
    private static fiftyFifty;
    private static oneThird;
}
