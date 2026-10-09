import { MessageInfo, MessageQuoteInfo, MessageReaction, MessageStatus } from '@tencentcloud/atomicxcore';
import { MessageConverter } from '@tencentcloud/atomicxcore/src/main/ets/api/common/private/MessageConverter';
import { V2TIMManager, V2TIMMessage, V2TIMMessageReaction, V2TIMMessageReactionResult } from '@tencentcloud/imsdk';

const REACTION_USER_COUNT: number = 10;
const REACTION_CONCURRENT_REQUESTS: number = 20;
const REACTION_REQUEST_TIMEOUT_MS: number = 3000;

export class MergedMessageEnrichment {
  static async fill(messages: MessageInfo[]): Promise<void> {
    await Promise.all([
      MergedMessageEnrichment.fillQuoteInfo(messages).catch((error: Error) => {
        console.error('[MergedMessageEnrichment] fillQuoteInfo failed:', error);
      }),
      MergedMessageEnrichment.fillReactionInfo(messages).catch((error: Error) => {
        console.error('[MergedMessageEnrichment] fillReactionInfo failed:', error);
      })
    ]);
  }

  private static async fillQuoteInfo(messages: MessageInfo[]): Promise<void> {
    const messagesWithQuote: MessageInfo[] = [];
    const messageIDs: Set<string> = new Set();
    for (const message of messages) {
      const quoteInfo = message.quoteInfo;
      if (quoteInfo && !quoteInfo.messagePayload && quoteInfo.msgID.length > 0) {
        messagesWithQuote.push(message);
        messageIDs.add(quoteInfo.msgID);
      }
    }
    if (messagesWithQuote.length === 0) {
      return;
    }

    const ids: string[] = Array.from(messageIDs);
    let foundMessages: V2TIMMessage[];
    try {
      foundMessages = await V2TIMManager.getMessageManager().findMessages(ids);
    } catch (error) {
      console.error('[MergedMessageEnrichment] findMessages failed:', error);
      return;
    }
    const foundByID: Map<string, V2TIMMessage> = new Map();
    for (const rawMessage of foundMessages) {
      if (rawMessage.msgID) {
        foundByID.set(rawMessage.msgID, rawMessage);
      }
    }

    for (const message of messagesWithQuote) {
      const quoteInfo = message.quoteInfo;
      if (!quoteInfo) {
        continue;
      }
      const rawMessage = foundByID.get(quoteInfo.msgID);
      if (!rawMessage) {
        quoteInfo.status = MessageStatus.DELETED;
        continue;
      }
      const quotedMessage = MessageConverter.convertToUIMessage(rawMessage);
      const fullQuoteInfo = new MessageQuoteInfo();
      fullQuoteInfo.msgID = quoteInfo.msgID;
      fullQuoteInfo.timestamp = quoteInfo.timestamp;
      fullQuoteInfo.sequence = quoteInfo.sequence;
      fullQuoteInfo.status = quotedMessage.status;
      fullQuoteInfo.sender = quotedMessage.from;
      fullQuoteInfo.messageType = quotedMessage.messageType;
      fullQuoteInfo.messagePayload = quotedMessage.messagePayload;
      message.quoteInfo = fullQuoteInfo;
    }
  }

  private static async fillReactionInfo(messages: MessageInfo[]): Promise<void> {
    const rawMessages: V2TIMMessage[] = [];
    for (const message of messages) {
      if (message.rawMessage && message.msgID) {
        rawMessages.push(message.rawMessage);
      }
    }
    const reactionsByID: Map<string, MessageReaction[]> = new Map();
    for (let index = 0; index < rawMessages.length; index += REACTION_CONCURRENT_REQUESTS) {
      const requests: Promise<V2TIMMessageReactionResult[]>[] = [];
      for (const rawMessage of rawMessages.slice(index, index + REACTION_CONCURRENT_REQUESTS)) {
        const request = V2TIMManager.getMessageManager()
          .getMessageReactions([rawMessage], REACTION_USER_COUNT)
          .then((result: V2TIMMessageReactionResult): V2TIMMessageReactionResult[] => {
            return Array.isArray(result) ? result as V2TIMMessageReactionResult[] : result ? [result] : [];
          })
          .catch((): V2TIMMessageReactionResult[] => []);
        let timeoutID: number = 0;
        const timeout = new Promise<V2TIMMessageReactionResult[]>((resolve) => {
          timeoutID = setTimeout(() => resolve([]), REACTION_REQUEST_TIMEOUT_MS);
        });
        requests.push(Promise.race([request, timeout]).then((result: V2TIMMessageReactionResult[]) => {
          clearTimeout(timeoutID);
          return result;
        }));
      }
      const results = await Promise.all(requests);
      for (const messageResults of results) {
        for (const result of messageResults) {
          if (!result.msgID || (result.resultCode !== undefined && result.resultCode !== 0)) {
            continue;
          }
          const reactionList: V2TIMMessageReaction[] = result.reactionList ?? [];
          reactionsByID.set(result.msgID, MessageConverter.convertToMessageReactions(reactionList));
        }
      }
    }
    for (const message of messages) {
      const reactions = reactionsByID.get(message.msgID);
      if (reactions) {
        message.reactionList = reactions;
      }
    }
  }
}
