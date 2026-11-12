import { MessageInfo, MessageType, StreamMessagePayload } from '@tencentcloud/atomicxcore';
import { ChatbotMessageProtocol, ChatbotMessageSource } from './ChatbotMessageProtocol';

export enum ChatbotReplyChannel {
  PLUGIN,
  STREAM,
  PLAIN,
  CONTROL
}

export class ChatbotReplyClassifier {
  static isVisibleReply(message: MessageInfo): boolean {
    const channel = ChatbotReplyClassifier.classify(message);
    if (channel === ChatbotReplyChannel.CONTROL) {
      return false;
    }
    if (channel !== ChatbotReplyChannel.STREAM) {
      return true;
    }
    const payload = message.messagePayload as StreamMessagePayload | undefined;
    if (!payload) {
      return true;
    }
    return (payload.markdown ?? '').length > 0;
  }

  static classify(message: MessageInfo): ChatbotReplyChannel {
    if (message.messageType === MessageType.STREAM) {
      return ChatbotReplyChannel.STREAM;
    }
    const plugin = ChatbotMessageProtocol.parse(message);
    if (!plugin) {
      return ChatbotReplyChannel.PLAIN;
    }
    if (plugin.source === ChatbotMessageSource.FLOW || plugin.source === ChatbotMessageSource.ERROR) {
      return ChatbotReplyChannel.PLUGIN;
    }
    return ChatbotReplyChannel.CONTROL;
  }
}
