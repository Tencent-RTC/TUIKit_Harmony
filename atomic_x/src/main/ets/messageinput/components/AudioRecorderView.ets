import { ThemeState } from '../../basecomponent/Index';

export type VoiceRecordReleaseAction = 'send' | 'cancel' | 'transcribe';

interface VoiceTouchPoint {
  x: number;
  y: number;
}

@Component
export struct AudioRecorderView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  @Prop recordingDuration: number = 0;
  @Link shouldCancelRecording: boolean;
  @Link shouldTranscribeRecording: boolean;
  @Prop primaryColor: string = '#4A90E2';
  @Prop fullScreen: boolean = false;
  @Prop allowReleaseToSendVoice: boolean = true;
  
  onTimeLimitReached?: () => void;
  onActionTargetAreaChange?: (action: VoiceRecordReleaseAction, x: number, y: number, width: number, height: number) => void;
  onPointerUpdate?: (x: number, y: number) => void;
  onPointerEnd?: (x: number, y: number, forceCancel?: boolean) => void;

  // Animation state for waveform
  @State private animationValues: number[] = Array(24).fill(0);
  private animationTimer?: number;
  private recordingCheckTimer?: number;
  private readonly maxRecordingDuration: number = 60;
  private readonly wavePhases: number[] = (() => {
    const rng = (seed: number) => {
      let s = seed;
      return () => { s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; return (s >>> 0) / 0xFFFFFFFF; };
    };
    const rand = rng(20260421);
    return Array(24).fill(0).map(() => rand() * Math.PI * 2);
  })();
  private readonly waveFreqs: number[] = (() => {
    const rng = (seed: number) => {
      let s = seed ^ 0xDEADBEEF;
      return () => { s = (s * 1664525 + 1013904223) & 0xFFFFFFFF; return (s >>> 0) / 0xFFFFFFFF; };
    };
    const rand = rng(20260421);
    return Array(24).fill(0).map(() => 2.4 + rand() * 3.2);
  })();
  private waveStartTimeMs: number = 0;
  @State private currentPowerLevel: number = 0;

  aboutToAppear() {
    this.waveStartTimeMs = Date.now();
    this.startWaveformAnimation();
    this.startRecordingTimeCheck();
  }

  aboutToDisappear() {
    this.stopWaveformAnimation();
    this.stopRecordingTimeCheck();
  }

  // Android 参考实现：录音面板背景是透明的白色渐变
  //   stop 0    -> 完全透明
  //   stop 0.42 -> 半透明白
  //   stop 0.67 -> 较白
  //   stop 1    -> 不透明白
  private overlayGradientColors(): Array<[ResourceColor, number]> {
    return [
      ['#00000000', 0.0],
      [this.themeState.colors.bgColorMaskDisappeared, 0.42],
      [this.themeState.colors.bgColorOperate, 0.67],
      [this.themeState.colors.bgColorOperate, 1.0]
    ];
  }

  build() {
    Column({ space: 32 }) {
      Row() {
        Blank()
        Text(this.releaseHintText())
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .fontColor(this.releaseHintColor())
          .textAlign(TextAlign.Center)
          .lineHeight(20)
        Blank()
      }
      .padding({ left: 20, right: 20, top: 10 })

      Row() {
        this.ActionTargetBuilder($r('app.string.cancel'), 'cancel')
        this.ActionTargetBuilder($r('app.string.voice_transcription_action'), 'transcribe')
      }
      .width('100%')
      .padding({ left: 72, right: 72 })
      .height(80)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row() {
        Row({ space: 3 }) {
          this.WaveBarBuilder(0)
          this.WaveBarBuilder(1)
          this.WaveBarBuilder(2)
          this.WaveBarBuilder(3)
          this.WaveBarBuilder(4)
          this.WaveBarBuilder(5)
          this.WaveBarBuilder(6)
          this.WaveBarBuilder(7)
          this.WaveBarBuilder(8)
          this.WaveBarBuilder(9)
          this.WaveBarBuilder(10)
          this.WaveBarBuilder(11)
          this.WaveBarBuilder(12)
          this.WaveBarBuilder(13)
          this.WaveBarBuilder(14)
          this.WaveBarBuilder(15)
          this.WaveBarBuilder(16)
          this.WaveBarBuilder(17)
          this.WaveBarBuilder(18)
          this.WaveBarBuilder(19)
          this.WaveBarBuilder(20)
          this.WaveBarBuilder(21)
          this.WaveBarBuilder(22)
          this.WaveBarBuilder(23)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Text(this.formatDuration(this.recordingDuration))
          .fontSize(12)
          .fontColor(this.themeState.colors.textColorButton)
      }
      .height(40)
      .width('92%')
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.recordingBarColor())
      .borderRadius(12)
      .margin({ bottom: 8 })
    }
    .width('100%')
    .height(this.fullScreen ? '100%' : 397)
    .align(Alignment.Bottom)
    .offset({ x: 0, y: 0 })
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .linearGradient({
      angle: 180,
      colors: this.overlayGradientColors()
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down || event.type === TouchType.Move) {
        const point = this.getWindowTouchPoint(event);
        if (point) {
          this.onPointerUpdate?.(point.x, point.y);
        }
      } else if (event.type === TouchType.Up) {
        const point = this.getWindowTouchPoint(event, true);
        if (point) {
          this.onPointerEnd?.(point.x, point.y);
        }
      } else if (event.type === TouchType.Cancel) {
        this.onPointerEnd?.(0, 0, true);
      }
    })
  }

  @Builder
  private WaveBarBuilder(index: number) {
    Rect()
      .width(2.5)
      .height(`${this.animationValues[index]}vp`)
      .fill(Color.White)
      .borderRadius(1.25)
  }

  @Builder
  private ActionTargetBuilder(label: Resource, action: VoiceRecordReleaseAction) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isActionTargetSelected(action)
          ? this.themeState.colors.textColorButton
          : this.themeState.colors.textColorPrimary)
        .textAlign(TextAlign.Center)
    }
    .width(80)
    .height(80)
    .borderRadius(40)
    .backgroundColor(this.isActionTargetSelected(action)
      ? (action === 'cancel' ? this.themeState.colors.buttonColorHangupDefault : this.themeState.colors.buttonColorPrimaryDefault)
      : this.themeState.colors.buttonColorSecondaryDefault)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.updateActionTargetArea(action, newValue);
    })
  }

  private updateActionTargetArea(action: VoiceRecordReleaseAction, area: Area): void {
    this.onActionTargetAreaChange?.(
      action,
      Number(area.globalPosition.x),
      Number(area.globalPosition.y),
      Number(area.width),
      Number(area.height)
    );
  }

  private isActionTargetSelected(action: VoiceRecordReleaseAction): boolean {
    if (action === 'cancel') {
      return this.shouldCancelRecording;
    }
    if (action === 'transcribe') {
      return this.shouldTranscribeRecording;
    }
    return false;
  }

  // Format duration from seconds to MM:SS
  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  private startWaveformAnimation(): void {
    this.animationValues = Array(24).fill(0);
    this.animationTimer = setInterval(() => {
      this.updateWaveformAnimation();
    }, 50);
  }

  private updateWaveformAnimation(): void {
    const t = (Date.now() - this.waveStartTimeMs) / 1000.0;
    const amplitude = 13 * (0.45 + (this.currentPowerLevel / 100) * 0.55);
    const minH = 3;
    const newValues: number[] = [];
    for (let i = 0; i < 24; i++) {
      const wave = Math.abs(Math.sin(t * this.waveFreqs[i] + this.wavePhases[i]));
      newValues.push(minH + amplitude * wave);
    }
    this.animationValues = newValues;
  }

  // Stop waveform animation
  private stopWaveformAnimation(): void {
    if (this.animationTimer) {
      clearInterval(this.animationTimer);
      this.animationTimer = undefined;
    }
  }

  // Start recording time check
  private startRecordingTimeCheck(): void {
    this.stopRecordingTimeCheck();
    this.recordingCheckTimer = setInterval(() => {
      if (this.recordingDuration >= this.maxRecordingDuration) {
        if (this.onTimeLimitReached) {
          this.onTimeLimitReached();
        }
        this.stopRecordingTimeCheck();
      }
    }, 500);
  }

  private stopRecordingTimeCheck(): void {
    if (this.recordingCheckTimer) {
      clearInterval(this.recordingCheckTimer);
      this.recordingCheckTimer = undefined;
    }
  }

  private getWindowTouchPoint(event: TouchEvent, useChangedTouch: boolean = false): VoiceTouchPoint | undefined {
    const touches = useChangedTouch ? event.changedTouches : event.touches;
    const touch = touches?.[0];
    if (!touch) {
      return undefined;
    }
    return {
      x: Number(touch.windowX),
      y: Number(touch.windowY)
    };
  }

  private releaseHintText(): Resource {
    if (this.shouldCancelRecording) {
      return $r('app.string.voice_release_to_cancel_short');
    }
    if (this.shouldTranscribeRecording) {
      return $r('app.string.voice_release_to_transcribe');
    }
    if (!this.allowReleaseToSendVoice) {
      return $r('app.string.message_input_slide_to_transcribe_hint');
    }
    return $r('app.string.voice_release_to_end');
  }

  private releaseHintColor(): ResourceColor {
    return this.themeState.colors.textColorSecondary;
  }

  private recordingBarColor(): ResourceColor {
    if (this.shouldCancelRecording) {
      return this.themeState.colors.buttonColorHangupDefault;
    }
    return this.themeState.colors.buttonColorPrimaryDefault;
  }

}