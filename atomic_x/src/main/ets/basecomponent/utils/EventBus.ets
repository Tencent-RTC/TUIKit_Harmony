/**
 * EventBus - Event bus for component communication using system Emitter
 * Based on @ohos.events.emitter
 */

import emitter from '@ohos.events.emitter';

type EventBusCallback = (data: emitter.EventData) => void;

export class EventBus {
  private static instance: EventBus;
  private listeners: Map<string, EventBusCallback[]> = new Map();

  private constructor() {
  }

  static getInstance(): EventBus {
    if (!EventBus.instance) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  on(eventName: string, callback: EventBusCallback): void {
    let arr = this.listeners.get(eventName);
    if (!arr) {
      arr = [];
      this.listeners.set(eventName, arr);
    }
    arr.push(callback);
  }

  off(eventName: string): void {
    this.listeners.delete(eventName);
  }

  post(eventName: string, data: Record<string, Object>): void {
    const arr = this.listeners.get(eventName);
    if (!arr || arr.length === 0) {
      return;
    }
    const eventData: emitter.EventData = { data: data };
    const snapshot = arr.slice();
    for (const cb of snapshot) {
      try {
        cb(eventData);
      } catch (e) {
        console.error(`[EventBus] listener for "${eventName}" threw:`, e);
      }
    }
  }
}
