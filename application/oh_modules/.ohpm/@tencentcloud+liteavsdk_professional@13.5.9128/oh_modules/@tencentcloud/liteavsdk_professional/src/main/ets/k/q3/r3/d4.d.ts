export interface ITXVodPreloadCallback {
    onComplete(taskId: number, url: string): void;
    onError(taskId: number, url: string, code: number, msg: string): void;
}
