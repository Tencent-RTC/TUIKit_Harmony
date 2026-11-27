import { c12, a12, b12 } from "../h1/k1";
import { l11, q10, y11, n11, z11 } from "../h1/m1";
export declare class u22 implements c12 {
    private nativeDeviceManager;
    constructor();
    destroy(): void;
    bindDevice(m23: string, n23: string, callback: l11<y11>): void;
    unbindDevice(l23: string, deviceId: q10, callback: l11<void>): void;
    addDeviceToRoom(deviceId: q10, j23: string, k23: string, callback: l11<void>): void;
    removeDeviceFromRoom(deviceId: q10, i23: string, callback: l11<void>): void;
    getDeviceList(g23: string, h23: string, callback: l11<n11<y11>>): void;
    createDeviceSharingToken(f23: string, deviceId: q10, callback: l11<string>): void;
    bindDeviceSharedWithMe(deviceId: q10, e23: string, callback: l11<void>): void;
    unbindDeviceSharedWithMe(deviceId: q10, callback: l11<void>): void;
    getDeviceSharedUsers(deviceId: q10, callback: l11<z11[]>): void;
    removeDeviceSharedUser(deviceId: q10, userId: string, callback: l11<void>): void;
    getDeviceListSharedWithMe(d23: string, callback: l11<n11<y11>>): void;
    sendCommand(deviceId: q10, c23: string, callback: l11<string>): void;
    getProperties(deviceId: q10, callback: l11<string>): void;
    modifyAliasName(deviceId: q10, aliasName: string, callback: l11<void>): void;
    createTimer(deviceId: q10, z22: string, repeat: boolean, a23: b12, b23: string, callback: l11<a12>): void;
    updateTimer(deviceId: q10, y22: a12, callback: l11<void>): void;
    deleteTimer(deviceId: q10, x22: string, callback: l11<void>): void;
    enableTimer(deviceId: q10, w22: string, enable: boolean, callback: l11<void>): void;
    getTimerList(deviceId: q10, v22: string, callback: l11<n11<a12>>): void;
}
