import { ThemeState } from '../../basecomponent/Index';

@Component
export struct VoiceTranscriptionDraftView {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  @Prop audioDuration: number = 0;
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

  build() {
    Column({ space: 14 }) {
      this.BubbleBuilder()
      Row() {
        this.ActionButtonBuilder($r('app.string.cancel'), this.themeState.colors.buttonColorSecondaryDefault, this.themeState.colors.textColorPrimary, 56, 48, () => {
          this.onCancel?.();
        })
        Blank()
        this.ActionButtonBuilder($r('app.string.voice_transcription_send_original_voice'), this.themeState.colors.buttonColorSecondaryDefault, this.themeState.colors.textColorPrimary, 56, 48, () => {
          this.onSendAudio?.();
        })
        Blank()
        Text($r('app.string.send_button'))
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorButton)
          .textAlign(TextAlign.Center)
          .width(80)
          .height(56)
          .borderRadius(28)
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
      }
      .width('100%')
      .padding({ left: 28, right: 28 })
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
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
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
    Stack() {
      if (this.isLoading) {
        Row({ space: 8 }) {
          Circle().width(6).height(6).fill(this.themeState.colors.textColorButton).opacity(0.45)
          Circle().width(6).height(6).fill(this.themeState.colors.textColorButton).opacity(0.7)
          Circle().width(6).height(6).fill(this.themeState.colors.textColorButton).opacity(1)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 18 })
      } else if (((this.userEdited ? this.draftText : this.text) || '').trim().length === 0) {
        Text($r('app.string.voice_transcription_empty'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorButton)
          .width('100%')
          .height('100%')
          .padding({ left: 16, right: 16 })
          .textAlign(TextAlign.Start)
      } else {
        TextArea({ text: this.userEdited ? this.draftText : this.text, controller: this.controller })
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorButton)
          .backgroundColor(Color.Transparent)
          .width('100%')
          .height('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .maxLines(4)
          .onChange((value: string) => {
            this.draftText = value;
            this.userEdited = true;
          })
      }
    }
    .width('84%')
    .height(!this.isLoading && ((this.userEdited ? this.draftText : this.text) || '').trim().length > 0 && (this.userEdited ? this.draftText : this.text).length > 24 ? 104 : 68)
    .backgroundColor(!this.isLoading && ((this.userEdited ? this.draftText : this.text) || '').trim().length === 0 ? this.themeState.colors.buttonColorHangupDefault : this.themeState.colors.buttonColorPrimaryDefault)
    .borderRadius(8)
  }

  @Builder
  private ActionButtonBuilder(text: Resource, backgroundColor: ResourceColor, fontColor: ResourceColor, width: number, height: number, action: () => void) {
    Text(text)
      .fontSize(14)
      .fontColor(fontColor)
      .textAlign(TextAlign.Center)
      .width(width)
      .height(height)
      .borderRadius(height / 2)
      .backgroundColor(backgroundColor)
      .onClick(action)
  }

  private formatDuration(seconds: number): string {
    const safeSeconds = Math.max(0, Math.floor(seconds));
    const minutes = Math.floor(safeSeconds / 60);
    const remainingSeconds = safeSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
}
