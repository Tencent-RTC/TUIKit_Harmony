import {
  ConversationType,
  CustomMessagePayload,
  MessageInfo,
  MessageSenderInfo,
  MessageStatus,
  MessageType
} from '@tencentcloud/atomicxcore';
import { ChatbotMessageData, ChatbotMessageProtocol } from './ChatbotMessageProtocol';
import { ChatbotConversationPolicy } from './ChatbotConversationPolicy';

const PLACEHOLDER_MESSAGE_ID_PREFIX: string = 'chatbot_placeholder_';

export class ChatbotMessageSummaryPolicy {
  static getSummary(message: MessageInfo): string | undefined {
    const data = ChatbotMessageProtocol.parse(message);
    if (!data) {
      return undefined;
    }
    return data.isVisualResponse ? data.displayText : undefined;
  }
}

export class ChatbotPlaceholderMessageFactory {
  static isPlaceholderMessageID(msgID?: string): boolean {
    return msgID?.startsWith(PLACEHOLDER_MESSAGE_ID_PREFIX) ?? false;
  }

  static create(conversationID: string, timestampSeconds: number,
    sender?: MessageSenderInfo): MessageInfo {
    const targetID = ChatbotConversationPolicy.targetID(conversationID) ?? '';
    let resolvedSender: MessageSenderInfo;
    if (sender) {
      const nickname = sender.nickname && sender.nickname.trim().length > 0 ? sender.nickname : targetID;
      resolvedSender = new MessageSenderInfo(
        sender.userID.length > 0 ? sender.userID : targetID,
        sender.avatarURL,
        nickname
      );
    } else {
      resolvedSender = new MessageSenderInfo(targetID, undefined, targetID);
    }

    let conversationType = ConversationType.UNKNOWN;
    if (ChatbotConversationPolicy.isC2CConversation(conversationID)) {
      conversationType = ConversationType.C2C;
    } else if (ChatbotConversationPolicy.isGroupConversation(conversationID)) {
      conversationType = ConversationType.GROUP;
    }

    const payload = new CustomMessagePayload();
    payload.customData = ChatbotMessageProtocol.createPlaceholderCustomData();

    const message = new MessageInfo();
    message.msgID = `${PLACEHOLDER_MESSAGE_ID_PREFIX}${conversationID}`;
    message.status = MessageStatus.SEND_SUCCESS;
    message.timestamp = timestampSeconds;
    message.from = resolvedSender;
    message.to = targetID;
    message.isSentBySelf = false;
    message.conversationType = conversationType;
    message.messageType = MessageType.CUSTOM;
    message.messagePayload = payload;
    message.needReadReceipt = false;
    return message;
  }

  static resolveSender(messages: MessageInfo[], conversationID: string,
    conversationTitle?: string, conversationAvatarURL?: string): MessageSenderInfo | undefined {
    for (let index = messages.length - 1; index >= 0; index--) {
      const message = messages[index];
      if (message.isSentBySelf) {
        continue;
      }
      const data: ChatbotMessageData | undefined = ChatbotMessageProtocol.parse(message);
      if (data && data.isVisualResponse) {
        return message.from;
      }
    }
    if (!conversationTitle && !conversationAvatarURL) {
      return undefined;
    }
    return new MessageSenderInfo(
      ChatbotConversationPolicy.targetID(conversationID) ?? '',
      conversationAvatarURL,
      conversationTitle
    );
  }
}
