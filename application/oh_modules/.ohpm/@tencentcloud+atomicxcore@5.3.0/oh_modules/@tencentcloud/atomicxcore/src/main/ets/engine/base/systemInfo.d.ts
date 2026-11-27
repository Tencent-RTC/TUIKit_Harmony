export default class SystemInfo {
    static getSystemOSName(): string;
    static getSystemOSVersion(): string;
    static getDeviceModel(): string;
    static getDeviceLanguage(): string;
    static bindNative(): void;
}
