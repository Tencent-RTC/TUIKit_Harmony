import { ThemeState } from '../../basecomponent/Index';
import { AppBuilderConfig, MessageAlignment } from '../../basecomponent/utils/AppBuilderHelper';

/**
 * Message action display style
 * - 'dialog': Full-screen dialog style (default, modern style)
 * - 'popup': Floating popup style (classic style, using bindPopup)
 */
export type MessageActionStyle = 'dialog' | 'popup';

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
  enableReadReceipt?: boolean;
  messageActionStyle?: MessageActionStyle;
}

/**
 * Message action configuration protocol
 * Defines supported message actions
 */
export interface MessageActionConfigProtocol {
  isSupportCopy?: boolean;
  isSupportDelete?: boolean;
  isSupportRecall?: boolean;
  isSupportForward?: boolean;
  isSupportMultiSelect?: boolean;
  isSupportReaction?: boolean;
  isSupportConvertToText?: boolean;
  isSupportTranslate?: boolean;
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
  private userEnableReadReceipt?: boolean;
  private userMessageActionStyle?: MessageActionStyle;
  
  // Action configuration
  private userIsSupportCopy?: boolean;
  private userIsSupportDelete?: boolean;
  private userIsSupportRecall?: boolean;
  private userIsSupportForward?: boolean;
  private userIsSupportMultiSelect?: boolean;
  private userIsSupportReaction?: boolean;
  private userIsSupportConvertToText?: boolean;
  private userIsSupportTranslate?: boolean;

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
      this.userEnableReadReceipt = config.enableReadReceipt;
      this.userMessageActionStyle = config.messageActionStyle;
      this.userIsSupportCopy = config.isSupportCopy;
      this.userIsSupportDelete = config.isSupportDelete;
      this.userIsSupportRecall = config.isSupportRecall;
      this.userIsSupportForward = config.isSupportForward;
      this.userIsSupportMultiSelect = config.isSupportMultiSelect;
      this.userIsSupportReaction = config.isSupportReaction;
      this.userIsSupportConvertToText = config.isSupportConvertToText;
      this.userIsSupportTranslate = config.isSupportTranslate;
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
    const useClassicUI = AppBuilderConfig.getInstance().useClassicUI;
    if (useClassicUI) {
      return true;
    }
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

  get isSupportForward(): boolean {
    if (this.userIsSupportForward !== undefined) {
      return this.userIsSupportForward;
    }
    return true; // Default to true
  }

  get isSupportMultiSelect(): boolean {
    if (this.userIsSupportMultiSelect !== undefined) {
      return this.userIsSupportMultiSelect;
    }
    return true; // Default to true
  }

  get horizontalPadding(): number {
    return this.userHorizontalPadding ?? 15.0;
  }

  get avatarSpacing(): number {
    return this.userAvatarSpacing ?? 6.0;
  }

  get enableReadReceipt(): boolean {
    if (this.userEnableReadReceipt !== undefined) {
      return this.userEnableReadReceipt;
    }
    return AppBuilderConfig.getInstance().enableReadReceipt;
  }

  get isSupportReaction(): boolean {
    if (this.userIsSupportReaction !== undefined) {
      return this.userIsSupportReaction;
    }
    return true; // Default to true
  }

  get isSupportConvertToText(): boolean {
    if (this.userIsSupportConvertToText !== undefined) {
      return this.userIsSupportConvertToText;
    }
    return true; // Default to true
  }

  get isSupportTranslate(): boolean {
    if (this.userIsSupportTranslate !== undefined) {
      return this.userIsSupportTranslate;
    }
    return true; // Default to true
  }

  get messageActionStyle(): MessageActionStyle {
    if (this.userMessageActionStyle !== undefined) {
      return this.userMessageActionStyle;
    }
    // Read from AppBuilderConfig - useClassicUI controls all classic style components
    return AppBuilderConfig.getInstance().useClassicUI ? 'popup' : 'dialog';
  }
}

/**
 * Merged message detail page configuration
 * All messages are displayed on the left side with avatars
 * No long press actions allowed (except reaction support)
 */
export class MergedMessageListConfig implements MessageListStyleProtocol {
  // Display configuration - all messages left aligned with avatar
  get alignment(): MessageAlignment {
    return MessageAlignment.LEFT;
  }

  get isShowTimeMessage(): boolean {
    return false;
  }

  get isShowLeftAvatar(): boolean {
    return true;
  }

  get isShowLeftNickname(): boolean {
    return false;
  }

  get isShowRightAvatar(): boolean {
    return true;
  }

  get isShowRightNickname(): boolean {
    return false;
  }

  get isShowTimeInBubble(): boolean {
    return false;
  }

  get cellSpacing(): number {
    return 8;
  }

  get isShowSystemMessage(): boolean {
    return true;
  }

  get isShowUnsupportMessage(): boolean {
    return true;
  }

  get horizontalPadding(): number {
    return 16;
  }

  get avatarSpacing(): number {
    return 8;
  }

  get enableReadReceipt(): boolean {
    return false;
  }

  // Action configuration - disable all actions in merged detail view
  get isSupportCopy(): boolean {
    return false;
  }

  get isSupportDelete(): boolean {
    return false;
  }

  get isSupportRecall(): boolean {
    return false;
  }

  get isSupportForward(): boolean {
    return false;
  }

  get isSupportMultiSelect(): boolean {
    return false;
  }

  // Enable reaction support in merged detail view (matches Swift behavior)
  get isSupportReaction(): boolean {
    return true;
  }

  // Disable convert to text in merged detail view
  get isSupportConvertToText(): boolean {
    return false;
  }

  // Disable translate in merged detail view
  get isSupportTranslate(): boolean {
    return false;
  }

  // Use dialog style in merged detail view
  get messageActionStyle(): MessageActionStyle {
    return 'dialog';
  }
}