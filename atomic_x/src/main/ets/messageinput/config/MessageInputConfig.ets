import { AppBuilderConfig } from '../../basecomponent/Index';

/**
 * Input style type for MessageInput component
 * - minimalist: Default style with [+] [input+emoji] [mic] [camera] layout
 * - classic: WeChat-style with [voice] [input] [emoji] [+/send] layout
 */
export type InputStyle = 'minimalist' | 'classic';

/**
 * Expand panel type for classic input style
 * - none: No panel expanded
 * - emoji: Emoji picker panel expanded
 * - action: Action menu panel expanded (image, video, file, etc.)
 */
export type ExpandPanelType = 'none' | 'emoji' | 'action';

/**
 * Stable identifiers of the built-in more menu entries, so hosts can target one
 * of them — for instance to ask for a red dot — without relying on its position.
 */
export class MessageInputActionIDs {
  static readonly ALBUM: string = 'messageInput.album';
  static readonly TAKE_PHOTO: string = 'messageInput.takePhoto';
  static readonly RECORD_VIDEO: string = 'messageInput.recordVideo';
  static readonly FILE: string = 'messageInput.file';
  static readonly VIDEO_CALL: string = 'messageInput.videoCall';
  static readonly AUDIO_CALL: string = 'messageInput.audioCall';
  static readonly CUSTOM_MESSAGE: string = 'messageInput.customMessage';
}

/**
 * Message input configuration protocol
 * Defines which input features are enabled
 */
export interface MessageInputConfigProtocol {
  /** Input style: 'minimalist' (default) or 'classic' (WeChat-style) */
  inputStyle?: InputStyle;
  isShowAudioRecorder?: boolean;
  isShowPhotoTaker?: boolean;
  /** Show audio call entry in the more menu (default: true) */
  isShowAudioCall?: boolean;
  /** Show video call entry in the more menu (default: true) */
  isShowVideoCall?: boolean;
  isShowMore?: boolean;
  isShowSendButton?: boolean;
  /** Enable @ mention feature for group conversations (default: true) */
  enableMention?: boolean;
  enableReadReceipt?: boolean;
  /** Enable "peer is typing" indicator for C2C conversations (default: false) */
  enableTyping?: boolean;
  /** Notified whenever the peer typing state changes; requires enableTyping */
  onTypingStatusChanged?: (isTyping: boolean) => void;
  /**
   * More menu entries that should carry a red dot, identified by
   * {@link MessageInputActionIDs}. The plus button mirrors the dot while any of
   * them is still unread, and both dots clear as soon as the entry is tapped.
   */
  moreActionRedDotIDs?: string[];
  /**
   * Called with the entry's id the first time a dotted entry is tapped, so the
   * host can persist that the dot has been consumed.
   */
  onMoreActionRedDotTap?: (actionID: string) => void;
}

/**
 * Default chat message input style
 * Provides full-featured input capabilities
 */
export class ChatMessageInputConfig implements MessageInputConfigProtocol {
  private userInputStyle?: InputStyle;
  private userIsShowAudioRecorder?: boolean;
  private userIsShowPhotoTaker?: boolean;
  private userIsShowAudioCall?: boolean;
  private userIsShowVideoCall?: boolean;
  private userIsShowMore?: boolean;
  private userIsShowSendButton?: boolean;
  private userEnableMention?: boolean;
  private userEnableReadReceipt?: boolean;
  private userEnableTyping?: boolean;
  private userOnTypingStatusChanged?: (isTyping: boolean) => void;
  private userMoreActionRedDotIDs?: string[];
  private userOnMoreActionRedDotTap?: (actionID: string) => void;

  constructor(config?: Partial<MessageInputConfigProtocol>) {
    if (config) {
      this.userInputStyle = config.inputStyle;
      this.userIsShowAudioRecorder = config.isShowAudioRecorder;
      this.userIsShowPhotoTaker = config.isShowPhotoTaker;
      this.userIsShowAudioCall = config.isShowAudioCall;
      this.userIsShowVideoCall = config.isShowVideoCall;
      this.userIsShowMore = config.isShowMore;
      this.userIsShowSendButton = config.isShowSendButton;
      this.userEnableMention = config.enableMention;
      this.userEnableReadReceipt = config.enableReadReceipt;
      this.userEnableTyping = config.enableTyping;
      this.userOnTypingStatusChanged = config.onTypingStatusChanged;
      this.userMoreActionRedDotIDs = config.moreActionRedDotIDs;
      this.userOnMoreActionRedDotTap = config.onMoreActionRedDotTap;
    }
  }

  get inputStyle(): InputStyle {
    if (this.userInputStyle !== undefined) {
      return this.userInputStyle;
    }
    return 'classic';
  }

  get isShowAudioRecorder(): boolean {
    return this.userIsShowAudioRecorder ?? true;
  }

  get isShowPhotoTaker(): boolean {
    return this.userIsShowPhotoTaker ?? true;
  }

  get isShowAudioCall(): boolean {
    return this.userIsShowAudioCall ?? true;
  }

  get isShowVideoCall(): boolean {
    return this.userIsShowVideoCall ?? true;
  }

  get isShowMore(): boolean {
    return this.userIsShowMore ?? true;
  }

  get isShowSendButton(): boolean {
    if (this.userIsShowSendButton !== undefined) {
      return this.userIsShowSendButton;
    }
    return !AppBuilderConfig.getInstance().hideSendButton;
  }

  get enableMention(): boolean {
    return this.userEnableMention ?? true;
  }

  get enableReadReceipt(): boolean {
    if (this.userEnableReadReceipt !== undefined) {
      return this.userEnableReadReceipt;
    }
    return AppBuilderConfig.getInstance().enableReadReceipt;
  }

  get enableTyping(): boolean {
    return this.userEnableTyping ?? false;
  }

  get onTypingStatusChanged(): ((isTyping: boolean) => void) | undefined {
    return this.userOnTypingStatusChanged;
  }

  get moreActionRedDotIDs(): string[] {
    return this.userMoreActionRedDotIDs ?? [];
  }

  get onMoreActionRedDotTap(): ((actionID: string) => void) | undefined {
    return this.userOnMoreActionRedDotTap;
  }
}
