import { Context } from '@ohos.abilityAccessCtrl';
import { p19 } from "./f2";
import { PlayerAppletProxy } from "./e2";
import { u17, v17 } from "./d2";
export declare class t19 implements PlayerAppletProxy {
    private observer;
    private y19;
    static n19(context?: Context): PlayerAppletProxy;
    static o19(x19?: PlayerAppletProxy): void;
    private z19;
    private constructor();
    destroy(): void;
    init(properties: v17): u17;
    uninit(): u17;
    setObserver(observer: p19): void;
    updateProperties(properties: v17): u17;
    setRenderView(w19: string): void;
    startPlay(): u17;
    stopPlay(): u17;
    isPlaying(): boolean;
    pause(): u17;
    resume(): u17;
    snapshot(v19: boolean): u17;
    private emit;
    private initObserver;
}
