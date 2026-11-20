import { CloudRecordingStatus } from '../features/recording/cloudrecordingstatus/CloudRecordingStatus'
import { RoomSafeArea } from '../../base/util/RoomSafeArea'
import { RoomInfoView } from '../features/roominfo/RoomInfoView'
import { RoomLeaveRoomButton } from '../features/roominfo/leaveroombutton/RoomLeaveRoomButton'
import { RoomNetworkSignalView } from '../features/roominfo/localnetworkinfo/RoomNetworkSignalView'

@Component
export struct MeetingTopBar {
  @Prop roomID: string = ''
  onLeaveOrEnd?: () => void
  @StorageProp(RoomSafeArea.topKey) safeTop: number = 0

  build() {
    Row() {
      RoomInfoView({ roomID: this.roomID })
      RoomNetworkSignalView()
        .margin({ left: 4 })
      CloudRecordingStatus({ roomID: this.roomID })
        .margin({ left: 2 })
      Blank()
      RoomLeaveRoomButton({ roomID: this.roomID, onLeaveOrEnd: this.onLeaveOrEnd })
    }
    .width('100%')
    .height(44 + this.safeTop)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 10, right: 12, top: this.safeTop })
    .backgroundColor($r('app.color.roomkit_bg_surface'))
  }
}
