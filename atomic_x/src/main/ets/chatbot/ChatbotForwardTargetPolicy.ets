import { ChatbotConversationPolicy } from './ChatbotConversationPolicy';

export class ChatbotForwardTargetPartition {
  allowedTargets: string[];
  rejectedChatbotTargets: string[];

  constructor(allowedTargets: string[], rejectedChatbotTargets: string[]) {
    this.allowedTargets = allowedTargets;
    this.rejectedChatbotTargets = rejectedChatbotTargets;
  }
}

export class ChatbotForwardTargetPolicy {
  static partition(conversationIDs: string[]): ChatbotForwardTargetPartition {
    const allowed: string[] = [];
    const rejected: string[] = [];
    for (const conversationID of conversationIDs) {
      if (ChatbotConversationPolicy.isChatbotConversation(conversationID)) {
        rejected.push(conversationID);
      } else {
        allowed.push(conversationID);
      }
    }
    return new ChatbotForwardTargetPartition(allowed, rejected);
  }
}
