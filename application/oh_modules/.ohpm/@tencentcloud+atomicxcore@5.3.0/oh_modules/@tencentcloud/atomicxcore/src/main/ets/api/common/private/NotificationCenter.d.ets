export interface Observer {
    onNotification(name: string, data: Object): void;
}
declare class WeakObserverWrapper implements Observer {
    private targetRef;
    private callback;
    private notificationName;
    constructor(target: Object, callback: (data: Object) => void, notificationName: string);
    onNotification(name: string, data: Object): void;
}
export declare class NotificationCenter {
    private static instance;
    private observers;
    static getInstance(): NotificationCenter;
    addObserver(name: string, observer: Object, callback: (data: Object) => void): void;
    removeObserverWrapper(name: string, wrapper: WeakObserverWrapper): void;
    post(name: string, data: Object): void;
}
declare const _default: NotificationCenter;
export default _default;
