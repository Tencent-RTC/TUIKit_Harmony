import common from '@ohos.app.ability.common';
export declare class LiteavSystemInfo {
    static nativeInitialize(s16: common.ApplicationContext): void;
    static nativeGetAppMemoryUsage(): number;
    static nativeListenAppBackgroundState(): void;
    static nativeGetMicPermission(): number;
    static nativeSetDeviceInfo(o16: string, manufacture: string, model: string, p16: string, q16: number): void;
    static nativeSetApplicationInfo(appName: string, packageName: string, appVersion: string): void;
    static nativeSetAppBackgroundState(n16: number): void;
    static nativeSetNetworkType(m16: number): void;
}
