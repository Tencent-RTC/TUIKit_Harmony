export interface TUIObserver {
  onNotify(event: string, key: string | null, params: NotifyParams | null): void;
}

export class PublishParams {
  isSticky: boolean;
  data: Record<string, Object> | null;
  callback: ((data: Record<string, Object>) => void) | null;

  constructor(isSticky: boolean = false, data: Record<string, Object> | null = null,
    callback: ((data: Record<string, Object>) => void) | null = null) {
    this.isSticky = isSticky;
    this.data = data;
    this.callback = callback;
  }
}

export class NotifyParams {
  data: Record<string, Object> | null;
  callback: ((data: Record<string, Object>) => void) | null;

  constructor(data: Record<string, Object> | null = null,
    callback: ((data: Record<string, Object>) => void) | null = null) {
    this.data = data;
    this.callback = callback;
  }
}

export class TUIEventBus {
  private static instance: TUIEventBus;
  private observerMap: Map<string, TUIObserver[]> = new Map();
  private stickyDataMap: Map<string, Record<string, Object>> = new Map();

  private constructor() {
  }

  static getInstance(): TUIEventBus {
    if (!TUIEventBus.instance) {
      TUIEventBus.instance = new TUIEventBus();
    }
    return TUIEventBus.instance;
  }

  subscribe(event: string, key: string | null, observer: TUIObserver): void {
    const eventKey = this.buildEventKey(event, key);
    if (!this.observerMap.has(eventKey)) {
      this.observerMap.set(eventKey, []);
    }
    this.observerMap.get(eventKey)!.push(observer);

    const data = this.stickyDataMap.get(eventKey);
    if (data) {
      observer.onNotify(event, key, new NotifyParams(data));
    }
  }

  unsubscribe(event: string, key: string | null, observer: TUIObserver): void {
    const eventKey = this.buildEventKey(event, key);
    const observers = this.observerMap.get(eventKey);
    if (observers) {
      const index = observers.indexOf(observer);
      if (index !== -1) {
        observers.splice(index, 1);
      }
      if (observers.length === 0) {
        this.observerMap.delete(eventKey);
      }
    }
  }

  /**
   * Check whether the given event has at least one live subscriber.
   *
   * Intended for lightweight capability probing (e.g. "Is TUICallKit
   * integrated in the host app?"): a module registers a subscriber during its
   * initialization, and other modules can detect its presence via this API.
   * Mirrors the reflection-based `isCallKitIntegrated` check on Android,
   * where ArkTS has no runtime class lookup.
   */
  hasSubscribers(event: string, key: string | null = null): boolean {
    const eventKey = this.buildEventKey(event, key);
    const observers = this.observerMap.get(eventKey);
    return !!observers && observers.length > 0;
  }

  publish(event: string, key: string | null, params: PublishParams | null): void {
    const eventKey = this.buildEventKey(event, key);

    if (params && params.isSticky && params.data) {
      this.stickyDataMap.set(eventKey, params.data);
    }

    const observers = this.observerMap.get(eventKey);
    if (observers) {
      let notifyParams: NotifyParams | null = null;
      if (params && (params.data || params.callback)) {
        notifyParams = new NotifyParams(params.data, params.callback);
      }

      for (const observer of observers) {
        observer.onNotify(event, key, notifyParams);
      }
    }
  }

  private buildEventKey(event: string, key: string | null): string {
    return key === null ? event : `${event}:${key}`;
  }
}