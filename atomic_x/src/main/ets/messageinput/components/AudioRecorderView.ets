import { ThemeState } from '../../basecomponent/Index';

type VoiceRecordReleaseAction = 'send' | 'cancel' | 'transcribe';

@Component
export struct AudioRecorderView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  @Prop recordingDuration: number = 0;
  @Link shouldCancelRecording: boolean;
  @Link shouldTranscribeRecording: boolean;
  @Prop primaryColor: string = '#4A90E2';
  @Prop transcribeHorizontalActionThreshold: number = 72;
  
  onCancel?: () => void;
  onSend?: (action?: VoiceRecordReleaseAction) => void;
  onTimeLimitReached?: () => void;
  onDragUpdate?: (shouldCancel: boolean, shouldTranscribe?: boolean) => void;

  // Touch handling state
  @State private initialTouchX: number = 0;
  @State private initialTouchY: number = 0;
  @State private dragOffsetX: number = 0;
  @State private dragOffset: number = 0;
  @State private currentTouchX: number = 0;
  @State private currentTouchY: number = 0;
  @State private componentWidth: number = 0;
  private readonly cancelThreshold: number = -50;
  private readonly horizontalActionThreshold: number = 72;
  private readonly actionTargetMaxY: number = 150;
  private readonly leftActionMaxRatio: number = 0.42;
  private readonly rightActionMinRatio: number = 0.58;

  // Animation state for waveform
  @State private animationValues: number[] = Array(24).fill(0);
  private animationTimer?: number;
  private recordingCheckTimer?: number;
  private readonly maxRecordingDuration: number = 60; // 60 seconds

  aboutToAppear() {
    this.startWaveformAnimation();
    this.startRecordingTimeCheck();
  }

  aboutToDisappear() {
    this.stopWaveformAnimation();
    this.stopRecordingTimeCheck();
  }

  build() {
    Column({ space: 18 }) {
      Row() {
        Blank()
        Text(this.releaseHintText())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.releaseHintColor())
          .textAlign(TextAlign.Center)
        Blank()
      }
      .padding({ left: 20, right: 20, top: 10 })

      Row() {
        this.ActionTargetBuilder('×', $r('app.string.cancel'), 'cancel', '#FF4D4F')
        Blank()
        this.ActionTargetBuilder($r('app.string.voice_transcription_action'), undefined, 'transcribe',
          this.themeState.colors.buttonColorPrimaryDefault)
      }
      .width('74%')
      .height(86)
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.formatDuration(Math.floor(this.recordingDuration)))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(70)

        Row({ space: 4 }) {
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
        .constraintSize({ maxHeight: 28 })
      }
      .width('96%')
      .height(52)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.recordingBarColor())
      .borderRadius(10)
      .margin({ left: 5, right: 5, bottom: 8 })
    }
    .width('100%')
    .height(230)
    .backgroundColor(this.themeState.colors.bgColorInput)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.componentWidth = newValue.width as number;
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        console.log('[AudioRecorderView] Touch down');
        this.initialTouchX = event.touches[0].x;
        this.initialTouchY = event.touches[0].y;
        this.currentTouchX = event.touches[0].x;
        this.currentTouchY = event.touches[0].y;
      } else if (event.type === TouchType.Move) {
        console.log('[AudioRecorderView] Touch move');
        this.currentTouchX = event.touches[0].x;
        this.currentTouchY = event.touches[0].y;
        this.dragOffsetX = event.touches[0].x - this.initialTouchX;
        this.dragOffset = event.touches[0].y - this.initialTouchY;
        this.updateActionState();
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        console.log('[AudioRecorderView] Touch up/cancel');
        const action = this.currentReleaseAction();
        if (action === 'cancel') {
          this.onCancel?.();
        } else {
          this.onSend?.(action);
        }
      }
    })
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
        .onActionUpdate((event: GestureEvent) => {
          console.log('[AudioRecorderView] Pan gesture update');
          this.dragOffsetX = event.offsetX;
          this.dragOffset = event.offsetY;
          if (this.initialTouchX > 0 || this.initialTouchY > 0) {
            this.currentTouchX = this.initialTouchX + event.offsetX;
            this.currentTouchY = this.initialTouchY + event.offsetY;
          }
          this.updateActionState();
        })
    )
  }

  @Builder
  private WaveBarBuilder(index: number) {
    Rect()
      .width(3)
      .height(`${8 + this.animationValues[index]}vp`)
      .fill(Color.White)
      .borderRadius(2)
  }

  @Builder
  private ActionTargetBuilder(content: string | Resource, label: Resource | undefined,
    action: VoiceRecordReleaseAction, selectedColor: ResourceColor) {
    Column({ space: 8 }) {
      Row() {
        if (typeof content === 'string') {
          Text(content)
            .fontSize(34)
            .fontColor(this.isActionTargetSelected(action) ? Color.White : this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
        } else {
          Text(content)
            .fontSize(18)
            .fontColor(this.isActionTargetSelected(action) ? Color.White : this.themeState.colors.textColorPrimary)
            .textAlign(TextAlign.Center)
        }
      }
      .width(70)
      .height(70)
      .borderRadius(35)
      .backgroundColor(this.isActionTargetSelected(action) ? selectedColor : this.themeState.colors.bgColorOperate)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      if (label) {
        Text(label)
          .fontSize(13)
          .fontColor(this.isActionTargetSelected(action) ? selectedColor : this.themeState.colors.textColorSecondary)
      }
    }
    .alignItems(HorizontalAlign.Center)
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

  // Start waveform animation
  private startWaveformAnimation(): void {
    this.animationValues = Array(24).fill(0);
    this.animationTimer = setInterval(() => {
      this.updateWaveformAnimation();
    }, 100);
  }

  // Update waveform animation values
  private updateWaveformAnimation(): void {
    // Simulate audio power level (in real implementation, get from AudioRecorder)
    const basePower = Math.random() * 10 + 1; // Random power between 1-11
    
    for (let i = 0; i < this.animationValues.length; i++) {
      const normalizedPower = Math.min(Math.max(basePower * 0.3, 1), 10);
      const randomOffset = (Math.random() - 0.5) * 4; // Random offset between -2 and 2
      this.animationValues[i] = normalizedPower + randomOffset;
    }
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

  private updateActionState(): void {
    const action = this.currentReleaseAction();
    this.shouldCancelRecording = action === 'cancel';
    this.shouldTranscribeRecording = action === 'transcribe';
    this.onDragUpdate?.(this.shouldCancelRecording, this.shouldTranscribeRecording);
  }

  private currentReleaseAction(): VoiceRecordReleaseAction {
    if (this.isTouchInCancelActionTarget()) {
      return 'cancel';
    }
    if (this.isTouchInTranscribeActionTarget()) {
      return 'transcribe';
    }
    if (this.dragOffset < this.cancelThreshold && this.dragOffsetX < -this.horizontalActionThreshold) {
      return 'cancel';
    }
    if (this.dragOffset < this.cancelThreshold && this.dragOffsetX > this.transcribeHorizontalActionThreshold) {
      return 'transcribe';
    }
    return 'send';
  }

  private isTouchInCancelActionTarget(): boolean {
    return this.isTouchInActionTargetY() && this.componentWidth > 0 &&
      this.currentTouchX < this.componentWidth * this.leftActionMaxRatio;
  }

  private isTouchInTranscribeActionTarget(): boolean {
    return this.isTouchInActionTargetY() && this.componentWidth > 0 &&
      this.currentTouchX > this.componentWidth * this.rightActionMinRatio;
  }

  private isTouchInActionTargetY(): boolean {
    return this.currentTouchY > 0 && this.currentTouchY < this.actionTargetMaxY;
  }

  private releaseHintText(): Resource {
    if (this.shouldCancelRecording) {
      return $r('app.string.voice_release_to_cancel_short');
    }
    if (this.shouldTranscribeRecording) {
      return $r('app.string.voice_release_to_transcribe');
    }
    return $r('app.string.voice_release_to_end');
  }

  private releaseHintColor(): ResourceColor {
    if (this.shouldCancelRecording) {
      return '#FF4D4F';
    }
    if (this.shouldTranscribeRecording) {
      return this.themeState.colors.buttonColorPrimaryDefault;
    }
    return this.themeState.colors.textColorSecondary;
  }

  private recordingBarColor(): ResourceColor {
    if (this.shouldCancelRecording) {
      return '#FF4D4F';
    }
    return this.themeState.colors.buttonColorPrimaryDefault;
  }

}