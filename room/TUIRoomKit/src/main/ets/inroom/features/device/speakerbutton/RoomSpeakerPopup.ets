import { AudioRoute } from '@tencentcloud/atomicxcore'
import { RoomPopup, RoomPopupContentHeight } from '../../../../base/popup/RoomPopup'
import { RoomResources } from '../../../../base/util/RoomResources'

@Component
export struct RoomSpeakerPopup {
  @Prop isPresented: boolean = false
  @Prop currentRoute: AudioRoute = AudioRoute.speakerphone
  @State private pressedRoute?: AudioRoute = undefined
  onSelect?: (route: AudioRoute) => void
  onDismiss?: () => void

  private routeIcon(route: AudioRoute): string {
    switch (route) {
      case AudioRoute.speakerphone:
        return this.currentRoute === route ? 'roomkit_icon_speaker_accent' : 'roomkit_icon_speaker_primary'
      case AudioRoute.earpiece:
        return this.currentRoute === route ? 'roomkit_icon_earpiece_accent' : 'roomkit_icon_earpiece_primary'
    }
  }

  @Builder
  routeRow(route: AudioRoute) {
    Row({ space: 12 }) {
      Image(RoomResources.image(this.routeIcon(route)))
        .width(22)
        .height(22)
      Text(RoomResources.string(route === AudioRoute.speakerphone ?
        'roomkit_main_audio_route_speaker' : 'roomkit_main_audio_route_earpiece'))
        .layoutWeight(1)
        .fontSize(15)
        .fontColor(this.currentRoute === route ? $r('app.color.roomkit_accent') : $r('app.color.roomkit_fg_primary'))
      if (this.currentRoute === route) {
        Image(RoomResources.image('roomkit_icon_check_accent')).width(18).height(18)
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.currentRoute === route ? $r('app.color.roomkit_accent_soft') :
      (this.pressedRoute === route ? $r('app.color.roomkit_bg_press') : Color.Transparent))
    .borderRadius(12)
    .onTouch((event: TouchEvent) => {
      this.pressedRoute = event.type === TouchType.Down ? route : undefined
    })
    .onClick(() => this.onSelect?.(route))
  }

  build() {
    RoomPopup({
      isPresented: this.isPresented,
      contentHeight: RoomPopupContentHeight.AUTO,
      panelBackgroundColor: Color.Transparent,
      panelBorderColor: Color.Transparent,
      showsHandleBar: false,
      onDismiss: () => this.onDismiss?.(),
    }) {
      Column() {
        Column() {
          this.routeRow(AudioRoute.speakerphone)
          this.routeRow(AudioRoute.earpiece)
        }
        .width('100%')
        .padding(6)
        .backgroundColor($r('app.color.roomkit_bg_canvas'))
        .borderRadius(16)
        Button(RoomResources.string('roomkit_room_common_cancel'))
          .width('100%')
          .height(48)
          .margin({ top: 8 })
          .fontSize(15)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .backgroundColor($r('app.color.roomkit_bg_canvas'))
          .borderRadius(12)
          .onClick(() => this.onDismiss?.())
      }
      .width('100%')
      .padding(12)
    }
  }
}
