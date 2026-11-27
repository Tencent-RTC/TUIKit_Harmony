import { ITPDataTransportInnerLogger } from './ITPDataTransportInnerLogger';
export declare class TPDataTransportInnerLogger implements ITPDataTransportInnerLogger {
    private domain;
    private prefix;
    private format;
    private tag;
    constructor(fileName: string, tag?: string);
    debug(msg: string): void;
    info(msg: string): void;
    error(msg: string): void;
    warn(msg: string): void;
}
