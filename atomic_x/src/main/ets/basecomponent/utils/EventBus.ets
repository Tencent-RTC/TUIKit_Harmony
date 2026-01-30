/**
 * EventBus - Event bus for component communication using system Emitter
 * Based on @ohos.events.emitter
 */

import emitter from '@ohos.events.emitter';

export class EventBus {
  private static instance: EventBus;
  private static readonly EVENT_ID_BASE = 1000;
  private static eventIdMap: Map<string, number> = new Map();
  private static nextEventId = EventBus.EVENT_ID_BASE;

  private constructor() {
  }

  static getInstance(): EventBus {
    if (!EventBus.instance) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  /**
   * Get or create event ID for event name
   */
  private static getEventId(eventName: string): number {
    if (!EventBus.eventIdMap.has(eventName)) {
      EventBus.eventIdMap.set(eventName, EventBus.nextEventId++);
    }
    return EventBus.eventIdMap.get(eventName)!;
  }

  /**
   * Subscribe to events
   * @param eventName Event name to subscribe
   * @param callback Event listener callback
   */
  on(eventName: string, callback: (data: emitter.EventData) => void): void {
    const eventId = EventBus.getEventId(eventName);
    console.log(`[EventBus] 📝 Subscribing to "${eventName}" (ID: ${eventId})`);
    
    emitter.on({
      eventId: eventId,
      priority: emitter.EventPriority.LOW
    }, (eventData: emitter.EventData) => {
      console.log(`[EventBus] 📨 Received event "${eventName}":`, JSON.stringify(eventData.data));
      callback(eventData);
    });
  }

  /**
   * Unsubscribe from events
   * @param eventName Event name to unsubscribe
   */
  off(eventName: string): void {
    const eventId = EventBus.getEventId(eventName);
    console.log(`[EventBus] 🗑️ Unsubscribing from "${eventName}" (ID: ${eventId})`);
    emitter.off(eventId);
  }

  /**
   * Post an event
   * @param eventName Event name
   * @param data Event data
   */
  post(eventName: string, data: Record<string, Object>): void {
    const eventId = EventBus.getEventId(eventName);
    console.log(`[EventBus] 📤 Posting event "${eventName}" (ID: ${eventId}):`, JSON.stringify(data));
    
    emitter.emit({
      eventId: eventId,
      priority: emitter.EventPriority.LOW
    }, {
      data: data
    });
  }
}
