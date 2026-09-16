import { MessageInfo } from '@tencentcloud/atomicxcore';
import { TextUtils } from '../../basecomponent/Index';

const TIME_INTERVAL_THRESHOLD: number = 5 * 60;

/**
 * Decides whether a message row should carry a standalone time divider, and
 * formats that timestamp. Mirrors the Android MessageListTimeGroupingPolicy.
 */
export class MessageListTimeGroupingPolicy {
  static get intervalThresholdSeconds(): number {
    return TIME_INTERVAL_THRESHOLD;
  }

  /**
   * @param message the message rendered at `currentIndex`
   * @param previousMessage the message rendered just above it, if any
   * @param isFirstRow whether this row is the first one in the list
   */
  static resolveTimeString(message: MessageInfo | undefined, previousMessage: MessageInfo | undefined,
    isFirstRow: boolean): string | null {
    if (!message || !message.timestamp) {
      return null;
    }

    if (message.timestamp === 0 || message.timestamp < 0 || isNaN(message.timestamp)) {
      console.warn(`[MessageListTimeGroupingPolicy] Invalid message dateTime: ${message.timestamp}, messageID: ${message.msgID}`);
      return null;
    }

    if (isFirstRow) {
      return MessageListTimeGroupingPolicy.formatTimestamp(message.timestamp);
    }

    if (previousMessage && previousMessage.timestamp) {
      const timeInterval = MessageListTimeGroupingPolicy.getIntervalSeconds(message.timestamp,
        previousMessage.timestamp);
      if (timeInterval > TIME_INTERVAL_THRESHOLD) {
        return MessageListTimeGroupingPolicy.formatTimestamp(message.timestamp);
      }
    }

    return null;
  }

  static formatTimestamp(timestamp?: number): string | null {
    if (!timestamp || timestamp <= 0 || isNaN(timestamp)) {
      return null;
    }
    const date = new Date(timestamp * 1000);
    const now = new Date();
    const timeString = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;

    if (MessageListTimeGroupingPolicy.isSameDay(now, date)) {
      return timeString;
    }

    if (MessageListTimeGroupingPolicy.isYesterday(now, date)) {
      return `昨天 ${timeString}`;
    }

    if (now.getFullYear() === date.getFullYear() && MessageListTimeGroupingPolicy.isSameWeek(now, date)) {
      return `${MessageListTimeGroupingPolicy.getLocalizedWeekday(date.getDay())} ${timeString}`;
    }

    const datePart = now.getFullYear() === date.getFullYear()
      ? `${date.getMonth() + 1}/${date.getDate()}`
      : `${date.getFullYear()}/${date.getMonth() + 1}/${date.getDate()}`;
    return `${datePart} ${timeString}`;
  }

  static getIntervalSeconds(timestamp1?: number, timestamp2?: number): number {
    if (!timestamp1 || !timestamp2) {
      return Number.MAX_SAFE_INTEGER;
    }
    return Math.abs(timestamp2 - timestamp1);
  }

  private static isSameDay(first: Date, second: Date): boolean {
    return first.getFullYear() === second.getFullYear() &&
      first.getMonth() === second.getMonth() &&
      first.getDate() === second.getDate();
  }

  private static isYesterday(now: Date, date: Date): boolean {
    const yesterday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    return MessageListTimeGroupingPolicy.isSameDay(yesterday, date);
  }

  private static isSameWeek(first: Date, second: Date): boolean {
    return MessageListTimeGroupingPolicy.getStartOfWeek(first).getTime() ===
      MessageListTimeGroupingPolicy.getStartOfWeek(second).getTime();
  }

  private static getStartOfWeek(date: Date): Date {
    const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const day = start.getDay();
    const daysSinceMonday = (day + 6) % 7;
    start.setDate(start.getDate() - daysSinceMonday);
    return start;
  }

  private static getLocalizedWeekday(dayOfWeek: number): string {
    let weekdayResource: Resource;
    switch (dayOfWeek) {
      case 0:
        weekdayResource = $r('app.string.sunday');
        break;
      case 1:
        weekdayResource = $r('app.string.monday');
        break;
      case 2:
        weekdayResource = $r('app.string.tuesday');
        break;
      case 3:
        weekdayResource = $r('app.string.wednesday');
        break;
      case 4:
        weekdayResource = $r('app.string.thursday');
        break;
      case 5:
        weekdayResource = $r('app.string.friday');
        break;
      case 6:
        weekdayResource = $r('app.string.saturday');
        break;
      default:
        weekdayResource = $r('app.string.unknown');
        break;
    }
    return TextUtils.getResourceString(weekdayResource);
  }
}
