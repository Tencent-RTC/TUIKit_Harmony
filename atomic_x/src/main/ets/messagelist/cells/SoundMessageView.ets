import { MessageInfo, AudioMessagePayload, MessageListStore } from '@tencentcloud/atomicxcore';
import { MessageActionStore } from '@tencentcloud/atomicxcore';
import { ThemeState, Toast } from '../../basecomponent/Index';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { AudioPlayer, AudioPlayerListener } from '../../audioplayer/Index';
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
  @ObjectLink message: MessageInfo;
  @ObjectLink messagePayload: AudioMessagePayload;
  @State isPlaying: boolean = false;
  @State progress: number = 0;
  @State currentPosition: number = 0;
  @ObjectLink messageListStore: MessageListStore;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State isConverting: boolean = false;
  @State isAsrExpanded: boolean = false;
  asrDisplayManager?: AsrDisplayManager = undefined;
  onAsrBubbleLongPress?: (message: MessageInfo) => void;
  private audioPlayer: AudioPlayer = AudioPlayer.create();
  private stateChangeListener?: () => void;

  aboutToAppear() {
    const listener = new SoundMessageAudioListener(this);
    this.audioPlayer.setListener(listener);

    if (this.asrDisplayManager && this.message.msgID) {
      this.isAsrExpanded = this.asrDisplayManager.isExpanded(this.message.msgID);
      this.isConverting = this.asrDisplayManager.isConverting(this.message.msgID);

      this.stateChangeListener = () => {
        if (this.message.msgID) {
          this.isAsrExpanded = this.asrDisplayManager!.isExpanded(this.message.msgID);
          this.isConverting = this.asrDisplayManager!.isConverting(this.message.msgID);
        }
      };
      this.asrDisplayManager.addListener(this.stateChangeListener);
    }
  }

  aboutToDisappear() {
    this.audioPlayer.stop();

    if (this.asrDisplayManager && this.stateChangeListener) {
      this.asrDisplayManager.removeListener(this.stateChangeListener);
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Row() {
        Image(this.isPlaying ? $rawfile('messagelist/voice_pause.png') : $rawfile('messagelist/voice_play.svg'))
          .width(12)
          .height(12)
          .fillColor(this.message.isSentBySelf ? this.themeState.colors.textColorAntiSecondary :
          this.themeState.colors.textColorPrimary)
          .margin({ left: 16 })
          .draggable(false)

        Row() {
          ForEach([0, 1, 2], (item: number) => {
            Image($rawfile('messagelist/voice_play_animation.svg'))
              .width(21)
              .height(21)
              .margin({ left: 4 })
              .fillColor(this.message.isSentBySelf ? this.themeState.colors.textColorAntiSecondary :
              this.themeState.colors.textColorPrimary)
              .opacity(this.progress > (item * 33.33) ? 1 : 0.3)
              .draggable(false)
          })
        }
        .margin({ left: 8, bottom: 4 })

        Text(this.formatDuration(this.messagePayload?.audioDuration || 0))
          .fontSize(12)
          .fontColor(this.message.isSentBySelf ? this.themeState.colors.textColorAntiSecondary :
          this.themeState.colors.textColorPrimary)
          .margin({
            left: 8,
            right: 16
          })
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .onClick(() => {
        this.togglePlay();
      })
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

  convertVoiceToText(): void {
    if (this.isConverting) {
      return;
    }

    this.isConverting = true;
    this.isAsrExpanded = true;

    if (this.asrDisplayManager) {
      this.asrDisplayManager.setConverting(this.message.msgID, true);
      this.asrDisplayManager.expand(this.message.msgID);
    }

    const messageActionStore = MessageActionStore.create(this.message);
    messageActionStore.convertVoiceToText('', new CompletionHandlerAdapter(() => {
      this.isConverting = false;

      if (this.asrDisplayManager && this.message.msgID) {
        this.asrDisplayManager.setConverting(this.message.msgID, false);
      }

      const asrText = this.messagePayload?.asrText ?? '';
      if (asrText.length === 0) {
        Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
        this.isAsrExpanded = false;
        if (this.asrDisplayManager && this.message.msgID) {
          this.asrDisplayManager.collapse(this.message.msgID);
        }
      }
    }, (code: number, desc: string) => {
      console.error('[SoundMessageView] convertVoiceToText failed:', code, desc);
      this.isConverting = false;
      this.isAsrExpanded = false;

      if (this.asrDisplayManager && this.message.msgID) {
        this.asrDisplayManager.setConverting(this.message.msgID, false);
        this.asrDisplayManager.collapse(this.message.msgID);
      }

      Toast.info($r('app.string.messagelist_convert_to_text_failed'), this.getUIContext());
    }));
  }

  private async togglePlay() {
    try {
      if (this.isPlaying) {
        await this.audioPlayer.pause();
      } else {
        const audioPath = this.messagePayload?.audioPath;
        if (!audioPath) {
          return;
        }

        if (this.audioPlayer.getCurrentPosition() > 0 && this.audioPlayer.isPaused()) {
          await this.audioPlayer.resume();
        } else {
          await this.audioPlayer.play(audioPath);
        }
      }
    } catch (error) {
      console.error('[SoundMessageView] Toggle play error:', error);
      this.isPlaying = false;
      this.progress = 0;
      this.currentPosition = 0;
    }
  }

  private formatDuration(milliseconds: number): string {
    const seconds = Math.floor(milliseconds);
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}

@Builder
export function SoundMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    SoundMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as AudioMessagePayload,
      messageListStore: context.messageListStore,
      asrDisplayManager: context.asrDisplayManager,
      onAsrBubbleLongPress: context.onAsrBubbleLongPress
    })
  }
}