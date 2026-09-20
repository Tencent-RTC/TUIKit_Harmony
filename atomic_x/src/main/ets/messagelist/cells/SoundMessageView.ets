import { MessageInfo, AudioMessagePayload, MessageListStore } from '@tencentcloud/atomicxcore';
import { MessageActionStore } from '@tencentcloud/atomicxcore';
import { ThemeState, Toast } from '../../basecomponent/Index';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { AudioPlayer, AudioPlayerListener } from '../../audioplayer/Index';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { MessageRenderContext } from '../context/MessageRenderContext';
import { display } from '@kit.ArkUI';

const VOICE_MAX_DURATION_SECONDS: number = 60;
const VOICE_ABSOLUTE_MIN_WIDTH: number = 80;
const VOICE_ABSOLUTE_MAX_WIDTH: number = 260;
const VOICE_MIN_WIDTH_SCREEN_RATIO: number = 0.22;
const VOICE_MAX_WIDTH_SCREEN_RATIO: number = 0.55;
let cachedScreenWidthVp: number = 0;

function getScreenWidthVp(): number {
  if (cachedScreenWidthVp > 0) {
    return cachedScreenWidthVp;
  }
  let widthVp = 360;
  try {
    widthVp = px2vp(display.getDefaultDisplaySync().width);
  } catch (error) {
  }
  cachedScreenWidthVp = widthVp;
  return widthVp;
}

class SoundMessageAudioListener implements AudioPlayerListener {
  private component: SoundMessageViewContent;

  constructor(component: SoundMessageViewContent) {
    this.component = component;
  }

  onPlay(): void {
    this.component.startVoiceAnimation();
  }

  onPause(): void {
    this.component.stopVoiceAnimation();
  }

  onResume(): void {
    this.component.startVoiceAnimation();
  }

  onProgressUpdate(currentPosition: number, duration: number): void {
    this.component.currentPosition = currentPosition;
    this.component.progress = duration > 0 ? (currentPosition / duration) * 100 : 0;
  }

  onCompletion(): void {
    this.component.stopVoiceAnimation();
    this.component.progress = 0;
    this.component.currentPosition = 0;
  }

  onError(errorMessage: string): void {
    console.error('[SoundMessageView] Audio player error:', errorMessage);
    this.component.stopVoiceAnimation();
    this.component.progress = 0;
    this.component.currentPosition = 0;
  }
}

@Component
export struct SoundMessageViewContent {
  @ObjectLink message: MessageInfo;
  @ObjectLink messagePayload: AudioMessagePayload;
  @State isPlaying: boolean = false;
  @State animationStep: number = -1;
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
  private voiceAnimationTimer?: number;

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
    this.stopVoiceAnimation();
    this.audioPlayer.stop();

    if (this.asrDisplayManager && this.stateChangeListener) {
      this.asrDisplayManager.removeListener(this.stateChangeListener);
    }
  }

  build() {
    Row({ space: 8 }) {
      if (!this.message.isSentBySelf) {
        this.VoiceIcon()
      }

      Text(this.formatDuration(this.messagePayload?.audioDuration || 0))
        .fontSize(14)
        .fontColor(this.message.isSentBySelf ? this.themeState.colors.textColorAntiPrimary :
        this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Normal)
        .maxLines(1)

      if (this.message.isSentBySelf) {
        this.VoiceIcon()
      }
    }
    .width(this.getBubbleWidth())
    .height(44)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(this.message.isSentBySelf ? FlexAlign.End : FlexAlign.Start)
    .onClick(() => {
      this.togglePlay();
    })
  }

  @Builder
  VoiceIcon() {
    Stack() {
      Image($rawfile('messagelist/voice_icon_dot.svg'))
        .width(16)
        .height(16)
        .opacity(this.getLayerOpacity(0))
        .fillColor(this.getContentColor())
      Image($rawfile('messagelist/voice_icon_arc_inner.svg'))
        .width(16)
        .height(16)
        .opacity(this.getLayerOpacity(1))
        .fillColor(this.getContentColor())
      Image($rawfile('messagelist/voice_icon_arc_outer.svg'))
        .width(16)
        .height(16)
        .opacity(this.getLayerOpacity(2))
        .fillColor(this.getContentColor())
    }
    .width(16)
    .height(16)
    .scale({ x: this.message.isSentBySelf ? -1 : 1, y: 1 })
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
      this.stopVoiceAnimation();
      this.progress = 0;
      this.currentPosition = 0;
    }
  }

  private getBubbleWidth(): number {
    const screenWidth = getScreenWidthVp();
    const minWidth = Math.min(Math.max(screenWidth * VOICE_MIN_WIDTH_SCREEN_RATIO, VOICE_ABSOLUTE_MIN_WIDTH),
      VOICE_ABSOLUTE_MAX_WIDTH);
    const maxWidth = Math.min(Math.max(screenWidth * VOICE_MAX_WIDTH_SCREEN_RATIO, minWidth),
      VOICE_ABSOLUTE_MAX_WIDTH);
    const duration = Math.max(0, Math.floor(this.messagePayload?.audioDuration ?? 0));
    const clampedDuration = Math.min(Math.max(duration, 1), VOICE_MAX_DURATION_SECONDS);
    return minWidth + (maxWidth - minWidth) * (clampedDuration / VOICE_MAX_DURATION_SECONDS);
  }

  startVoiceAnimation(): void {
    this.stopVoiceAnimation();
    this.isPlaying = true;
    this.animationStep = 0;
    this.voiceAnimationTimer = setInterval(() => {
      this.animationStep = (this.animationStep + 1) % 3;
    }, 300);
  }

  stopVoiceAnimation(): void {
    if (this.voiceAnimationTimer !== undefined) {
      clearInterval(this.voiceAnimationTimer);
      this.voiceAnimationTimer = undefined;
    }
    this.isPlaying = false;
    this.animationStep = -1;
  }

  private getLayerOpacity(layer: number): number {
    if (!this.isPlaying || this.animationStep < 0) {
      return 1;
    }
    return layer === this.animationStep ? 1 : 0.3;
  }

  private getContentColor(): string {
    return this.message.isSentBySelf
      ? this.themeState.colors.textColorAntiPrimary
      : this.themeState.colors.textColorPrimary;
  }

  private formatDuration(seconds: number): string {
    const safeSeconds = Math.max(0, Math.floor(seconds));
    return `${safeSeconds}"`;
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