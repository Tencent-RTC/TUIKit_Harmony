import { Context } from '@ohos.abilityAccessCtrl';
export declare class LiteavAudioPermissionRequester {
    private static TAG;
    static nativeRequestMicPermission(context: Context, callback: (granted: boolean) => void): void;
}
