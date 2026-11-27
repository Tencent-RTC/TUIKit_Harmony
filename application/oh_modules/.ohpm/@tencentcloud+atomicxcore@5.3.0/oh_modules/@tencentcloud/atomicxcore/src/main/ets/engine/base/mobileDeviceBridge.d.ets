/** AudioKit-only observation; it does not create capturers, renderers, or permission dialogs. */
export default class MobileDeviceBridge {
    private static sessions;
    private token;
    private revision;
    private active;
    private manager;
    private routing;
    private streams;
    private application;
    private deviceListener;
    private inputListener;
    private outputListener;
    private foregroundListener;
    private constructor();
    /** Registers native entry points before the engine initializes. */
    static bindNative(): void;
    private static start;
    private static refreshSession;
    private observe;
    private static stop;
    private static removeObserver;
    private refresh;
    private readSnapshot;
    private static deviceInfo;
}
