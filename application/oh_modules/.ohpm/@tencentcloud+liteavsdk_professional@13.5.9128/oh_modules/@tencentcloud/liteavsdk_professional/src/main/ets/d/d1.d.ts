export declare class LiteavLog {
    private static LOG_LEVEL_DEBUG;
    private static LOG_LEVEL_INFO;
    private static LOG_LEVEL_WARN;
    private static LOG_LEVEL_ERROR;
    private static LOG_LEVEL_FATAL;
    static debug(tag: string, f16: string, ...args: Object[]): void;
    static info(tag: string, d16: string, ...args: Object[]): void;
    static warn(tag: string, b16: string, ...args: Object[]): void;
    static error(tag: string, z15: string, ...args: Object[]): void;
    static fatal(tag: string, x15: string, ...args: Object[]): void;
    static nativeWriteLogToNative(level: number, tag: string, message: string): void;
}
