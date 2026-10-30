import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { BottomSheetView } from '../../common/theme/BottomSheetView'
import { LiveTheme, white } from '../../common/theme/LiveTheme'

@Component
export struct PusherCoverPickerView {
  @Prop isPresented: boolean = false
  @Prop selectedURL: string = LiveKitResources.defaultCoverURL
  onDismiss?: () => void
  onSelect?: (coverURL: string) => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private loadedURLs: string[] = []

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: 190,
      sheetTitle: LiveKitResources.localizedString('tuilivekit.pusher.prepare.change_cover'),
      onDismiss: () => this.onDismiss?.(),
    }) {
      Row({ space: 8 }) {
        ForEach(LiveKitResources.presetCoverURLs, (url: string, index: number) => {
          Image(url)
            .objectFit(ImageFit.Cover)
            .layoutWeight(1)
            .aspectRatio(1)
            .constraintSize({
              maxWidth: Math.max(0, 190 - 68 - this.safeBottom - 12),
              maxHeight: Math.max(0, 190 - 68 - this.safeBottom - 12)
            })
            .borderRadius(12)
            .borderWidth(2)
            .borderColor(url === this.selectedURL ? LiveTheme.Color.brandBlue : white(0.14))
            .backgroundColor(white(0.06))
            .clip(true)
            .opacity(this.loadedURLs.includes(url) ? 1 : 0.55)
            .enabled(this.loadedURLs.includes(url))
            .accessibilityText(LiveKitResources.localizedFormat('tuilivekit.pusher.prepare.cover_option', index + 1))
            .onComplete(() => {
              if (!this.loadedURLs.includes(url)) {
                this.loadedURLs = this.loadedURLs.concat([url])
              }
            })
            .onClick(() => {
              this.onSelect?.(url)
              this.onDismiss?.()
            })
        }, (url: string) => url)
      }
      .padding({ left: 20, right: 20 })
      .margin({ top: 68 })
    }
  }
}
