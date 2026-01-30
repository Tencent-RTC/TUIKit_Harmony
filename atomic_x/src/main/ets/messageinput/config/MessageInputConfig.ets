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
 * Message input configuration protocol
 * Defines which input features are enabled
 */
export interface MessageInputConfigProtocol {
  /** Input style: 'minimalist' (default) or 'classic' (WeChat-style) */
  inputStyle?: InputStyle;
  isShowAudioRecorder?: boolean;
  isShowPhotoTaker?: boolean;
  isShowMore?: boolean;
  isShowSendButton?: boolean;
  /** Enable @ mention feature for group conversations (default: true) */
  enableMention?: boolean;
  enableReadReceipt?: boolean;
}

/**
 * Default chat message input style
 * Provides full-featured input capabilities
 */
export class ChatMessageInputConfig implements MessageInputConfigProtocol {
  private userInputStyle?: InputStyle;
  private userIsShowAudioRecorder?: boolean;
  private userIsShowPhotoTaker?: boolean;
  private userIsShowMore?: boolean;
  private userIsShowSendButton?: boolean;
  private userEnableMention?: boolean;
  private userEnableReadReceipt?: boolean;

  constructor(config?: Partial<MessageInputConfigProtocol>) {
    if (config) {
      this.userInputStyle = config.inputStyle;
      this.userIsShowAudioRecorder = config.isShowAudioRecorder;
      this.userIsShowPhotoTaker = config.isShowPhotoTaker;
      this.userIsShowMore = config.isShowMore;
      this.userIsShowSendButton = config.isShowSendButton;
      this.userEnableMention = config.enableMention;
      this.userEnableReadReceipt = config.enableReadReceipt;
    }
  }

  get inputStyle(): InputStyle {
    if (this.userInputStyle !== undefined) {
      return this.userInputStyle;
    }
    // Read from AppBuilderConfig - useClassicUI controls all classic style components
    return AppBuilderConfig.getInstance().useClassicUI ? 'classic' : 'minimalist';
  }

  get isShowAudioRecorder(): boolean {
    return this.userIsShowAudioRecorder ?? true;
  }

  get isShowPhotoTaker(): boolean {
    return this.userIsShowPhotoTaker ?? true;
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
}
