import { CompletionHandler, MessageInfo } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../basecomponent/utils/CompletionHandlers';
import { ChatbotMessageData, ChatbotMessageProtocol, ChatbotMessageSource } from './ChatbotMessageProtocol';
import { ChatbotReplyClassifier } from './ChatbotReplyClassifier';
import {
  ChatbotConversationEvent,
  ChatbotConversationReducer,
  ChatbotConversationState
} from './ChatbotConversationReducer';
import { ChatbotInterruptAction, ChatbotInterruptSender } from './ChatbotInterruptSender';

export type ChatbotStateListener = (state: ChatbotConversationState) => void;

class ChatbotPluginResponse {
  readonly message: MessageInfo;
  readonly data: ChatbotMessageData;

  constructor(message: MessageInfo, data: ChatbotMessageData) {
    this.message = message;
    this.data = data;
  }
}

export class ChatbotConversationController {
  private static readonly WATCHDOG_TICK_MS: number = 500;
  private static readonly WAITING_TIMEOUT_MS: number = 15000;
  private static readonly STREAMING_STALL_TIMEOUT_MS: number = 60000;
  private static readonly STREAM_RESUME_WINDOW_SECONDS: number = 60;
  readonly conversationID: string;
  private readonly interruptAction: ChatbotInterruptAction;
  private readonly nowSeconds: () => number;
  private readonly elapsedMillis: () => number;
  private mutableState: ChatbotConversationState = ChatbotConversationState.idle();
  private stateListeners: ChatbotStateListener[] = [];
  private knownMessageIDs: Set<string> = new Set();
  private waitingBaselineMessageIDs: Set<string> = new Set();
  private watchdogJob?: number;
  private lastProgressMillis: number = 0;
  private abandonedMessageIDs: Set<string> = new Set();

  constructor(conversationID: string,
    interruptAction: ChatbotInterruptAction = new ChatbotInterruptSender(conversationID),
    nowSeconds: () => number = () => Math.floor(Date.now() / 1000),
    elapsedMillis: () => number = () => Date.now()) {
    this.conversationID = conversationID;
    this.interruptAction = interruptAction;
    this.nowSeconds = nowSeconds;
    this.elapsedMillis = elapsedMillis;
  }

  get state(): ChatbotConversationState {
    return this.mutableState;
  }

  get isActive(): boolean {
    return !this.mutableState.isIdle;
  }

  addStateListener(listener: ChatbotStateListener): void {
    if (!this.stateListeners.includes(listener)) {
      this.stateListeners.push(listener);
    }
  }

  removeStateListener(listener: ChatbotStateListener): void {
    const index = this.stateListeners.indexOf(listener);
    if (index >= 0) {
      this.stateListeners.splice(index, 1);
    }
  }

  onTextMessageSent(): void {
    this.waitingBaselineMessageIDs = this.knownMessageIDs;
    this.dispatch(ChatbotConversationEvent.textMessageSent(this.nowSeconds()));
  }

  onMessagesChanged(messages: MessageInfo[]): void {
    const current = this.mutableState;
    if (current.isIdle) {
      this.restoreFromHistory(messages);
    } else if (current.isWaiting) {
      const response = this.firstChatbotPluginResponse(messages, (message: MessageInfo, data: ChatbotMessageData) =>
      !this.waitingBaselineMessageIDs.has(message.msgID) && this.isVisualResponse(data));
      if (response) {
        this.dispatch(ChatbotConversationEvent.botMessageReceived(response.message.msgID, response.data));
      } else if (this.hasInboundReply(messages, this.waitingBaselineMessageIDs)) {
        this.dispatch(ChatbotConversationEvent.cleared());
      }
    } else if (current.isStreaming) {
      const response = this.firstChatbotPluginResponse(messages, (message: MessageInfo, data: ChatbotMessageData) =>
      message.msgID === current.messageID && this.isVisualResponse(data));
      if (response) {
        this.dispatch(ChatbotConversationEvent.botMessageReceived(response.message.msgID, response.data));
      }
    }
    const ids: Set<string> = new Set();
    for (const message of messages) {
      if (message.msgID && message.msgID.trim().length > 0) {
        ids.add(message.msgID);
      }
    }
    this.knownMessageIDs = ids;
  }

  placeholderTimestampSeconds(messages: MessageInfo[]): number | undefined {
    const waiting = this.mutableState;
    if (!waiting.isWaiting) {
      return undefined;
    }
    const pluginResponse = this.firstChatbotPluginResponse(messages,
      (message: MessageInfo, data: ChatbotMessageData) =>
      !this.waitingBaselineMessageIDs.has(message.msgID) && this.isVisualResponse(data));
    if (pluginResponse !== undefined || this.hasInboundReply(messages, this.waitingBaselineMessageIDs)) {
      return undefined;
    }
    return waiting.requestTimestampSeconds;
  }

  get canInterrupt(): boolean {
    return this.mutableState.isStreaming;
  }

  sendInterrupt(completion?: CompletionHandler): boolean {
    const streaming = this.mutableState;
    if (!streaming.isStreaming) {
      return false;
    }
    return this.interruptAction.send(streaming.messageID, streaming.msgKey, new CompletionHandlerAdapter(() => {
      completion?.onSuccess();
    }, (code: number, desc: string) => {
      this.abandon(streaming.messageID);
      completion?.onFailure(code, desc);
    }));
  }

  clear(): void {
    this.knownMessageIDs = new Set();
    this.waitingBaselineMessageIDs = new Set();
    this.abandonedMessageIDs = new Set();
    this.dispatch(ChatbotConversationEvent.cleared());
  }

  private hasInboundReply(messages: MessageInfo[], baseline: Set<string>): boolean {
    return messages.some((message: MessageInfo) =>
    !message.isSentBySelf &&
      !!message.msgID && message.msgID.trim().length > 0 &&
      !baseline.has(message.msgID) &&
    ChatbotReplyClassifier.isVisibleReply(message));
  }

  private restoreFromHistory(messages: MessageInfo[]): void {
    const response = this.firstChatbotPluginResponse(messages, (_message: MessageInfo, data: ChatbotMessageData) =>
    this.isVisualResponse(data));
    const resumable = response !== undefined &&
      !this.abandonedMessageIDs.has(response.message.msgID) &&
      this.isRecentEnoughToResume(response.message);
    this.dispatch(ChatbotConversationEvent.historyRestored(
      resumable ? response?.message.msgID : undefined,
      resumable ? response?.data : undefined
    ));
  }

  private isRecentEnoughToResume(message: MessageInfo): boolean {
    const timestamp = message.timestamp;
    if (timestamp === undefined || timestamp <= 0) {
      return false;
    }
    return this.nowSeconds() - timestamp <= ChatbotConversationController.STREAM_RESUME_WINDOW_SECONDS;
  }

  private abandon(messageID?: string): void {
    if (messageID && messageID.trim().length > 0) {
      this.abandonedMessageIDs.add(messageID);
    }
    this.dispatch(ChatbotConversationEvent.cleared());
  }

  private dispatch(event: ChatbotConversationEvent): void {
    const previous = this.mutableState;
    const next = ChatbotConversationReducer.reduce(previous, event);
    this.mutableState = next;
    this.syncWatchdog(next);
    if (next.equalsTo(previous)) {
      return;
    }
    const snapshot = this.stateListeners.slice();
    for (const listener of snapshot) {
      listener(next);
    }
  }

  private syncWatchdog(state: ChatbotConversationState): void {
    if (state.isIdle) {
      if (this.watchdogJob !== undefined) {
        clearInterval(this.watchdogJob);
        this.watchdogJob = undefined;
      }
      return;
    }
    this.lastProgressMillis = this.elapsedMillis();
    if (this.watchdogJob !== undefined) {
      return;
    }
    this.watchdogJob = setInterval(() => {
      const current = this.mutableState;
      if (current.isIdle) {
        return;
      }
      const timeoutMillis = current.isWaiting ? ChatbotConversationController.WAITING_TIMEOUT_MS :
        ChatbotConversationController.STREAMING_STALL_TIMEOUT_MS;
      if (this.elapsedMillis() - this.lastProgressMillis < timeoutMillis) {
        return;
      }
      if (this.watchdogJob !== undefined) {
        clearInterval(this.watchdogJob);
        this.watchdogJob = undefined;
      }
      this.abandon(current.isStreaming ? current.messageID : undefined);
    }, ChatbotConversationController.WATCHDOG_TICK_MS);
  }

  private isVisualResponse(data: ChatbotMessageData): boolean {
    return data.source === ChatbotMessageSource.FLOW || data.source === ChatbotMessageSource.ERROR;
  }

  private firstChatbotPluginResponse(messages: MessageInfo[],
    predicate: (message: MessageInfo, data: ChatbotMessageData) => boolean): ChatbotPluginResponse | undefined {
    for (const message of messages) {
      const data = ChatbotMessageProtocol.parse(message);
      if (!data) {
        continue;
      }
      if (predicate(message, data)) {
        return new ChatbotPluginResponse(message, data);
      }
    }
    return undefined;
  }
}
