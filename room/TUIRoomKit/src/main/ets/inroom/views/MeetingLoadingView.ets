import { RoomResources } from '../../base/util/RoomResources'

@Component
export struct MeetingLoadingView {
  @Prop isVisible: boolean = false
  @State private spinRotation: number = 0

  build() {
    if (this.isVisible) {
      Stack() {
        Stack() {
          Image(RoomResources.image('roomkit_loading_spinner'))
            .width(44)
            .height(44)
            .rotate({ angle: this.spinRotation })
            .animation({ duration: 750, curve: Curve.Linear, iterations: -1 })
            .onAppear(() => {
              this.spinRotation = 360
            })
        }
        .width(44)
        .height(44)
        .offset({ y: -20 })
        Text(RoomResources.string('roomkit_room_entry_joining'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.roomkit_fg_secondary'))
          .textAlign(TextAlign.Center)
          .offset({ y: 32 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.roomkit_bg_canvas'))
      .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
    }
  }
}
