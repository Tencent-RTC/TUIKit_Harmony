import { ChatbotConversationController } from './ChatbotConversationController';

class RegistryEntry {
  controller: ChatbotConversationController;
  referenceCount: number = 0;

  constructor(controller: ChatbotConversationController) {
    this.controller = controller;
  }
}

class ChatbotConversationControllerRegistry {
  private entries: Map<string, RegistryEntry> = new Map();

  acquire(conversationID: string, preferredController?: ChatbotConversationController): ChatbotConversationController {
    let entry = this.entries.get(conversationID);
    if (!entry) {
      entry = new RegistryEntry(preferredController ?? new ChatbotConversationController(conversationID));
      this.entries.set(conversationID, entry);
    }
    entry.referenceCount += 1;
    return entry.controller;
  }

  release(conversationID: string, controller: ChatbotConversationController): void {
    const entry = this.entries.get(conversationID);
    if (!entry || entry.controller !== controller) {
      return;
    }
    entry.referenceCount = Math.max(0, entry.referenceCount - 1);
    if (entry.referenceCount === 0 && !entry.controller.isActive) {
      this.entries.delete(conversationID);
    }
  }

  clear(conversationID: string): void {
    const entry = this.entries.get(conversationID);
    if (!entry) {
      return;
    }
    entry.controller.clear();
    if (entry.referenceCount === 0) {
      this.entries.delete(conversationID);
    }
  }
}

const registry: ChatbotConversationControllerRegistry = new ChatbotConversationControllerRegistry();

export class ChatbotConversationControllers {
  static acquire(conversationID: string): ChatbotConversationController {
    return registry.acquire(conversationID);
  }

  static retain(conversationID: string,
    controller: ChatbotConversationController): ChatbotConversationController {
    return registry.acquire(conversationID, controller);
  }

  static release(conversationID: string, controller: ChatbotConversationController): void {
    registry.release(conversationID, controller);
  }

  static clear(conversationID: string): void {
    registry.clear(conversationID);
  }
}
