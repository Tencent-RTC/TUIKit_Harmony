import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { LiveTextInputView, LimitUnit } from '../../common/theme/LiveTextInputView'
import { LiveTheme, rgba, white } from '../../common/theme/LiveTheme'
import { LiveToast } from '../../common/theme/LiveToastView'

const titleByteLimit: number = 100
const titleInputID: string = 'tuilivekit_prepare_title_input'

@Component
export struct PusherLiveInfoEditorView {
  @Prop @Watch('bind') title: string = ''
  @Prop coverURL: string = LiveKitResources.defaultCoverURL
  onChangeCover?: () => void
  onTitleChanged?: (title: string) => void
  @State private text: string = LiveKitResources.localizedString('tuilivekit.pusher.default_title')
  private isEditing: boolean = false

  aboutToAppear(): void {
    this.bind()
  }

  private bind(): void {
    if (!this.isEditing) {
      this.text = this.title
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.coverURL.length > 0 ? this.coverURL : LiveKitResources.image('livekit_livelist_default_cover'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .alt(LiveKitResources.image('livekit_livelist_default_cover'))
        Text(LiveKitResources.localizedString('tuilivekit.pusher.prepare.change_cover'))
          .attributeModifier(
            new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.primary, TextAlign.Center, true))
          .fontColor($r('app.color.tuilivekit_pusher_prepare_hint'))
          .backgroundColor($r('app.color.tuilivekit_pusher_prepare_caption_background'))
          .width('100%')
          .height(18)
          .maxLines(1)
          .minFontSize(7)
          .maxFontSize(10)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(58)
      .height(58)
      .backgroundColor(rgba(0.13, 0.15, 0.23))
      .borderRadius(14)
      .borderWidth(1)
      .borderColor(white(0.16))
      .clip(true)
      .accessibilityText(LiveKitResources.localizedString('tuilivekit.pusher.prepare.change_cover'))
      .onClick(() => this.onChangeCover?.())

      LiveTextInputView({
        text: $text,
        fontSize: 20,
        fontWeight: 600,
        textAlignment: TextAlign.Center,
        inputLimit: titleByteLimit,
        limitUnit: LimitUnit.utf8Bytes,
        maximumLines: 3,
        minimumHeight: 28,
        inputID: titleInputID,
        onTextChanged: () => this.onTitleChanged?.(this.text),
        onSubmit: () => this.getUIContext().getFocusController().clearFocus(),
        onEditingChanged: (isEditing: boolean) => this.isEditing = isEditing,
        onLimitExceeded: () => LiveToast.show(
          LiveKitResources.localizedFormat('tuilivekit.pusher.prepare.topic_byte_limit',
            titleByteLimit)),
      })
        .padding({ left: 45, right: 45 })
        .margin({ top: 32 })
      Text(LiveKitResources.localizedString('tuilivekit.pusher.prepare.edit_topic'))
        .fontSize(12)
        .fontWeight(600)
        .fontColor($r('app.color.tuilivekit_pusher_prepare_hint'))
        .height(25)
        .margin({ bottom: 10 })
        .onClick(() => this.getUIContext().getFocusController().requestFocus(titleInputID))
    }
    .width('100%')
  }
}
