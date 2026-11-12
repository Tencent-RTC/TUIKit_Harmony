import { V2TIMManager, V2TIMMessage } from '@tencentcloud/imsdk';
import { CompletionHandler } from '@tencentcloud/atomicxcore';
import { util } from '@kit.ArkTS';
import { ChatbotMessageProtocol } from './ChatbotMessageProtocol';
import { ChatbotConversationPolicy } from './ChatbotConversationPolicy';

const ERR_INVALID_PARAMETERS: number = 6017;

export interface ChatbotInterruptAction {
  send(messageID: string, fallbackMsgKey: string, completion?: CompletionHandler): boolean;
}

export interface ChatbotControlMessageTransport {
  send(conversationID: string, customData: string, completion?: CompletionHandler): void;
}

class ImsdkChatbotControlMessageTransport implements ChatbotControlMessageTransport {
  send(conversationID: string, customData: string, completion?: CompletionHandler): void {
    try {
      const encoder = new util.TextEncoder();
      const bytes = encoder.encodeInto(customData);
      const messageManager = V2TIMManager.getMessageManager();
      const message = messageManager.createCustomMessage(bytes.buffer as ArrayBuffer);
      message.isExcludedFromLastMessage = true;
      message.isExcludedFromUnreadCount = true;
      const targetID = ChatbotConversationPolicy.targetID(conversationID) ?? '';
      const isGroup = ChatbotConversationPolicy.isGroupConversation(conversationID);
      const result = messageManager.sendMessage(message, {
        receiver: isGroup ? undefined : targetID,
        groupID: isGroup ? targetID : undefined,
        onlineUserOnly: true
      });
      result.promise.then(() => {
        completion?.onSuccess();
      }).catch((error: Object) => {
        completion?.onFailure(ERR_INVALID_PARAMETERS, `${error}`);
      });
    } catch (error) {
      completion?.onFailure(ERR_INVALID_PARAMETERS, `${error}`);
    }
  }
}

export class ChatbotInterruptSender implements ChatbotInterruptAction {
  private static readonly SEND_INTERVAL_MS: number = 1000;
  private readonly conversationID: string;
  private readonly transport: ChatbotControlMessageTransport;
  private readonly elapsedRealtime: () => number;
  private lastSentAtMs?: number;

  constructor(conversationID: string,
    transport: ChatbotControlMessageTransport = new ImsdkChatbotControlMessageTransport(),
    elapsedRealtime: () => number = () => Date.now()) {
    this.conversationID = conversationID;
    this.transport = transport;
    this.elapsedRealtime = elapsedRealtime;
  }

  send(messageID: string, fallbackMsgKey: string, completion?: CompletionHandler): boolean {
    if (messageID.trim().length === 0 && fallbackMsgKey.trim().length === 0) {
      return false;
    }
    const now = this.elapsedRealtime();
    const lastSentAt = this.lastSentAtMs;
    if (lastSentAt !== undefined && now - lastSentAt < ChatbotInterruptSender.SEND_INTERVAL_MS) {
      return false;
    }
    this.lastSentAtMs = now;
    if (messageID.trim().length === 0) {
      this.sendWithMessageKey(fallbackMsgKey, completion);
    } else {
      this.resolveMessageKeyAndSend(messageID, fallbackMsgKey, completion);
    }
    return true;
  }

  private resolveMessageKeyAndSend(messageID: string, fallbackMsgKey: string, completion?: CompletionHandler): void {
    V2TIMManager.getMessageManager().findMessages([messageID]).then((messages: V2TIMMessage[]) => {
      let messageKey = '';
      if (messages && messages.length > 0) {
        messageKey = this.generateMessageKey(messages[0]);
      }
      if (messageKey.trim().length === 0) {
        messageKey = fallbackMsgKey;
      }
      this.sendWithMessageKey(messageKey, completion);
    }).catch((error: Object) => {
      if (fallbackMsgKey.trim().length > 0) {
        this.sendWithMessageKey(fallbackMsgKey, completion);
      } else {
        completion?.onFailure(ERR_INVALID_PARAMETERS, `${error}`);
      }
    });
  }

  private sendWithMessageKey(msgKey: string, completion?: CompletionHandler): void {
    if (msgKey.trim().length === 0) {
      completion?.onFailure(ERR_INVALID_PARAMETERS, 'Chatbot message key is unavailable');
      return;
    }
    this.transport.send(this.conversationID, ChatbotMessageProtocol.createInterruptPayload(msgKey), completion);
  }

  private generateMessageKey(message: V2TIMMessage): string {
    return `${message.seq}_${message.random}_${message.timestamp}`;
  }
}
