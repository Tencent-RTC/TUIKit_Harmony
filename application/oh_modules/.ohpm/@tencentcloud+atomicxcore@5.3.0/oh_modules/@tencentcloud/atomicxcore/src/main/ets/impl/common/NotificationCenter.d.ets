type NotificationHandler = (data: Object) => void;
export default class NotificationCenter {
    private static observers;
    static addObserver(key: string, owner: Object, handler: NotificationHandler): void;
    static removeObserver(owner: Object): void;
    static post(key: string, data: Object): void;
}
export {};
