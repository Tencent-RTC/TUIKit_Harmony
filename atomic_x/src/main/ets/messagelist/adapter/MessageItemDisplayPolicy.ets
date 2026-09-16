import { CustomMessagePayload, MessageInfo, MessageType } from '@tencentcloud/atomicxcore';
import { shouldHideCallingMessage } from '../cells/CallMessageView';
import { CallingMessageDataProvider, CallParticipantType } from '../utils/CallingMessageDataProvider';
import { ChatbotMessageProtocol, ChatbotMessageSource } from '../../chatbot/ChatbotMessageProtocol';
import { TypingMessageProtocol } from '../typing/TypingIndicatorController';

const GROUP_CREATE_BUSINESS_ID: string = 'group_create';

export class MessageItemDisplayPolicy {
  static isGroupCreatedMessage(message: MessageInfo): boolean {
    const customPayload = message.messagePayload as CustomMessagePayload | undefined;
    if (!customPayload) {
      return false;
    }
    return MessageItemDisplayPolicy.isGroupCreated(customPayload);
  }

  static isChatbotVisualMessage(message: MessageInfo): boolean {
    const data = ChatbotMessageProtocol.parse(message);
    return data?.isVisualResponse ?? false;
  }

  static isChatbotInterruptMessage(message: MessageInfo): boolean {
    return ChatbotMessageProtocol.parse(message)?.source === ChatbotMessageSource.INTERRUPT;
  }

  static shouldHideMessageEntirely(message: MessageInfo): boolean {
    if (shouldHideCallingMessage(message) || MessageItemDisplayPolicy.isChatbotInterruptMessage(message)) {
      return true;
    }
    return TypingMessageProtocol.isTypingMessage(message);
  }

  static isBusinessCustomMessage(message: MessageInfo): boolean {
    if (message.messageType !== MessageType.CUSTOM) {
      return false;
    }
    if (MessageItemDisplayPolicy.isGroupCreatedMessage(message)) {
      return false;
    }
    if (MessageItemDisplayPolicy.isChatbotInterruptMessage(message)) {
      return false;
    }
    if (MessageItemDisplayPolicy.isCallingC2C(message) ||
      MessageItemDisplayPolicy.isCallingGroup(message) ||
      MessageItemDisplayPolicy.isCallingSignal(message)) {
      return false;
    }
    return true;
  }

  static isCallingSignal(message: MessageInfo): boolean {
    return new CallingMessageDataProvider(message).isCallingSignal;
  }

  static isCallingC2C(message: MessageInfo): boolean {
    const provider = new CallingMessageDataProvider(message);
    return provider.isCallingSignal && provider.participantType === CallParticipantType.c2c;
  }

  static isCallingGroup(message: MessageInfo): boolean {
    const provider = new CallingMessageDataProvider(message);
    return provider.isCallingSignal && provider.participantType === CallParticipantType.group;
  }

  private static isGroupCreated(customPayload: CustomMessagePayload): boolean {
    const dataStr = customPayload.customData;
    if (!dataStr) {
      return false;
    }
    try {
      const customInfo = JSON.parse(dataStr) as Record<string, string | number | boolean | object>;
      return customInfo["businessID"] === GROUP_CREATE_BUSINESS_ID;
    } catch (error) {
      console.error('[MessageItemDisplayPolicy] isGroupCreated error:', error);
      return false;
    }
  }
}
