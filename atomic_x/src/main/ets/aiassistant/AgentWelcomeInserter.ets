import { MessageInfo, MessageInputStore, MessageListStore, TextSendMessagePayload } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../basecomponent/utils/CompletionHandlers';
import { AIAssistantAgent } from './AIAssistantAgent';
import { AIAssistantControlMessages } from './AIAssistantControlMessages';

export class AgentWelcomeInserter {
  private static pendingCallbacks: Map<string, (() => void)[]> = new Map();

  static insertIfConversationEmpty(agent: AIAssistantAgent, onDone: () => void): void {
    const welcome = agent.welcome;
    if (welcome.length === 0) {
      onDone();
      return;
    }
    const conversationID = agent.conversationID;
    let callbacks = AgentWelcomeInserter.pendingCallbacks.get(conversationID);
    if (!callbacks) {
      callbacks = [];
      AgentWelcomeInserter.pendingCallbacks.set(conversationID, callbacks);
    }
    callbacks.push(onDone);
    if (callbacks.length !== 1) {
      return;
    }
    const store = MessageListStore.create(conversationID);
    store.loadMessages(undefined, new CompletionHandlerAdapter(() => {
      const hasHistory = store.state.messageList.some((message: MessageInfo) =>
      !AIAssistantControlMessages.isControlMessage(message));
      if (hasHistory) {
        AgentWelcomeInserter.finish(conversationID);
      } else {
        AgentWelcomeInserter.insertLocal(agent.imUserId, welcome, conversationID);
      }
    }, () => {
      AgentWelcomeInserter.finish(conversationID);
    }));
  }

  private static insertLocal(robotUserId: string, welcome: string, conversationID: string): void {
    MessageInputStore.create(conversationID).insertLocalMessage(
      new TextSendMessagePayload(welcome),
      robotUserId,
      new CompletionHandlerAdapter(() => {
        AgentWelcomeInserter.finish(conversationID);
      }, () => {
        AgentWelcomeInserter.finish(conversationID);
      })
    );
  }

  private static finish(conversationID: string): void {
    const callbacks = AgentWelcomeInserter.pendingCallbacks.get(conversationID) ?? [];
    AgentWelcomeInserter.pendingCallbacks.delete(conversationID);
    for (const callback of callbacks) {
      callback();
    }
  }
}
