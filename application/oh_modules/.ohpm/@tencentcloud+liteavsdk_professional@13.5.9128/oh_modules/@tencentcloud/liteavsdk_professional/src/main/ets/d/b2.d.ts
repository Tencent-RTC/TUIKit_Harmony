import { Callback } from '@ohos.base';
export declare class NetworkStateMonitor {
    private static NETWORK_TYPE_UNSET;
    private static NETWORK_TYPE_UNKNOWN;
    private static NETWORK_TYPE_WIFI;
    private static NETWORK_TYPE_4G;
    private static NETWORK_TYPE_3G;
    private static NETWORK_TYPE_2G;
    private static NETWORK_TYPE_WIRED;
    private static NETWORK_TYPE_5G;
    private static instance;
    private netConnection;
    private networkType;
    private onNetworkTypeChanged;
    private constructor();
    static getInstance(): NetworkStateMonitor;
    on(type: 'onNetworkTypeChanged', callback: Callback<number>): void;
    start(): void;
    stop(): void;
    private setNetworkType;
    private getNetworkTypeFromNetCapabilities;
    private getCellularType;
}
