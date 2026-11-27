export declare class Log {
    private static readonly API;
    private static readonly LOG_KEY_LEVEL;
    private static readonly LOG_KEY_MESSAGE;
    private static readonly LOG_KEY_FILE;
    private static readonly LOG_KEY_LINE;
    private static readonly LOG_KEY_TAG;
    private static readonly MODULE_ATOMIC_XCORE_COMMON;
    private static readonly MODULE_ATOMIC_XCORE_CALL;
    private static readonly MODULE_ATOMIC_XCORE_LIVE;
    private static readonly MODULE_ATOMIC_XCORE_ROOM;
    private static readonly LOG_LEVEL_INFO;
    private static readonly LOG_LEVEL_WARNING;
    private static readonly LOG_LEVEL_ERROR;
    private moduleName;
    private fileName;
    private constructor();
    static getCommonLog(file: string): Log;
    static getCallLog(file: string): Log;
    static getLiveLog(file: string): Log;
    static getRoomLog(file: string): Log;
    static info(module: string, file: string, message: string): void;
    static warn(module: string, file: string, message: string): void;
    static error(module: string, file: string, message: string): void;
    private static log;
    info(message: string): void;
    warn(message: string): void;
    error(message: string): void;
}
