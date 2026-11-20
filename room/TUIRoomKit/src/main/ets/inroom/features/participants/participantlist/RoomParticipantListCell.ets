import { DeviceStatus, LoginStore, ParticipantRole, RoomParticipant } from '@tencentcloud/atomicxcore'
import { RoomAvatar } from '../../../../base/avatar/RoomAvatar'
import { getParticipantDisplayName } from '../../../../base/util/DisplayName'
import { RoomResources } from '../../../../base/util/RoomResources'

@Component
export struct RoomParticipantListCell {
  @Prop participant: RoomParticipant = new RoomParticipant()
  @Prop canAction: boolean = false
  onTap?: () => void

  @Builder
  tag(text: string, foreground: ResourceColor, background: ResourceColor) {
    Text(text)
      .fontSize(10)
      .fontWeight(600)
      .fontColor(foreground)
      .padding({ left: 6, right: 6 })
      .height(18)
      .backgroundColor(background)
      .borderRadius(9)
  }

  build() {
    Row() {
      RoomAvatar({ text: getParticipantDisplayName(this.participant), url: this.participant.avatarURL, avatarSize: 32 })
      Row({ space: 6 }) {
        Text(getParticipantDisplayName(this.participant))
          .fontSize(13)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 160 })
        if (this.participant.userID === LoginStore.shared().state.loginUserInfo?.userID) {
          this.tag(RoomResources.string('roomkit_participants_me'), $r('app.color.roomkit_fg_secondary'), '#FFE8E8E8')
        }
        if (this.participant.role === ParticipantRole.owner) {
          this.tag(RoomResources.string('roomkit_participants_owner'), $r('app.color.roomkit_role_owner_fg'),
            $r('app.color.roomkit_role_owner_bg'))
        } else if (this.participant.role === ParticipantRole.admin) {
          this.tag(RoomResources.string('roomkit_participants_admin'), $r('app.color.roomkit_role_admin_fg'),
            $r('app.color.roomkit_role_admin_bg'))
        }
        if (this.participant.screenShareStatus === DeviceStatus.on) {
          Row({ space: 3 }) {
            Image(RoomResources.image('roomkit_icon_screen_share_tag')).width(10).height(10)
            Text(RoomResources.string('roomkit_participants_sharing'))
              .fontSize(10)
              .fontWeight(600)
              .fontColor($r('app.color.roomkit_role_owner_fg'))
          }
          .height(18)
          .padding({ left: 6, right: 6 })
          .backgroundColor($r('app.color.roomkit_role_owner_bg'))
          .borderRadius(9)
        }
      }
      .layoutWeight(1)
      .margin({ left: 12, right: 16 })
      Image(RoomResources.image(this.participant.microphoneStatus === DeviceStatus.on ?
        'roomkit_icon_microphone' : 'roomkit_icon_microphone_off'))
        .width(14)
        .height(14)
        .margin({ right: 18 })
      Image(RoomResources.image(this.participant.cameraStatus === DeviceStatus.on ?
        'roomkit_icon_camera' : 'roomkit_icon_camera_off'))
        .width(14)
        .height(14)
        .margin({ right: 22 })
    }
    .width('100%')
    .height(50)
    .padding({ left: 16 })
    .enabled(this.canAction)
    .onClick(() => this.onTap?.())
  }
}
