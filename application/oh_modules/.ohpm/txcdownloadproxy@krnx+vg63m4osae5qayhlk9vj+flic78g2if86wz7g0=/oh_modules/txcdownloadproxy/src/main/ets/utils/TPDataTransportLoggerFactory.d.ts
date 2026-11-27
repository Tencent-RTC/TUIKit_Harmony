import { ITPDataTransportLogListener } from '../api/ITPDataTransportLogListener';
import { ITPDataTransportInnerLogger } from './ITPDataTransportInnerLogger';
export declare class TPDataTransportLoggerFactory {
    private static _instance;
    private listener;
    private constructor();
    static getInstance(): TPDataTransportLoggerFactory;
    createInnerLogger(fileName: string, tag?: string): ITPDataTransportInnerLogger;
    setLogger(listener: ITPDataTransportLogListener): void;
    getLogger(): ITPDataTransportLogListener;
}
