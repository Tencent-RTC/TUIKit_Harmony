import { RoomState, RoomStore } from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../../base/util/RoomResources'
import { RoomPopup } from '../../../../base/popup/RoomPopup'
import { RoomParticipantListView } from '../participantlist/RoomParticipantListView'

@Component
export struct RoomParticipantButton {
  @Prop roomID: string = ''
  @State private isPressed: boolean = false
  @State private isParticipantPresented: boolean = false
  @State private roomState: RoomState = RoomStore.shared().state

  private participantCount(): number {
    const room = this.roomState.currentRoom
    return room?.roomID === this.roomID ? room.participantCount : 0
  }

  build() {
    Stack() {
      Image(RoomResources.image('roomkit_icon_members')).width(20).height(20)
      if (this.participantCount() > 0) {
        Text(this.participantCount() > 99 ? '99+' : `${this.participantCount()}`)
          .height(12)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .position({ left: 30, top: 4 })
      }
      RoomPopup({
        isPresented: this.isParticipantPresented,
        onDismiss: () => this.isParticipantPresented = false,
      }) {
        RoomParticipantListView({ roomID: this.roomID })
      }
    }
    .width(44)
    .height(44)
    .backgroundColor(this.isParticipantPresented ? $r('app.color.roomkit_bg_hover_strong') :
      $r('app.color.roomkit_bg_hover'))
    .borderRadius(22)
    .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
    .animation({ duration: 80 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => this.isParticipantPresented = true)
  }
}
