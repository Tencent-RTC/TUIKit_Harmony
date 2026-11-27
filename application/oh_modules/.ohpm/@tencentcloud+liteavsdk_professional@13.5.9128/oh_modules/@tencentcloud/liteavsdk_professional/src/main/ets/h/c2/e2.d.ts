import { Context } from '@ohos.abilityAccessCtrl';
import { u17, v17 } from "./d2";
import { p19 } from "./f2";
export declare function n19(context: Context): PlayerAppletProxy;
export declare function o19(u19: PlayerAppletProxy): void;
export interface PlayerAppletProxy {
    init(properties: v17): u17;
    uninit(): u17;
    setObserver(observer: p19): void;
    updateProperties(properties: v17): u17;
    setRenderView(view: string): void;
    startPlay(): u17;
    stopPlay(): u17;
    isPlaying(): boolean;
    pause(): u17;
    resume(): u17;
    snapshot(needCompress: boolean): u17;
}
