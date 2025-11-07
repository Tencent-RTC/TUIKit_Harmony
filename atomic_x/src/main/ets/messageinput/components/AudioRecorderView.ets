import { ThemeState } from '../../basecomponent/Index';

@Component
export struct AudioRecorderView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  @Prop recordingDuration: number = 0;
  @Prop shouldCancelRecording: boolean = false;
  @Prop primaryColor: string = '#4A90E2';
  
  onCancel?: () => void;
  onSend?: () => void;
  onTimeLimitReached?: () => void;

  // Animation state for waveform
  @State private animationValues: number[] = Array(30).fill(0);
  private animationTimer?: number;
  private readonly maxRecordingDuration: number = 60; // 60 seconds

  aboutToAppear() {
    this.startWaveformAnimation();
    this.startRecordingTimeCheck();
  }

  aboutToDisappear() {
    this.stopWaveformAnimation();
  }

  build() {
    Column({ space: 16 }) {
      // Top instruction text
      Row() {
        Blank()
        Text(this.shouldCancelRecording ? 
          $r('app.string.voice_release_to_cancel') : 
          $r('app.string.voice_release_to_send_slide_to_cancel'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.shouldCancelRecording ? Color.Red : this.themeState.colors.textColorSecondary)
          .textAlign(TextAlign.Center)
        Blank()
      }
      .padding({ left: 20, right: 20, top: 10 })

      // Recording interface with waveform
      Row() {
        // Duration display
        Text(this.formatDuration(this.recordingDuration))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)

        Blank()

        // Waveform animation
        Row({ space: 3 }) {
          ForEach(this.animationValues, (value: number, index: number) => {
            Rect()
              .width(2)
              .height(`${6 + value}vp`)
              .fill(Color.White)
              .borderRadius(1)
          })
        }
        .alignItems(VerticalAlign.Center)
        .constraintSize({ maxHeight: 20 })

        Blank()
      }
      .width('80%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.shouldCancelRecording ? Color.Red : this.primaryColor)
      .borderRadius(24)
      .shadow({
        radius: 4,
        color: Color.Black,
        offsetX: 0,
        offsetY: 2
      })
      .margin({ left: 5, right: 5, bottom: 0 })
    }
    .width('100%')
    .height(100)
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // Format duration from seconds to MM:SS
  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  // Start waveform animation
  private startWaveformAnimation(): void {
    this.animationValues = Array(30).fill(0);
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
    const checkTimer = setInterval(() => {
      if (this.recordingDuration >= this.maxRecordingDuration) {
        if (this.onTimeLimitReached) {
          this.onTimeLimitReached();
        }
        clearInterval(checkTimer);
      }
    }, 500);
  }

}