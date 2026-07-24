import { MessageInfo, MessageQuoteInfo } from '@tencentcloud/atomicxcore';

export class MessageQuoteLocatePolicy {
  static findLoadedTargetMessageId(quoteInfo: MessageQuoteInfo, messages: MessageInfo[]): string | undefined {
    const quoteMessageId = quoteInfo.msgID;
    if (quoteMessageId && quoteMessageId.length > 0) {
      const found = messages.find((m: MessageInfo): boolean => m.msgID === quoteMessageId);
      if (found) {
        return quoteMessageId;
      }
    }
    const sequence = quoteInfo.sequence;
    if (sequence <= 0) {
      return undefined;
    }
    const target = messages.find((m: MessageInfo): boolean => m.sequence === sequence);
    if (target && target.msgID && target.msgID.length > 0) {
      return target.msgID;
    }
    return undefined;
  }

  static shouldLoadAround(quoteInfo: MessageQuoteInfo, messages: MessageInfo[]): boolean {
    if (quoteInfo.sequence <= 0) {
      return false;
    }
    return MessageQuoteLocatePolicy.findLoadedTargetMessageId(quoteInfo, messages) === undefined;
  }

  static buildCursorMessage(quoteInfo: MessageQuoteInfo): MessageInfo {
    const cursor = new MessageInfo();
    cursor.msgID = quoteInfo.msgID;
    cursor.timestamp = quoteInfo.timestamp;
    cursor.sequence = quoteInfo.sequence;
    return cursor;
  }
}
