/**
 * EventEmitter - A simple event emitter for reactive event streams
 * @example
 * ```typescript
 * @Component
 * struct MessageList {
 *   private store = MessageListStore.create(conversationID);
 *   private unsubscribe?: () => void;
 *
 *   aboutToAppear() {
 *     this.unsubscribe = this.store.messageEventEmitter.subscribe(this, (event) => {
 *       console.info('Received event:', event.type);
 *     });
 *   }
 * }
 * ```
 */
type EventCallback<T> = (event: T) => void;
export declare class EventEmitter<T> {
    private listeners;
    subscribe(target: Object, callback: EventCallback<T>): () => void;
    emit(event: T): void;
    unsubscribe(target: Object): void;
    get subscriberCount(): number;
    clear(): void;
}
export {};
