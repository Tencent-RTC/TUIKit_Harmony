import { AudioRoute, DeviceState, DeviceStore } from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomSpeakerPopup } from './RoomSpeakerPopup'

@Component
export struct RoomSpeakerButton {
  @State private deviceState: DeviceState = DeviceStore.shared().state
  @State private isRoutePopupPresented: boolean = false
  @State private isPressed: boolean = false

  @Builder
  routePopup() {
    RoomSpeakerPopup({
      isPresented: this.isRoutePopupPresented,
      currentRoute: this.deviceState.currentAudioRoute,
      onSelect: (route: AudioRoute) => {
        DeviceStore.shared().setAudioRoute(route)
        this.isRoutePopupPresented = false
      },
      onDismiss: () => this.isRoutePopupPresented = false,
    })
  }

  build() {
    Stack() {
      Stack() {
        Image(RoomResources.image(this.deviceState.currentAudioRoute === AudioRoute.speakerphone ?
          'roomkit_icon_speaker_primary' : 'roomkit_icon_earpiece_primary'))
          .width(20)
          .height(20)
      }
      .width(44)
      .height(44)
      .backgroundColor($r('app.color.roomkit_bg_hover'))
      .borderRadius(22)
      .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
      .animation({ duration: 80 })
      .onTouch((event: TouchEvent) => {
        this.isPressed = event.type === TouchType.Down
      })
      .onClick(() => {
        if (!this.isRoutePopupPresented) {
          this.isRoutePopupPresented = true
        }
      })
      this.routePopup()
    }
  }
}
