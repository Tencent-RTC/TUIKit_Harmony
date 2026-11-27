import { l11, n11 } from "./m1";
export declare class o11 {
    r11: string;
    s11: string;
    t11: string;
    u11: string;
    startTimeMs: number;
    durationMs: number;
}
export declare class p11 {
    eventType: string;
    v11: string;
    w11: number;
    durationMs: number;
    x11: o11[];
}
export interface q11 {
    getDayList(channelId: number, timeZone: string, callback: l11<string[]>): void;
    getEventList(channelId: number, timeZone: string, date: string, nextPageToken: string, callback: l11<n11<p11>>): void;
}
