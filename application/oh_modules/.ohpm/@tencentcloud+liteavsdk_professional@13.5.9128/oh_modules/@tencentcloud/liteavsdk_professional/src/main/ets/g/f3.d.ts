import { q11, p11 } from "../h1/j1";
import { l11, q10, n11 } from "../h1/m1";
export declare class s22 implements q11 {
    private nativeCloudStorage;
    constructor(deviceId: q10);
    getDayList(channelId: number, timeZone: string, callback: l11<string[]>): void;
    getEventList(channelId: number, timeZone: string, date: string, t22: string, callback: l11<n11<p11>>): void;
}
