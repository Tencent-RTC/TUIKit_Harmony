import { MessageInfo, MessageStatus, MessageBody, MessageListStore, MessageActionStore, ErrorInfo } from '@tencentcloud/atomicxcore';
import { ThemeState, Toast } from '../../basecomponent/Index';
import { AudioPlayer, AudioPlayerListener } from '../../audioplayer/Index';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { MessageRenderContext } from '../context/MessageRenderContext';

class SoundMessageAudioListener implements AudioPlayerListener {
  private component: SoundMessageViewContent;

  constructor(component: SoundMessageViewContent) {
    this.component = component;
  }

  onPlay(): void {
    this.component.isPlaying = true;
  }

  onPause(): void {
    this.component.isPlaying = false;
  }

  onResume(): void {
    this.component.isPlaying = true;
  }

  onProgressUpdate(currentPosition: number, duration: number): void {
    this.component.currentPosition = currentPosition;
    this.component.progress = duration > 0 ? (currentPosition / duration) * 100 : 0;
  }

  onCompletion(): void {
    this.component.isPlaying = false;
    this.component.progress = 0;
    this.component.currentPosition = 0;
  }

  onError(errorMessage: string): void {
    console.error('[SoundMessageView] Audio player error:', errorMessage);
    this.component.isPlaying = false;
    this.component.progress = 0;
    this.component.currentPosition = 0;
  }
}

@Component
export struct SoundMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @State isPlaying: boolean = false;
  @State progress: number = 0;
  @State currentPosition: number = 0;
  @ObjectLink messageListStore: MessageListStore;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  // ASR related states
  @State isConverting: boolean = false;
  @State isAsrExpanded: boolean = false;
  asrDisplayManager?: AsrDisplayManager = undefined;
  onAsrBubbleLongPress?: (message: MessageInfo) => void;
  private audioPlayer: AudioPlayer = AudioPlayer.create();
  private stateChangeListener?: () => void;

  aboutToAppear() {
    const listener = new SoundMessageAudioListener(this);
    this.audioPlayer.setListener(listener);
    
    // Initialize ASR expanded state from manager
    if (this.asrDisplayManager && this.message?.msgID) {
      this.isAsrExpanded = this.asrDisplayManager.isExpanded(this.message.msgID);
      this.isConverting = this.asrDisplayManager.isConverting(this.message.msgID);
      
      // Listen for state changes
      this.stateChangeListener = () => {
        if (this.message?.msgID) {
          this.isAsrExpanded = this.asrDisplayManager!.isExpanded(this.message.msgID);
          this.isConverting = this.asrDisplayManager!.isConverting(this.message.msgID);
        }
      };
      this.asrDisplayManager.addListener(this.stateChangeListener);
    }
  }

  aboutToDisappear() {
    this.audioPlayer.stop();
    
    // Remove listener
    if (this.asrDisplayManager && this.stateChangeListener) {
      this.asrDisplayManager.removeListener(this.stateChangeListener);
    }
  }

  build() {
    // Audio bubble only (no ASR bubble inside)
    Stack({ alignContent: Alignment.BottomEnd }) {
      // Main content row
      Row() {
        Image(this.isPlaying ? $rawfile('messagelist/voice_pause.png') : $rawfile('messagelist/voice_play.svg'))
          .width(12)
          .height(12)
          .fillColor(this.message?.isSelf ? this.themeState.colors.textColorAntiSecondary :
          this.themeState.colors.textColorPrimary)
          .margin({ left: 16 })
          .draggable(false)

        Row() {
          ForEach([0, 1, 2], (item: number) => {
            Image($rawfile('messagelist/voice_play_animation.svg'))
              .width(21)
              .height(21)
              .margin({ left: 4 })
              .fillColor(this.message?.isSelf ? this.themeState.colors.textColorAntiSecondary :
              this.themeState.colors.textColorPrimary)
              .opacity(this.progress > (item * 33.33) ? 1 : 0.3)
              .draggable(false)
          })
        }
        .margin({ left: 8, bottom: 4 })

        Text(this.formatDuration(this.messageBody?.soundDuration || 0))
          .fontSize(12)
          .fontColor(this.message?.isSelf ? this.themeState.colors.textColorAntiSecondary :
          this.themeState.colors.textColorPrimary)
          .margin({ 
            left: 8, 
            right: this.shouldShowStatusIcons() ? 40 : 16  
          })
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .onClick(() => {
        this.togglePlay();
      })

      // Status icons positioned at bottom right
      Row() {
        if (this.message && MessageUtils.shouldShowReadReceipt(this.message,
          this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
          this.isInMergedDetailView)) {
          Image(MessageUtils.getReadReceiptIconResource(this.message))
            .width(14)
            .height(14)
            .margin({ right: 4 })
        }

        if (this.message?.status === MessageStatus.sending) {
          LoadingProgress()
            .width(12)
            .height(12)
            .margin({ right: 4 })
        }
      }
      .justifyContent(FlexAlign.End)
      .margin({ bottom: 4, right: 8 })
    }
    .margin({
      top: 8,
      bottom: 8,
    })
    .borderRadius(8)
    .constraintSize({
      minWidth: 120,
      maxWidth: 200
    })
  }

  /**
   * Convert voice message to text
   * Called from MessageActionPanel
   */
  convertVoiceToText(): void {
    if (!this.message || this.isConverting) {
      return;
    }

    console.log(`[SoundMessageView]  Starting voice to text conversion for message: ${this.message.msgID}`);

    // Set converting state
    this.isConverting = true;
    this.isAsrExpanded = true;
    
    if (this.asrDisplayManager) {
      this.asrDisplayManager.setConverting(this.message.msgID, true);
      this.asrDisplayManager.expand(this.message.msgID);
    }

    // Call API
    const messageActionStore = MessageActionStore.create(this.message);
    messageActionStore.convertVoiceToText('')
      .then(() => {
        console.log(`[SoundMessageView]  Voice to text conversion succeeded`);
        this.isConverting = false;
        
        if (this.asrDisplayManager && this.message?.msgID) {
          this.asrDisplayManager.setConverting(this.message.msgID, false);
        }

        // Check if asrText is empty after conversion
        const asrText = this.messageBody?.asrText ?? '';
        if (asrText.length === 0) {
          console.log(`[SoundMessageView]  asrText is empty after conversion`);
          Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
          this.isAsrExpanded = false;
          if (this.asrDisplayManager && this.message?.msgID) {
            this.asrDisplayManager.collapse(this.message.msgID);
          }
        }
      })
      .catch((error: ErrorInfo) => {
        console.error(`[SoundMessageView] ❌ Voice to text conversion failed:`, error);
        this.isConverting = false;
        this.isAsrExpanded = false;
        
        if (this.asrDisplayManager && this.message?.msgID) {
          this.asrDisplayManager.setConverting(this.message.msgID, false);
          this.asrDisplayManager.collapse(this.message.msgID);
        }

        Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
      });
  }

  private async togglePlay() {
    try {
      if (this.isPlaying) {
        await this.audioPlayer.pause();
      } else {
        const soundPath = this.messageBody?.soundPath;
        if (!soundPath) {
          console.warn('[SoundMessageView] No sound path available');
          return;
        }

        if (this.audioPlayer.getCurrentPosition() > 0 && this.audioPlayer.isPaused()) {
          await this.audioPlayer.resume();
        } else {
          await this.audioPlayer.play(soundPath);
        }
      }
    } catch (error) {
      console.error('[SoundMessageView] Toggle play error:', error);
      this.isPlaying = false;
      this.progress = 0;
      this.currentPosition = 0;
    }
  }

  /**
   * Check if status icons (read receipt or sending status) should be shown
   */
  private shouldShowStatusIcons(): boolean {
    const hasReadReceipt = this.message && MessageUtils.shouldShowReadReceipt(this.message,
      this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
      this.isInMergedDetailView);
    const hasSendingStatus = this.message?.status === MessageStatus.sending;
    return !!(hasReadReceipt || hasSendingStatus);
  }

  private formatDuration(milliseconds: number): string {
    const seconds = Math.floor(milliseconds);
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  private getMessageStatusIcon(): Resource {
    if (this.message?.status === MessageStatus.sendSuccess) {
      return $rawfile('messagelist/msg_status_send_succ.svg');
    } else {
      return $rawfile('messagelist/icon_message_send_error.svg');
    }
  }
}

@Builder
export function SoundMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    SoundMessageViewContent({
      message: context.message,
      messageBody: context.message.messageBody,
      messageListStore: context.messageListStore,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false,
      asrDisplayManager: context.asrDisplayManager,
      onAsrBubbleLongPress: context.onAsrBubbleLongPress
    })
  }
}
