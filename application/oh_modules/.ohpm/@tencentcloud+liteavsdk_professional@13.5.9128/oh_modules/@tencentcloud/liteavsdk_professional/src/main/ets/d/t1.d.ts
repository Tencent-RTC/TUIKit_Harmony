import { Callback } from '@ohos.base';
import common from '@ohos.app.ability.common';
export declare class AppStateMonitor {
    private static APP_STATE_UNSET;
    private static APP_STATE_FORGROUND;
    private static APP_STATE_BACKGROUND;
    private static tag;
    private static instance;
    private isRunning;
    private appContext;
    private callback;
    private backgroundState;
    private onAppBackgroundStateChanged;
    private constructor();
    static getInstance(): AppStateMonitor;
    on(type: 'onAppBackgroundStateChanged', callback: Callback<number>): void;
    private setAppBackgroundState;
    initialize(context: common.ApplicationContext): void;
    start(): void;
    stop(): void;
    getAppBackgroundState(): number;
}
