import { MessageInfo, ConversationInfo } from '@tencentcloud/atomicxcore';
import { ChatbotConversationController, ChatbotStateListener } from '../../chatbot/ChatbotConversationController';
import { ChatbotConversationState } from '../../chatbot/ChatbotConversationReducer';
import { ChatbotConversationControllers } from '../../chatbot/ChatbotConversationControllerRegistry';
import { ChatbotConversationPolicy } from '../../chatbot/ChatbotConversationPolicy';
import { ChatbotMessageProtocol, ChatbotMessageData } from '../../chatbot/ChatbotMessageProtocol';
import { ChatbotPlaceholderMessageFactory } from '../../chatbot/ChatbotMessageListSupport';
import { MessageUtils } from '../utils/MessageUtils';

export interface MessageListChatbotHost {
  getRawMessages(): MessageInfo[] | undefined;

  getConversationInfo(conversationID: string): ConversationInfo | undefined;

  setDisplayMessages(messages: MessageInfo[]): void;

  refreshDataSource(): void;

  onStreamContentUpdated(): void;
}

export class MessageListChatbotCoordinator {
  private host?: MessageListChatbotHost;
  private controller?: ChatbotConversationController;
  private stateListener?: ChatbotStateListener;
  private messageStateHash: string = '';

  attach(host: MessageListChatbotHost): void {
    this.host = host;
  }

  get activeController(): ChatbotConversationController | undefined {
    return this.controller;
  }

  attachControllerIfNeeded(conversationID: string): void {
    if (!ChatbotConversationPolicy.isChatbotConversation(conversationID)) {
      return;
    }
    const controller = ChatbotConversationControllers.acquire(conversationID);
    this.controller = controller;
    const listener: ChatbotStateListener = (_state: ChatbotConversationState): void => {
      this.rebuildChatbotDisplay(conversationID);
      this.refreshMessagesIfChanged(conversationID);
    };
    this.stateListener = listener;
    controller.addStateListener(listener);
  }

  detachController(conversationID: string): void {
    const controller = this.controller;
    if (!controller) {
      return;
    }
    if (this.stateListener) {
      controller.removeStateListener(this.stateListener);
      this.stateListener = undefined;
    }
    ChatbotConversationControllers.release(conversationID, controller);
    this.controller = undefined;
  }

  resetHash(): void {
    this.messageStateHash = '';
  }

  static getChatbotMessageStateHash(messages: MessageInfo[]): string {
    const parts: string[] = [];
    for (const message of messages) {
      const data: ChatbotMessageData | undefined = ChatbotMessageProtocol.parse(message);
      if (data && data.isVisualResponse) {
        parts.push(MessageUtils.getMessageStateHash(message));
      }
    }
    return parts.join('|');
  }

  refreshMessagesIfChanged(conversationID: string): void {
    const messages = this.host?.getRawMessages();
    if (!messages) {
      return;
    }
    const nextHash = MessageListChatbotCoordinator.getChatbotMessageStateHash(messages);
    if (nextHash === this.messageStateHash) {
      return;
    }
    this.messageStateHash = nextHash;
    this.host?.refreshDataSource();
    this.host?.onStreamContentUpdated();
  }

  buildDisplayMessages(conversationID: string, source: MessageInfo[]): MessageInfo[] {
    const controller = this.controller;
    if (!controller || !controller.shouldShowPlaceholder(source)) {
      return source;
    }
    const conversation = this.host?.getConversationInfo(conversationID);
    const sender = ChatbotPlaceholderMessageFactory.resolveSender(
      source,
      conversationID,
      conversation?.title,
      conversation?.avatarURL
    );
    const placeholder = ChatbotPlaceholderMessageFactory.create(
      conversationID,
      controller.currentState.requestTimestampSeconds,
      sender
    );
    return source.concat(placeholder);
  }

  rebuildChatbotDisplay(conversationID: string): void {
    const messages = this.host?.getRawMessages();
    if (!messages) {
      return;
    }
    const filtered = messages.filter((m: MessageInfo) => MessageUtils.shouldDisplayInMessageList(m));
    this.host?.setDisplayMessages(this.buildDisplayMessages(conversationID, filtered));
  }
}
