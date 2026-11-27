/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallViewConstants @ AtomicXCore
 * Function: View-layer constants, colors, and utility functions for Call UI components.
 */
export declare class CallColors {
    static readonly background: string;
    static readonly white: string;
    static readonly videoPlaceholder: string;
    static readonly overlay: string;
    static readonly bottomBarBackground: string;
    static readonly shadowColor: string;
    static readonly durationText: string;
    static readonly countText: string;
    static readonly blurMask: string;
}
export declare enum CallLayoutTemplate {
    float = 0,
    grid = 1,
    pip = 2
}
export declare enum VolumeLevel {
    mute = 0,
    low = 1,
    medium = 2,
    high = 3,
    peak = 4
}
export declare const VOLUME_LEVEL_MIN = 10;
export declare function volumeToLevel(volume: number): VolumeLevel;
export declare function formatDuration(seconds: number): string;
