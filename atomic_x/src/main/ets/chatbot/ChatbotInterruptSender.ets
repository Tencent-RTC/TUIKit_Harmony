import { V2TIMManager, V2TIMMessage } from '@tencentcloud/imsdk';
import { util } from '@kit.ArkTS';
import { ChatbotMessageProtocol } from './ChatbotMessageProtocol';
import { ChatbotConversationPolicy } from './ChatbotConversationPolicy';

const SEND_INTERVAL_MS: number = 1000;
const ERR_INVALID_PARAMETERS: number = 6017;

export type ChatbotInterruptSuccess = () => void;
export type ChatbotInterruptFailure = (code: number, desc: string) => void;

function buildMessageKey(message: V2TIMMessage): string {
  return `${message.seq}_${message.random}_${message.timestamp}`;
}

export class ChatbotInterruptSender {
  private conversationID: string;
  private lastSentAtMs?: number;

  constructor(conversationID: string) {
    this.conversationID = conversationID;
  }

  send(messageID: string, fallbackMsgKey: string, onSuccess?: ChatbotInterruptSuccess,
    onFailure?: ChatbotInterruptFailure): boolean {
    if (messageID.trim().length === 0 && fallbackMsgKey.trim().length === 0) {
      return false;
    }
    const now = Date.now();
    if (this.lastSentAtMs !== undefined && now - this.lastSentAtMs < SEND_INTERVAL_MS) {
      return false;
    }
    this.lastSentAtMs = now;
    if (messageID.trim().length === 0) {
      this.sendWithMessageKey(fallbackMsgKey, onSuccess, onFailure);
    } else {
      this.resolveMessageKeyAndSend(messageID, fallbackMsgKey, onSuccess, onFailure);
    }
    return true;
  }

  private resolveMessageKeyAndSend(messageID: string, fallbackMsgKey: string,
    onSuccess?: ChatbotInterruptSuccess, onFailure?: ChatbotInterruptFailure): void {
    V2TIMManager.getMessageManager().findMessages([messageID]).then((messages: V2TIMMessage[]) => {
      let messageKey = '';
      if (messages && messages.length > 0) {
        messageKey = buildMessageKey(messages[0]);
      }
      if (messageKey.trim().length === 0) {
        messageKey = fallbackMsgKey;
      }
      this.sendWithMessageKey(messageKey, onSuccess, onFailure);
    }).catch((error: Object) => {
      if (fallbackMsgKey.trim().length > 0) {
        this.sendWithMessageKey(fallbackMsgKey, onSuccess, onFailure);
      } else {
        onFailure?.(ERR_INVALID_PARAMETERS, `${error}`);
      }
    });
  }

  private sendWithMessageKey(msgKey: string, onSuccess?: ChatbotInterruptSuccess,
    onFailure?: ChatbotInterruptFailure): void {
    if (msgKey.trim().length === 0) {
      onFailure?.(ERR_INVALID_PARAMETERS, 'Chatbot message key is unavailable');
      return;
    }
    try {
      const customData = ChatbotMessageProtocol.createInterruptPayload(msgKey);
      const encoder = new util.TextEncoder();
      const bytes = encoder.encodeInto(customData);
      const messageManager = V2TIMManager.getMessageManager();
      const message = messageManager.createCustomMessage(bytes.buffer as ArrayBuffer);
      message.isExcludedFromLastMessage = true;
      message.isExcludedFromUnreadCount = true;
      const targetID = ChatbotConversationPolicy.targetID(this.conversationID) ?? '';
      const isGroup = ChatbotConversationPolicy.isGroupConversation(this.conversationID);
      const result = messageManager.sendMessage(message, {
        receiver: isGroup ? undefined : targetID,
        groupID: isGroup ? targetID : undefined,
        onlineUserOnly: true
      });
      result.promise.then(() => {
        onSuccess?.();
      }).catch((error: Object) => {
        onFailure?.(ERR_INVALID_PARAMETERS, `${error}`);
      });
    } catch (error) {
      onFailure?.(ERR_INVALID_PARAMETERS, `${error}`);
    }
  }
}
