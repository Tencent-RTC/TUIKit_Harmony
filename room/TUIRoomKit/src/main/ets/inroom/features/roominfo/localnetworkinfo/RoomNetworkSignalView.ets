import { DeviceState, DeviceStore, NetworkQuality } from '@tencentcloud/atomicxcore'
import { RoomPopup, RoomPopupContentHeight } from '../../../../base/popup/RoomPopup'
import { RoomNetworkInfoPopup } from './RoomNetworkInfoPopup'

@Component
export struct RoomNetworkSignalView {
  @State private deviceState: DeviceState = DeviceStore.shared().state
  @State private isPopupPresented: boolean = false

  private level(): number {
    switch (this.deviceState.networkInfo.quality) {
      case NetworkQuality.excellent:
      case NetworkQuality.good:
        return 3
      case NetworkQuality.poor:
        return 2
      case NetworkQuality.bad:
      case NetworkQuality.veryBad:
        return 1
      default:
        return 0
    }
  }

  private barColor(): ResourceColor {
    const level = this.level()
    if (level >= 3) {
      return $r('app.color.roomkit_success')
    }
    return level === 2 ? $r('app.color.roomkit_warning') : $r('app.color.roomkit_danger')
  }

  private openDetail(): void {
    if (this.isPopupPresented) {
      return
    }
    this.isPopupPresented = true
  }

  private closeDetail(): void {
    this.isPopupPresented = false
  }

  @Builder
  detailPopup() {
    RoomPopup({
      isPresented: this.isPopupPresented,
      contentHeight: RoomPopupContentHeight.AUTO,
      onDismiss: () => this.closeDetail(),
    }) {
      RoomNetworkInfoPopup()
    }
  }

  build() {
    Stack() {
      Row({ space: 2 }) {
        ForEach([4, 8, 12], (height: number, index: number) => {
          Column()
            .width(3)
            .height(height)
            .borderRadius(1)
            .backgroundColor(this.barColor())
            .opacity(index < this.level() ? 1 : (this.level() === 0 ? 0.18 : 0.28))
        })
      }
      .alignItems(VerticalAlign.Bottom)
      .justifyContent(FlexAlign.Center)
      .width(24)
      .height(24)
      .padding({ top: 6, bottom: 6 })
      .borderRadius(8)
      .backgroundColor(this.level() <= 1 ? $r('app.color.roomkit_danger_faint') : Color.Transparent)
      .onClick(() => this.openDetail())
      this.detailPopup()
    }
  }
}
