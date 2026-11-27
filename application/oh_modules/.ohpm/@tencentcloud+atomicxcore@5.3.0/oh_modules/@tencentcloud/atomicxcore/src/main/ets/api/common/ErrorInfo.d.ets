export declare class ErrorInfo extends Error {
    code?: number;
    constructor(code: number, message: string);
    get isSuccess(): boolean;
}
