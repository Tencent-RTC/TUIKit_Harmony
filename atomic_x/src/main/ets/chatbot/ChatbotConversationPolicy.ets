const CHATBOT_ID_PREFIX: string = '@RBT#';
const C2C_CONVERSATION_PREFIX: string = 'c2c_';
const GROUP_CONVERSATION_PREFIX: string = 'group_';

export class ChatbotConversationPolicy {
  static isChatbotID(targetID?: string): boolean {
    if (!targetID || targetID.length === 0) {
      return false;
    }
    return targetID.startsWith(CHATBOT_ID_PREFIX);
  }

  static isChatbotConversation(conversationID?: string): boolean {
    return ChatbotConversationPolicy.isChatbotID(ChatbotConversationPolicy.targetID(conversationID));
  }

  static targetID(conversationID?: string): string | undefined {
    if (!conversationID || conversationID.length === 0) {
      return undefined;
    }
    if (conversationID.startsWith(C2C_CONVERSATION_PREFIX)) {
      return conversationID.substring(C2C_CONVERSATION_PREFIX.length);
    }
    if (conversationID.startsWith(GROUP_CONVERSATION_PREFIX)) {
      return conversationID.substring(GROUP_CONVERSATION_PREFIX.length);
    }
    return undefined;
  }

  static isC2CConversation(conversationID?: string): boolean {
    return conversationID?.startsWith(C2C_CONVERSATION_PREFIX) ?? false;
  }

  static isGroupConversation(conversationID?: string): boolean {
    return conversationID?.startsWith(GROUP_CONVERSATION_PREFIX) ?? false;
  }
}
