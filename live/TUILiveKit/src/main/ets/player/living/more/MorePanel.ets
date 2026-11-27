import { LiveKitResources } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { white } from '../../../common/theme/LiveTheme'

@Component
export struct MorePanel {
  @Prop isPresented: boolean = false
  onDismiss?: () => void
  onStart?: () => void

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: 160,
      onDismiss: () => this.onDismiss?.(),
    }) {
      Column({ space: 8 }) {
        Stack({ alignContent: Alignment.Center }) {
          Image(LiveKitResources.image('livekit_float_window'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
            .opacity(0.9)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor(white(0.08))
        Text(LiveKitResources.localizedString('tuilivekit.player.floating_play'))
          .fontSize(11)
          .fontColor(white(0.75))
          .lineHeight(14)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(64)
      .padding(4)
      .margin({ top: 40, left: 16 })
      .alignItems(HorizontalAlign.Center)
      .accessibilityText(LiveKitResources.localizedString('tuilivekit.player.floating_play'))
      .onClick(() => this.onStart?.())
    }
  }
}
