import { Context } from "@ohos.abilityAccessCtrl";
import { c12 } from "./k1";
import { b11 } from "./i1";
import { q11 } from "./j1";
import { q10, r10, z11 } from "./m1";
import { i12 } from "./n1";
import { j12 } from "./o1";
export declare enum k12 {
    STATUS_CHANGE = 0
}
export declare enum l12 {
    ONLINE = 0,
    OFFLINE = 1
}
export declare class n12 {
    r12: number;
    type: k12;
    subType: l12;
    deviceId: q10;
}
export declare class o12 {
    requestId: string;
    timestamp: number;
    nonce: number;
    signature: string;
}
export interface p12 {
    s12?: () => void;
    t12?: (errCode: r10, errMsg: string) => void;
    u12?: () => void;
    v12?: () => void;
    w12?: (pushMessage: n12) => void;
}
export interface q12 {
    addListener(listener: p12): void;
    removeListener(listener: p12): void;
    login(appKey: string, userId: string, userSignature: o12): void;
    logout(): void;
    getLoginUserInfo(): z11 | null;
    x12(): i12 | null;
    getDeviceManager(): c12 | null;
    y12(): b11 | null;
    z12(): j12 | null;
    a13(deviceId: q10): q11 | null;
}
export declare function g12(context?: Context): q12;
