export declare enum AtomicMetrics {
    MESSAGE_LIST = 1001,
    MESSAGE_INPUT = 1002,
    MESSAGE_ACTION = 1003,
    CONVERSATION_LIST = 1004,
    CONVERSATION_GROUP = 1005,
    SEARCH = 1006,
    CONTACT = 1007,
    GROUP = 1008,
    GROUP_MEMBER = 1009,
    LIVE_LIST = 1101,
    LIVE_SEAT = 1103,
    LIVE_AUDIENCE = 1104,
    LIVE_CO_GUEST = 1105,
    LIVE_CO_HOST = 1106,
    LIVE_BATTLE = 1108,
    LIVE_BARRAGE = 1110,
    LIVE_LIKE = 1111,
    LIVE_GIFT = 1112,
    DEVICE = 1113,
    AUDIO_EFFECT = 1114,
    BASE_BEAUTY = 1115,
    ALBUM_PICKER = 1121,
    MUSIC_STORE = 1122,
    CALL = 1301,
    AI_TRANSCRIBER = 1401
}
export declare enum InteractionMetrics {
    CHAT_INVOKE_CALL = 1020,
    CHAT_INVOKE_ROOM = 1021
}
export declare class DataReport {
    private static readonly TAG;
    private static framework;
    static setFramework(framework: number): void;
    static reportAtomicMetrics(componentType: AtomicMetrics): void;
    static reportInteractionMetrics(componentType: InteractionMetrics): void;
    static reportUIPlatform(platform: number): void;
    static reportComponent(component: number): void;
    private static reportMetricsImpl;
}
