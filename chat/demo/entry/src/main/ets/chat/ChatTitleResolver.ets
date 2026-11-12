import { SupportAgentCatalog } from '../ai/SupportAgentCatalog';

export class ChatTitleResolver {
  static resolve(conversationTitle: string | undefined, conversationID: string): string {
    if (conversationTitle !== undefined && conversationTitle.trim().length > 0) {
      return conversationTitle;
    }
    return SupportAgentCatalog.displayNameForConversation(conversationID) ?? conversationID;
  }
}
