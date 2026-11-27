export interface TXLiteAVBaseCallback {
    onUpdateNetworkTime?: (errCode: number, errMsg: string) => void;
}
export declare class TXLiteAVBase {
    static setGlobalEnv(n1: string): number;
    static updateNetworkTime(): number;
    static getNetworkTimestamp(): number;
    static setCallback(callback: TXLiteAVBaseCallback): void;
    static setRootDirectory(path: string): void;
}
