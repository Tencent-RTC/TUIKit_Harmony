import { AppBuilderConfig } from '../../basecomponent/Index';

/**
 * Message input configuration protocol
 * Defines which input features are enabled
 */
export interface MessageInputConfigProtocol {
  isShowAudioRecorder?: boolean;
  isShowPhotoTaker?: boolean;
  isShowMore?: boolean;
  isShowSendButton?: boolean;
}

/**
 * Default chat message input style
 * Provides full-featured input capabilities
 */
export class ChatMessageInputConfig implements MessageInputConfigProtocol {
  private userIsShowAudioRecorder?: boolean;
  private userIsShowPhotoTaker?: boolean;
  private userIsShowMore?: boolean;
  private userIsShowSendButton?: boolean;

  constructor(config?: Partial<MessageInputConfigProtocol>) {
    if (config) {
      this.userIsShowAudioRecorder = config.isShowAudioRecorder;
      this.userIsShowPhotoTaker = config.isShowPhotoTaker;
      this.userIsShowMore = config.isShowMore;
      this.userIsShowSendButton = config.isShowSendButton;
    }
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
}


