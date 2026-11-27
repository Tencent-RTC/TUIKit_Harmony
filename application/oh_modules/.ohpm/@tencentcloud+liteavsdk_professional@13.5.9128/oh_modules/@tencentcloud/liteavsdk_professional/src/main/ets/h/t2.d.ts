import { Context } from '@ohos.abilityAccessCtrl';
import { V2TXLivePremier, V2TXLivePremierObserver } from "./k2";
import { V2TXLiveLogConfig } from "./o2";
export declare class V2TXLivePremierImpl implements V2TXLivePremier {
    private static sharedInstance;
    private v2txlivepremier;
    private observer;
    static getV2TXLivePremierShareInstance(context?: Context): V2TXLivePremier;
    private constructor();
    getSDKVersionStr(): string;
    setObserver(observer: V2TXLivePremierObserver): void;
    setLogConfig(config: V2TXLiveLogConfig): void;
    setEnvironment(l21: string): void;
    setLicence(url: string, key: string): void;
    setUserId(userId: string): void;
    callExperimentalAPI(k21: string): number;
    private emit;
    private initObserver;
}
