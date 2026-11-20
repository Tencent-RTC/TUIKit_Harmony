import { pasteboard } from '@kit.BasicServicesKit'
import { RoomInfo, RoomState, RoomStore } from '@tencentcloud/atomicxcore'
import { getRoomUserDisplayName } from '../../../base/util/DisplayName'
import { RoomResources } from '../../../base/util/RoomResources'

@Component
export struct RoomInfoPopup {
  @Prop roomID: string = ''
  @State private roomState: RoomState = RoomStore.shared().state
  @State private copiedTarget: string = ''
  private copiedTimer: number = -1

  aboutToDisappear(): void {
    clearTimeout(this.copiedTimer)
  }

  private currentRoom(): RoomInfo | undefined {
    const room = this.roomState.currentRoom
    return room !== undefined && room.roomID === this.roomID ? room : undefined
  }

  private copy(text: string, target: string): void {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
      pasteboard.getSystemPasteboard().setDataSync(data)
    } catch (error) {
      return
    }
    clearTimeout(this.copiedTimer)
    this.copiedTarget = target
    this.copiedTimer = setTimeout(() => {
      this.copiedTarget = ''
    }, 2000)
  }

  private invitationText(room: RoomInfo): string {
    const lines: string[] = [
      room.roomName,
      RoomResources.string('roomkit_room_info_invitation_room_id', room.roomID),
    ]
    const password = room.password ?? ''
    if (password.length > 0) {
      lines.push(RoomResources.string('roomkit_room_info_invitation_password', password))
    }
    return lines.join('\n')
  }

  @Builder
  infoRow(label: string, value: string, copyTarget: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.roomkit_fg_secondary'))
      Text(value)
        .fontSize(15)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .layoutWeight(1)
        .margin({ left: 16 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (copyTarget.length > 0) {
        Stack() {
          Image(RoomResources.image(this.copiedTarget === copyTarget ?
            'roomkit_icon_check_success' : 'roomkit_icon_copy_accent'))
            .width(16)
            .height(16)
        }
        .width(22)
        .height(22)
        .margin({ left: 16 })
        .borderRadius(8)
        .backgroundColor(this.copiedTarget === copyTarget ? $r('app.color.roomkit_success_soft') : Color.Transparent)
        .onClick(() => this.copy(value, copyTarget))
      }
    }
    .width('100%')
    .height(42)
  }

  build() {
    Column() {
      Text(this.currentRoom()?.roomName ?? '')
        .width('100%')
        .padding({ top: 8, left: 20, right: 20 })
        .fontSize(16)
        .fontWeight(500)
        .fontColor($r('app.color.roomkit_fg_primary'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Column()
        .height(1)
        .backgroundColor($r('app.color.roomkit_info_line'))
        .margin({ top: 16, left: 20, right: 20 })
      Column() {
        this.infoRow(
          RoomResources.string('roomkit_room_info_host'),
          this.currentRoom() !== undefined ? getRoomUserDisplayName(this.currentRoom()!.roomOwner) : '',
          '',
        )
        this.infoRow(RoomResources.string('roomkit_room_info_room_id'), this.roomID, 'id')
        if ((this.currentRoom()?.password ?? '').length > 0) {
          this.infoRow(RoomResources.string('roomkit_room_info_password'), this.currentRoom()!.password!, 'password')
        }
      }
      .width('100%')
      .padding({ top: 8, left: 20, right: 20 })
      Column() {
        Stack() {
          Text(RoomResources.string(this.copiedTarget === 'invite' ? 'roomkit_common_copied' : 'roomkit_room_info_invitation'))
            .fontSize(15)
            .fontColor(this.copiedTarget === 'invite' ?
              $r('app.color.roomkit_success_text') : $r('app.color.roomkit_fg_on_accent'))
        }
        .width('100%')
        .height(44)
        .borderRadius(8)
        .backgroundColor(this.copiedTarget === 'invite' ?
          $r('app.color.roomkit_success_soft') : $r('app.color.roomkit_accent'))
        .onClick(() => {
          const room = this.currentRoom()
          if (room !== undefined) {
            this.copy(this.invitationText(room), 'invite')
          }
        })
      }
      .width('100%')
      .padding({ top: 16, left: 20, right: 20 })
    }
    .width('100%')
    .padding({ bottom: 14 })
  }
}
