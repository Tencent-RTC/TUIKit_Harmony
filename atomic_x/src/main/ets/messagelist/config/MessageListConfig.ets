import { ThemeState } from '../../basecomponent/Index';
import { AppBuilderConfig, MessageAlignment } from '../../basecomponent/utils/AppBuilderHelper';

/**
 * Message list configuration protocol
 * Defines all configurable properties for message list display
 */
export interface MessageListConfigProtocol {
  alignment?: MessageAlignment;
  isShowTimeMessage?: boolean;
  isShowLeftAvatar?: boolean;
  isShowLeftNickname?: boolean;
  isShowRightAvatar?: boolean;
  isShowRightNickname?: boolean;
  isShowTimeInBubble?: boolean;
  cellSpacing?: number;
  isShowSystemMessage?: boolean;
  isShowUnsupportMessage?: boolean;
  horizontalPadding?:number;
  avatarSpacing?:number;
}

/**
 * Message action configuration protocol
 * Defines supported message actions
 */
export interface MessageActionConfigProtocol {
  isSupportCopy?: boolean;
  isSupportDelete?: boolean;
  isSupportRecall?: boolean;
}

/**
 * Combined configuration protocol for message list
 */
export interface MessageListStyleProtocol extends MessageListConfigProtocol, MessageActionConfigProtocol {}

/**
 * Default chat message style
 * Provides sensible defaults for chat-style message lists
 */
export class ChatMessageListConfig implements MessageListStyleProtocol {
  private themeState: ThemeState = ThemeState.getInstance();
  
  // Display configuration
  private userAlignment?: MessageAlignment;
  private userIsShowTimeMessage?: boolean;
  private userIsShowLeftAvatar?: boolean;
  private userIsShowLeftNickname?: boolean;
  private userIsShowRightAvatar?: boolean;
  private userIsShowRightNickname?: boolean;
  private userIsShowTimeInBubble?: boolean;
  private userCellSpacing?: number;
  private userIsShowSystemMessage?: boolean;
  private userIsShowUnsupportMessage?: boolean;
  private userHorizontalPadding?: number;
  private userAvatarSpacing?: number;
  
  // Action configuration
  private userIsSupportCopy?: boolean;
  private userIsSupportDelete?: boolean;
  private userIsSupportRecall?: boolean;

  constructor(config?: Partial<MessageListStyleProtocol>) {
    if (config) {
      this.userAlignment = config.alignment;
      this.userIsShowTimeMessage = config.isShowTimeMessage;
      this.userIsShowLeftAvatar = config.isShowLeftAvatar;
      this.userIsShowLeftNickname = config.isShowLeftNickname;
      this.userIsShowRightAvatar = config.isShowRightAvatar;
      this.userIsShowRightNickname = config.isShowRightNickname;
      this.userIsShowTimeInBubble = config.isShowTimeInBubble;
      this.userCellSpacing = config.cellSpacing;
      this.userIsShowSystemMessage = config.isShowSystemMessage;
      this.userIsShowUnsupportMessage = config.isShowUnsupportMessage;
      this.userHorizontalPadding = config.horizontalPadding;
      this.userAvatarSpacing = config.avatarSpacing;
      this.userIsSupportCopy = config.isSupportCopy;
      this.userIsSupportDelete = config.isSupportDelete;
      this.userIsSupportRecall = config.isSupportRecall;
    }
  }

  // Getters with default values
  get alignment(): MessageAlignment {
    if (this.userAlignment !== undefined) {
      return this.userAlignment;
    }
    return AppBuilderConfig.getInstance().messageAlignment;
  }

  get isShowTimeMessage(): boolean {
    return this.userIsShowTimeMessage ?? true;
  }

  get isShowLeftAvatar(): boolean {
    return this.userIsShowLeftAvatar ?? true;
  }

  get isShowLeftNickname(): boolean {
    return this.userIsShowLeftNickname ?? false;
  }

  get isShowRightAvatar(): boolean {
    return this.userIsShowRightAvatar ?? false;
  }

  get isShowRightNickname(): boolean {
    return this.userIsShowRightNickname ?? false;
  }

  get isShowTimeInBubble(): boolean {
    return this.userIsShowTimeInBubble ?? false;
  }

  get cellSpacing(): number {
    return this.userCellSpacing ?? 2.0;
  }

  get isShowSystemMessage(): boolean {
    return this.userIsShowSystemMessage ?? true;
  }

  get isShowUnsupportMessage(): boolean {
    return this.userIsShowUnsupportMessage ?? true;
  }

  // Message action getters
  get isSupportCopy(): boolean {
    if (this.userIsSupportCopy !== undefined) {
      return this.userIsSupportCopy;
    }
    return AppBuilderConfig.getInstance().messageActionList.some(action => action === 'copy');
  }

  get isSupportDelete(): boolean {
    if (this.userIsSupportDelete !== undefined) {
      return this.userIsSupportDelete;
    }
    return AppBuilderConfig.getInstance().messageActionList.some(action => action === 'delete');
  }

  get isSupportRecall(): boolean {
    if (this.userIsSupportRecall !== undefined) {
      return this.userIsSupportRecall;
    }
    return AppBuilderConfig.getInstance().messageActionList.some(action => action === 'recall');
  }

  get horizontalPadding(): number {
    return this.userHorizontalPadding ?? 15.0;
  }

  get avatarSpacing(): number {
    return this.userAvatarSpacing ?? 6.0;
  }
}


