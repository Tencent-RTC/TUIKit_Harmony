import { RoomPopup, RoomPopupContentHeight } from 'tuiroomkit'
import { RoomPageTheme, roomText } from './RoomPageComponents'

@Component
export struct RoomHomeProfilePopup {
  @Prop isPresented: boolean = false
  onDismiss?: () => void
  onSettings?: () => void

  build() {
    RoomPopup({ isPresented: this.isPresented, contentHeight: RoomPopupContentHeight.AUTO,
      onDismiss: () => this.onDismiss?.() }) {
      Row() {
        Button(roomText('app_settings'))
          .width('100%').height(44).fontSize(16).fontColor(RoomPageTheme.primary)
          .backgroundColor(RoomPageTheme.hover).borderRadius(12).margin({ top: 4, bottom: 8 })
          .onClick(() => {
            this.onDismiss?.()
            this.onSettings?.()
          })
      }
      .width('100%').height(76).padding({ left: 16, right: 16, top: 4, bottom: 16 })
    }
  }
}
