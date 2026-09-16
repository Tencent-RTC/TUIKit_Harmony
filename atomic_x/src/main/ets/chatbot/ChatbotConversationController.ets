import { MessageInfo } from '@tencentcloud/atomicxcore';
import { ChatbotMessageData, ChatbotMessageProtocol } from './ChatbotMessageProtocol';
import {
  ChatbotConversationEvent,
  ChatbotConversationReducer,
  ChatbotConversationState
} from './ChatbotConversationReducer';
import {
  ChatbotInterruptFailure,
  ChatbotInterruptSender,
  ChatbotInterruptSuccess
} from './ChatbotInterruptSender';

export type ChatbotStateListener = (state: ChatbotConversationState) => void;

class ParsedMessage {
  message: MessageInfo;
  data: ChatbotMessageData;

  constructor(message: MessageInfo, data: ChatbotMessageData) {
    this.message = message;
    this.data = data;
  }
}

/**
 * Harmony message list is ordered from oldest to newest, which is the reverse of
 * the Android list. Iterating forward here matches Android's asReversed() traversal.
 */
function findFirstParsed(messages: MessageInfo[],
  predicate: (message: MessageInfo, data: ChatbotMessageData) => boolean): ParsedMessage | undefined {
  for (const message of messages) {
    const data = ChatbotMessageProtocol.parse(message);
    if (!data) {
      continue;
    }
    if (predicate(message, data)) {
      return new ParsedMessage(message, data);
    }
  }
  return undefined;
}

export class ChatbotConversationController {
  readonly conversationID: string;
  private state: ChatbotConversationState = ChatbotConversationState.idle();
  private interruptSender: ChatbotInterruptSender;
  private listeners: ChatbotStateListener[] = [];
  private knownVisualMessageIDs: Set<string> = new Set();
  private waitingBaselineMessageIDs: Set<string> = new Set();

  constructor(conversationID: string) {
    this.conversationID = conversationID;
    this.interruptSender = new ChatbotInterruptSender(conversationID);
  }

  get currentState(): ChatbotConversationState {
    return this.state;
  }

  get isActive(): boolean {
    return !this.state.isIdle;
  }

  addStateListener(listener: ChatbotStateListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  removeStateListener(listener: ChatbotStateListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  shouldShowPlaceholder(messages: MessageInfo[]): boolean {
    if (!this.state.isWaiting) {
      return false;
    }
    const response = findFirstParsed(messages, (message: MessageInfo, data: ChatbotMessageData) =>
    !this.waitingBaselineMessageIDs.has(message.msgID) && data.isVisualResponse);
    return response === undefined;
  }

  onTextMessageSent(): void {
    this.waitingBaselineMessageIDs = new Set(this.knownVisualMessageIDs);
    this.dispatch(ChatbotConversationEvent.textMessageSent(Math.floor(Date.now() / 1000)));
  }

  onMessagesChanged(messages: MessageInfo[]): void {
    const current = this.state;
    if (current.isIdle) {
      this.restoreFromHistory(messages);
    } else if (current.isWaiting) {
      const response = findFirstParsed(messages, (message: MessageInfo, data: ChatbotMessageData) =>
      !this.waitingBaselineMessageIDs.has(message.msgID) && data.isVisualResponse);
      if (response) {
        this.dispatch(ChatbotConversationEvent.botMessageReceived(response.message.msgID, response.data));
      }
    } else if (current.isStreaming) {
      const response = findFirstParsed(messages, (message: MessageInfo, data: ChatbotMessageData) =>
      message.msgID === current.messageID && data.isVisualResponse);
      if (response) {
        this.dispatch(ChatbotConversationEvent.botMessageReceived(response.message.msgID, response.data));
      }
    }
    const visualIDs: Set<string> = new Set();
    for (const message of messages) {
      const data = ChatbotMessageProtocol.parse(message);
      if (data && data.isVisualResponse) {
        visualIDs.add(message.msgID);
      }
    }
    this.knownVisualMessageIDs = visualIDs;
  }

  sendInterrupt(onSuccess?: ChatbotInterruptSuccess, onFailure?: ChatbotInterruptFailure): boolean {
    if (!this.state.isStreaming) {
      return false;
    }
    return this.interruptSender.send(this.state.messageID, this.state.msgKey, onSuccess, onFailure);
  }

  clear(): void {
    this.knownVisualMessageIDs = new Set();
    this.waitingBaselineMessageIDs = new Set();
    this.dispatch(ChatbotConversationEvent.cleared());
  }

  private restoreFromHistory(messages: MessageInfo[]): void {
    const response = findFirstParsed(messages, (_message: MessageInfo, data: ChatbotMessageData) =>
    data.isVisualResponse);
    this.dispatch(ChatbotConversationEvent.historyRestored(response?.message.msgID, response?.data));
  }

  private dispatch(event: ChatbotConversationEvent): void {
    const next = ChatbotConversationReducer.reduce(this.state, event);
    if (next.equalsTo(this.state)) {
      return;
    }
    this.state = next;
    const snapshot = this.listeners.slice();
    for (const listener of snapshot) {
      listener(next);
    }
  }
}
