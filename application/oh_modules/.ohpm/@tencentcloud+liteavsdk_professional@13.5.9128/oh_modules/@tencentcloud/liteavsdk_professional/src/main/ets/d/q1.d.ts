import common from '@ohos.app.ability.common';
export declare class AppInfo {
    private static appName;
    private static appPackageName;
    private static appVersion;
    static initialize(a14: common.ApplicationContext): void;
    static getAppName(): string;
    static getAppPackageName(): string;
    static getAppVersion(): string;
}
