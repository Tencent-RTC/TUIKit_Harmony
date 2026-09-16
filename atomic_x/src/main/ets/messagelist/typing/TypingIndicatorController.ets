import { MessageInfo, MessageEvent, MessageInputStore, MessageListStore,
  MessageLoadOption, MessageType, CustomMessagePayload, CustomSendMessagePayload,
  SendMessageOption, OnReceiveNewMessage } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';

const TYPING_SEND_INTERVAL_MS: number = 4000;
const TYPING_DISPLAY_TIMEOUT_MS: number = 5000;
const PEER_ACTIVE_WINDOW_MS: number = 30000;
const RECENT_MESSAGE_LOAD_COUNT: number = 20;
const GROUP_CONVERSATION_PREFIX: string = 'group_';

export class TypingMessageProtocol {
  static readonly BUSINESS_ID: string = 'user_typing_status';
  private static readonly USER_ACTION_TYPING: number = 14;
  private static readonly ACTION_PARAM_TYPING_START: string = 'EIMAMSG_InputStatus_Ing';
  private static readonly ACTION_PARAM_TYPING_END: string = 'EIMAMSG_InputStatus_End';

  static buildTypingMessageData(isTyping: boolean): string {
    const json: Record<string, Object> = {
      'businessID': TypingMessageProtocol.BUSINESS_ID,
      'typingStatus': isTyping ? 1 : 0,
      'version': 0,
      'userAction': isTyping ? TypingMessageProtocol.USER_ACTION_TYPING : 0,
      'actionParam': isTyping ? TypingMessageProtocol.ACTION_PARAM_TYPING_START :
        TypingMessageProtocol.ACTION_PARAM_TYPING_END
    };
    return JSON.stringify(json);
  }

  static isTypingMessage(message: MessageInfo): boolean {
    return TypingMessageProtocol.parseTypingStatus(message) !== undefined;
  }

  static parseTypingStatus(message: MessageInfo): boolean | undefined {
    if (message.messageType !== MessageType.CUSTOM) {
      return undefined;
    }
    const payload = message.messagePayload as CustomMessagePayload | undefined;
    if (!payload) {
      return undefined;
    }
    return TypingMessageProtocol.parseTypingStatusData(payload.customData);
  }

  static parseTypingStatusData(data: string): boolean | undefined {
    if (!data) {
      return undefined;
    }
    try {
      const json = JSON.parse(data) as Record<string, Object>;
      if (json['businessID'] !== TypingMessageProtocol.BUSINESS_ID) {
        return undefined;
      }
      if (json['typingStatus'] !== undefined) {
        return json['typingStatus'] === 1;
      }
      const actionParam = json['actionParam'];
      if (actionParam === TypingMessageProtocol.ACTION_PARAM_TYPING_START) {
        return true;
      }
      if (actionParam === TypingMessageProtocol.ACTION_PARAM_TYPING_END) {
        return false;
      }
      return undefined;
    } catch (error) {
      return undefined;
    }
  }
}

export type TypingStateListener = (isTyping: boolean) => void;

export class TypingIndicatorController {
  private static readonly controllers: Map<string, TypingIndicatorController> = new Map();

  static obtain(conversationID: string): TypingIndicatorController {
    let controller = TypingIndicatorController.controllers.get(conversationID);
    if (!controller) {
      controller = new TypingIndicatorController(conversationID);
      TypingIndicatorController.controllers.set(conversationID, controller);
    }
    controller.retainCount++;
    return controller;
  }

  static release(controller: TypingIndicatorController): void {
    controller.retainCount--;
    if (controller.retainCount <= 0) {
      TypingIndicatorController.controllers.delete(controller.conversationID);
      controller.destroy();
    }
  }

  static isTypingConversation(conversationID: string): boolean {
    return conversationID.length > 0 && !conversationID.startsWith(GROUP_CONVERSATION_PREFIX);
  }

  private readonly conversationID: string;
  private readonly peerUserID: string;
  private readonly inputStore: MessageInputStore;
  private listenStore?: MessageListStore;
  private unsubscribeFlow?: () => void;
  private listeners: TypingStateListener[] = [];
  private typingState: boolean = false;
  private typingTimeoutId?: number;
  private retainCount: number = 0;
  private lastTypingSendTimeMs: number = 0;
  private hasSentTypingStart: boolean = false;
  private lastPeerMessageTimeMs: number = 0;

  private constructor(conversationID: string) {
    this.conversationID = conversationID;
    this.peerUserID = conversationID;
    this.inputStore = MessageInputStore.create(conversationID);
    if (TypingIndicatorController.isTypingConversation(conversationID)) {
      this.listenStore = MessageListStore.create(conversationID);
      const option = new MessageLoadOption();
      option.pageCount = RECENT_MESSAGE_LOAD_COUNT;
      this.listenStore.loadMessages(option, new CompletionHandlerAdapter(() => {
        this.trackLastPeerMessageTime();
      }));
      this.listenStore.messageEventFlow.subscribe(this, (event: MessageEvent) => {
        if (event instanceof OnReceiveNewMessage) {
          this.handleNewMessage(event.message);
        }
      });
      this.unsubscribeFlow = () => {
        this.listenStore?.messageEventFlow.unsubscribe(this);
      };
      this.trackLastPeerMessageTime();
    }
  }

  get isTyping(): boolean {
    return this.typingState;
  }

  addStateListener(listener: TypingStateListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  removeStateListener(listener: TypingStateListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  sendTypingStatus(isTyping: boolean): void {
    if (this.peerUserID.length === 0) {
      return;
    }
    if (!this.isPeerActive()) {
      return;
    }
    if (isTyping) {
      const now = Date.now();
      if (now - this.lastTypingSendTimeMs < TYPING_SEND_INTERVAL_MS) {
        return;
      }
      this.lastTypingSendTimeMs = now;
    } else if (!this.hasSentTypingStart) {
      return;
    }
    this.hasSentTypingStart = isTyping;
    this.dispatchTypingMessage(isTyping);
  }

  private trackLastPeerMessageTime(): void {
    const list = this.listenStore?.state?.messageList ?? [];
    for (let i = list.length - 1; i >= 0; i--) {
      const message = list[i];
      if (message && !message.isSentBySelf) {
        const timeMs = (message.timestamp ?? 0) * 1000;
        if (timeMs > this.lastPeerMessageTimeMs) {
          this.lastPeerMessageTimeMs = timeMs;
        }
        break;
      }
    }
  }

  private handleNewMessage(message: MessageInfo): void {
    if (!message || message.isSentBySelf) {
      return;
    }
    this.lastPeerMessageTimeMs = Date.now();
    const typingStatus = TypingMessageProtocol.parseTypingStatus(message);
    if (typingStatus !== undefined) {
      this.updatePeerTyping(typingStatus);
    }
  }

  private updatePeerTyping(isTyping: boolean): void {
    if (this.typingTimeoutId !== undefined) {
      clearTimeout(this.typingTimeoutId);
      this.typingTimeoutId = undefined;
    }
    if (isTyping) {
      this.setTypingState(true);
      this.typingTimeoutId = setTimeout(() => {
        this.typingTimeoutId = undefined;
        this.setTypingState(false);
      }, TYPING_DISPLAY_TIMEOUT_MS);
    } else {
      this.setTypingState(false);
    }
  }

  private setTypingState(isTyping: boolean): void {
    if (this.typingState === isTyping) {
      return;
    }
    this.typingState = isTyping;
    this.listeners.forEach((listener: TypingStateListener) => listener(isTyping));
  }

  private isPeerActive(): boolean {
    if (this.lastPeerMessageTimeMs === 0) {
      return false;
    }
    return Date.now() - this.lastPeerMessageTimeMs < PEER_ACTIVE_WINDOW_MS;
  }

  private dispatchTypingMessage(isTyping: boolean): void {
    const payload = new CustomSendMessagePayload(
      TypingMessageProtocol.buildTypingMessageData(isTyping), '', '');
    const option = new SendMessageOption();
    option.onlineUserOnly = true;
    this.inputStore.sendMessage(payload, option);
  }

  private destroy(): void {
    if (this.typingTimeoutId !== undefined) {
      clearTimeout(this.typingTimeoutId);
      this.typingTimeoutId = undefined;
    }
    if (this.hasSentTypingStart) {
      this.hasSentTypingStart = false;
      this.dispatchTypingMessage(false);
    }
    this.unsubscribeFlow?.();
    this.unsubscribeFlow = undefined;
    this.listeners = [];
    this.typingState = false;
  }
}
