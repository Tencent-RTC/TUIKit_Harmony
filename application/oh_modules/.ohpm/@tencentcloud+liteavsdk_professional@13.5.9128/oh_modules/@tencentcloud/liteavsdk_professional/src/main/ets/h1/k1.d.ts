import { l11, q10, y11, n11, z11 } from "./m1";
export declare class a12 {
    timerId: string;
    timerName: string;
    timerPlan: b12;
    deviceId: q10;
    data: string;
    isEnabled: boolean;
    d12: boolean;
    createTime: number;
    updateTime: number;
}
export declare class b12 {
    repeatDays: boolean[];
    e12: number;
    f12: number;
}
export interface c12 {
    bindDevice(familyId: string, deviceBindSignature: string, callback: l11<y11>): void;
    unbindDevice(familyId: string, deviceId: q10, callback: l11<void>): void;
    addDeviceToRoom(deviceId: q10, familyId: string, roomId: string, callback: l11<void>): void;
    removeDeviceFromRoom(deviceId: q10, familyId: string, callback: l11<void>): void;
    getDeviceList(familyId: string, nextPageToken: string, callback: l11<n11<y11>>): void;
    createDeviceSharingToken(familyId: string, deviceId: q10, callback: l11<string>): void;
    bindDeviceSharedWithMe(deviceId: q10, shareToken: string, callback: l11<void>): void;
    unbindDeviceSharedWithMe(deviceId: q10, callback: l11<void>): void;
    getDeviceSharedUsers(deviceId: q10, callback: l11<z11[]>): void;
    removeDeviceSharedUser(deviceId: q10, userId: string, callback: l11<void>): void;
    getDeviceListSharedWithMe(nextPageToken: string, callback: l11<n11<y11>>): void;
    sendCommand(deviceId: q10, jsonData: string, callback: l11<string>): void;
    getProperties(deviceId: q10, callback: l11<string>): void;
    modifyAliasName(deviceId: q10, aliasName: string, callback: l11<void>): void;
}
