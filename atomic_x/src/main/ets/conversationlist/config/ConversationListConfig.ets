import { AppBuilderConfig, ConversationAction } from '../../basecomponent/Index';

export interface ConversationActionConfigProtocol {
  isSupportDelete?: boolean;
  isSupportMute?: boolean;
  isSupportPin?: boolean;
  isSupportMarkUnread?: boolean;
  isSupportClearHistory?: boolean;
}

export class ChatConversationActionConfig implements ConversationActionConfigProtocol {
  private userIsSupportDelete?: boolean;
  private userIsSupportMute?: boolean;
  private userIsSupportPin?: boolean;
  private userIsSupportMarkUnread?: boolean;
  private userIsSupportClearHistory?: boolean;

  constructor(config?: Partial<ConversationActionConfigProtocol>) {
    if (config) {
      this.userIsSupportDelete = config.isSupportDelete;
      this.userIsSupportMute = config.isSupportMute;
      this.userIsSupportPin = config.isSupportPin;
      this.userIsSupportMarkUnread = config.isSupportMarkUnread;
      this.userIsSupportClearHistory = config.isSupportClearHistory;
    }
  }

  get isSupportDelete(): boolean {
    if (this.userIsSupportDelete !== undefined) {
      return this.userIsSupportDelete;
    }
    return AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.DELETE);
  }

  get isSupportMute(): boolean {
    if (this.userIsSupportMute !== undefined) {
      return this.userIsSupportMute;
    }
    return AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MUTE);
  }

  get isSupportPin(): boolean {
    if (this.userIsSupportPin !== undefined) {
      return this.userIsSupportPin;
    }
    return AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.PIN);
  }

  get isSupportMarkUnread(): boolean {
    if (this.userIsSupportMarkUnread !== undefined) {
      return this.userIsSupportMarkUnread;
    }
    return AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.MARK_UNREAD);
  }

  get isSupportClearHistory(): boolean {
    if (this.userIsSupportClearHistory !== undefined) {
      return this.userIsSupportClearHistory;
    }
    return AppBuilderConfig.getInstance().conversationActionList.includes(ConversationAction.CLEAR_HISTORY);
  }
}

