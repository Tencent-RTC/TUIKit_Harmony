export declare enum AtomicMetrics {
    MESSAGE_LIST = 1001,
    MESSAGE_INPUT = 1002,
    MESSAGE_ACTION = 1003,
    CONVERSATION_LIST = 1004,
    CONVERSATION_GROUP = 1005,
    SEARCH = 1006,
    CONTACT_LIST = 1007,
    GROUP_SETTING = 1008,
    C2C_SETTING = 1009
}
export declare class DataReport {
    private static readonly TAG;
    static reportAtomicMetrics(componentType: AtomicMetrics): void;
}
