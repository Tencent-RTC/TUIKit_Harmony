export type TimerTask = (timerId: number) => void;
export type DelayTask = () => void;
export default class JSTimer {
    private static timerMap;
    static startInterval(timerId: number, interval: number, callback: TimerTask): void;
    static stopInterval(timerId: number): void;
    static startTimeout(timeout: number, callback: DelayTask): void;
    static bindNative(): void;
}
