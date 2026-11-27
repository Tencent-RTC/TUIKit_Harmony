export interface ITPDataTransportLogListener {
    debug(tag: string, msg: string): void;
    info(tag: string, msg: string): void;
    warn(tag: string, msg: string): void;
    error(tag: string, msg: string): void;
}
