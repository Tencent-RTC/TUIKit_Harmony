import { MessageInfo, MessageStatus } from '@tencentcloud/atomicxcore';
import { ChatbotMessageData, ChatbotMessageProtocol, ChatbotMessageSource } from './ChatbotMessageProtocol';

/**
 * Action capability rules for chatbot streaming messages.
 * Mirrors the Android buildActionCapability() chatbot branch: a streaming answer
 * only becomes actionable (copy / forward / delete) once it has completed.
 */
export class ChatbotMessageActionPolicy {
  static isChatbotVisualMessage(message?: MessageInfo): boolean {
    return ChatbotMessageProtocol.parse(message)?.isVisualResponse ?? false;
  }

  static isComplete(message?: MessageInfo): boolean {
    if (!message) {
      return false;
    }
    const data: ChatbotMessageData | undefined = ChatbotMessageProtocol.parse(message);
    if (!data || !data.isVisualResponse) {
      return false;
    }
    if (data.isPlaceholder) {
      return false;
    }
    if (message.status === MessageStatus.VIOLATION) {
      return false;
    }
    return data.source === ChatbotMessageSource.ERROR || data.isFinished;
  }

  /**
   * Whether the message can be long-pressed / selected at all.
   * Unfinished streaming answers and interrupt signals are non-interactive.
   */
  static isInteractionEnabled(message?: MessageInfo): boolean {
    const data: ChatbotMessageData | undefined = ChatbotMessageProtocol.parse(message);
    if (!data) {
      return true;
    }
    if (data.source === ChatbotMessageSource.ERROR) {
      return true;
    }
    if (data.source === ChatbotMessageSource.FLOW) {
      return data.isFinished && !data.isPlaceholder;
    }
    return false;
  }

  static displayText(message?: MessageInfo): string {
    return ChatbotMessageProtocol.parse(message)?.displayText ?? '';
  }
}
