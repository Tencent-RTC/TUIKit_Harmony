import { ThemeState } from '../../basecomponent/Index';

@Component
export struct VoiceTranscriptionDraftView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  @Prop audioDuration: number = 0;
  @Prop allowSendOriginalVoice: boolean = true;
  @Link text: string;
  @Link isLoading: boolean;

  onCancel?: () => void;
  onSendAudio?: () => void;
  onSendText?: (text: string) => void;

  @State private draftText: string = '';
  @State private userEdited: boolean = false;
  private controller: TextAreaController = new TextAreaController();

  aboutToAppear(): void {
    this.draftText = this.text;
    this.userEdited = false;
  }

  aboutToDisappear(): void {
    this.draftText = '';
    this.userEdited = false;
  }

  private overlayGradientColors(): Array<[ResourceColor, number]> {
    return [
      ['#00000000', 0.0],
      [this.themeState.colors.bgColorMaskDisappeared, 0.42],
      [this.themeState.colors.bgColorOperate, 0.67],
      [this.themeState.colors.bgColorOperate, 1.0]
    ];
  }

  build() {
    Column({ space: 14 }) {
      this.BubbleBuilder()
      Row() {
        Column({ space: 8 }) {
          Row() {
            Image($rawfile('messageinput/close_icon.svg'))
              .width(24)
              .height(24)
          }
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor(this.themeState.colors.buttonColorSecondaryDefault)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.onCancel?.();
          })

          Text($r('app.string.cancel'))
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorSecondary)
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)

        if (this.allowSendOriginalVoice) {
          Column({ space: 8 }) {
            Row() {
              Image($rawfile('messageinput/voice_transcription_audio.svg'))
                .width(24)
                .height(24)
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .backgroundColor(this.themeState.colors.buttonColorSecondaryDefault)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.onSendAudio?.();
            })

            Text($r('app.string.voice_transcription_send_original_voice'))
              .fontSize(12)
              .fontColor(this.themeState.colors.textColorSecondary)
              .textAlign(TextAlign.Center)
          }
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 46 })
        }

        Text($r('app.string.send_button'))
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorButton)
          .textAlign(TextAlign.Center)
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor(
            (!this.isLoading && ((this.userEdited ? this.draftText : this.text) || '').trim().length > 0)
              ? this.themeState.colors.buttonColorPrimaryDefault
              : this.themeState.colors.buttonColorPrimaryDisabled
          )
          .onClick(() => {
            const effective = (this.userEdited ? this.draftText : this.text) || '';
            if (!this.isLoading && effective.trim().length > 0) {
              this.onSendText?.(effective.trim());
            }
          })
          .margin({ left: 57 })
      }
      .width('100%')
      .padding({ left: 28, right: 28 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Row({ space: 10 }) {
        Row({ space: 4 }) {
          this.WaveDotBuilder(0.35)
          this.WaveDotBuilder(0.53)
          this.WaveDotBuilder(0.71)
          this.WaveDotBuilder(0.35)
          this.WaveDotBuilder(0.53)
          this.WaveDotBuilder(0.71)
          this.WaveDotBuilder(0.35)
          this.WaveDotBuilder(0.53)
          this.WaveDotBuilder(0.71)
          this.WaveDotBuilder(0.35)
          this.WaveDotBuilder(0.53)
          this.WaveDotBuilder(0.71)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        Text(this.formatDuration(this.audioDuration))
          .fontSize(12)
          .fontColor(this.themeState.colors.textColorSecondary)
      }
      .width('92%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 16, bottom: 16 })
    .justifyContent(FlexAlign.End)
    .linearGradient({
      angle: 180,
      colors: this.overlayGradientColors()
    })
  }

  @Builder
  private WaveDotBuilder(opacity: number) {
    Circle()
      .width(3)
      .height(3)
      .fill(this.themeState.colors.textColorPrimary)
      .opacity(opacity)
  }

  @Builder
  private BubbleBuilder() {
    if (this.isLoading) {
      Column() {
        Stack() {
          Row({ space: 8 }) {
            Circle().width(6).height(6).fill(this.themeState.colors.textColorButton).opacity(0.45)
            Circle().width(6).height(6).fill(this.themeState.colors.textColorButton).opacity(0.7)
            Circle().width(6).height(6).fill(this.themeState.colors.textColorButton).opacity(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .height(50)
        .backgroundColor(this.bubbleBackgroundColor())
        .borderRadius(8)

        Row() {
          Blank()
          Polygon()
            .points([[0, 0], [24, 0], [12, 14]])
            .fill(this.bubbleBackgroundColor())
            .width(24)
            .height(14)
        }
        .width('100%')
        .padding({ right: 40 })
      }
      .width('84%')
    } else {
      Column() {
        Stack() {
          TextArea({
            text: this.userEdited ? this.draftText : this.text,
            placeholder: $r('app.string.voice_transcription_empty'),
            controller: this.controller
          })
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorButton)
            .placeholderColor(this.themeState.colors.textColorButton)
            .backgroundColor(Color.Transparent)
            .width('100%')
            .maxLines(4)
            .onChange((value: string) => {
              this.draftText = value;
              this.userEdited = true;
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .constraintSize({ minHeight: 44, maxHeight: 148 })
        .backgroundColor(this.bubbleBackgroundColor())
        .borderRadius(8)

        Row() {
          Blank()
          Polygon()
            .points([[0, 0], [24, 0], [12, 14]])
            .fill(this.bubbleBackgroundColor())
            .width(24)
            .height(14)
        }
        .width('100%')
        .padding({ right: 40 })
      }
      .width('84%')
    }
  }

  private bubbleBackgroundColor(): ResourceColor {
    if (!this.isLoading && ((this.userEdited ? this.draftText : this.text) || '').trim().length === 0) {
      return this.themeState.colors.buttonColorHangupDefault;
    }
    return this.themeState.colors.buttonColorPrimaryDefault;
  }

  private formatDuration(seconds: number): string {
    const safeSeconds = Math.max(0, Math.floor(seconds));
    const minutes = Math.floor(safeSeconds / 60);
    const remainingSeconds = safeSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
}
