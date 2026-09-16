import { ChatbotMessageData, ChatbotMessageSource } from './ChatbotMessageProtocol';

export enum ChatbotConversationStateType {
  IDLE,
  WAITING,
  STREAMING
}

export class ChatbotConversationState {
  readonly type: ChatbotConversationStateType;
  readonly requestTimestampSeconds: number;
  readonly messageID: string;
  readonly msgKey: string;

  private constructor(type: ChatbotConversationStateType, requestTimestampSeconds: number,
    messageID: string, msgKey: string) {
    this.type = type;
    this.requestTimestampSeconds = requestTimestampSeconds;
    this.messageID = messageID;
    this.msgKey = msgKey;
  }

  static idle(): ChatbotConversationState {
    return new ChatbotConversationState(ChatbotConversationStateType.IDLE, 0, '', '');
  }

  static waiting(requestTimestampSeconds: number): ChatbotConversationState {
    return new ChatbotConversationState(ChatbotConversationStateType.WAITING, requestTimestampSeconds, '', '');
  }

  static streaming(messageID: string, msgKey: string): ChatbotConversationState {
    return new ChatbotConversationState(ChatbotConversationStateType.STREAMING, 0, messageID, msgKey);
  }

  get isIdle(): boolean {
    return this.type === ChatbotConversationStateType.IDLE;
  }

  get isWaiting(): boolean {
    return this.type === ChatbotConversationStateType.WAITING;
  }

  get isStreaming(): boolean {
    return this.type === ChatbotConversationStateType.STREAMING;
  }

  equalsTo(other: ChatbotConversationState): boolean {
    return this.type === other.type &&
      this.requestTimestampSeconds === other.requestTimestampSeconds &&
      this.messageID === other.messageID &&
      this.msgKey === other.msgKey;
  }
}

export enum ChatbotConversationEventType {
  TEXT_MESSAGE_SENT,
  BOT_MESSAGE_RECEIVED,
  HISTORY_RESTORED,
  CLEARED
}

export class ChatbotConversationEvent {
  readonly type: ChatbotConversationEventType;
  readonly timestampSeconds: number;
  readonly messageID?: string;
  readonly data?: ChatbotMessageData;

  private constructor(type: ChatbotConversationEventType, timestampSeconds: number,
    messageID?: string, data?: ChatbotMessageData) {
    this.type = type;
    this.timestampSeconds = timestampSeconds;
    this.messageID = messageID;
    this.data = data;
  }

  static textMessageSent(timestampSeconds: number): ChatbotConversationEvent {
    return new ChatbotConversationEvent(ChatbotConversationEventType.TEXT_MESSAGE_SENT, timestampSeconds);
  }

  static botMessageReceived(messageID: string, data: ChatbotMessageData): ChatbotConversationEvent {
    return new ChatbotConversationEvent(ChatbotConversationEventType.BOT_MESSAGE_RECEIVED, 0, messageID, data);
  }

  static historyRestored(messageID?: string, data?: ChatbotMessageData): ChatbotConversationEvent {
    return new ChatbotConversationEvent(ChatbotConversationEventType.HISTORY_RESTORED, 0, messageID, data);
  }

  static cleared(): ChatbotConversationEvent {
    return new ChatbotConversationEvent(ChatbotConversationEventType.CLEARED, 0);
  }
}

function reduceMessage(current: ChatbotConversationState, messageID: string,
  data: ChatbotMessageData): ChatbotConversationState {
  if (data.source === ChatbotMessageSource.FLOW) {
    return data.isFinished ? ChatbotConversationState.idle() :
    ChatbotConversationState.streaming(messageID, data.msgKey);
  }
  if (data.source === ChatbotMessageSource.ERROR) {
    return ChatbotConversationState.idle();
  }
  return current;
}

export class ChatbotConversationReducer {
  static reduce(current: ChatbotConversationState, event: ChatbotConversationEvent): ChatbotConversationState {
    if (event.type === ChatbotConversationEventType.TEXT_MESSAGE_SENT) {
      return ChatbotConversationState.waiting(event.timestampSeconds);
    }
    if (event.type === ChatbotConversationEventType.BOT_MESSAGE_RECEIVED) {
      if (!event.messageID || !event.data) {
        return current;
      }
      return reduceMessage(current, event.messageID, event.data);
    }
    if (event.type === ChatbotConversationEventType.HISTORY_RESTORED) {
      const messageID = event.messageID;
      const data = event.data;
      if (messageID && data && data.source === ChatbotMessageSource.FLOW && !data.isFinished) {
        return ChatbotConversationState.streaming(messageID, data.msgKey);
      }
      return ChatbotConversationState.idle();
    }
    return ChatbotConversationState.idle();
  }
}
