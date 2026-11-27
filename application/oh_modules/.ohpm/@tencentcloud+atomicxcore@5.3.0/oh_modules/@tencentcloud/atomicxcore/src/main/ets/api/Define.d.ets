/**
 * Callback for experimental event subscription, delivering roomID and JSON payload.
 */
export type ExperimentalEventCallback = (roomID: string, jsonStr: string) => void;
export { SubscriptionToken } from '../engine/EngineBridge';
export interface ListResultCompletionHandler<T> {
    onSuccess(result: Array<T>, cursor: string): void;
    onFailure(code: number, desc: string): void;
}
export interface CompletionHandler {
    onSuccess(): void;
    onFailure(code: number, desc: string): void;
}
