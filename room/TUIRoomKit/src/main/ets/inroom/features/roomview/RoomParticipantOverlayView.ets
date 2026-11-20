import {
  DeviceStatus,
  DeviceStore,
  NetworkQuality,
  ParticipantRole,
  RoomParticipant,
} from '@tencentcloud/atomicxcore'
import { RoomAvatar } from '../../../base/avatar/RoomAvatar'
import { getParticipantDisplayName } from '../../../base/util/DisplayName'
import { RoomResources } from '../../../base/util/RoomResources'
import { RoomMicLevelView } from '../device/micbutton/RoomMicLevelView'

@Component
export struct RoomParticipantOverlayView {
  @Prop participant: RoomParticipant = new RoomParticipant()
  @Prop isScreenStream: boolean = false
  @Prop isLocal: boolean = false
  @Prop volume: number = 0
  @Prop networkQuality: NetworkQuality = NetworkQuality.unknown
  @State private cellWidth: number = 0
  @State private isFlipPressed: boolean = false
  @State private localBadgeWidth: number = 0

  private microphoneOn(): boolean {
    return this.participant.microphoneStatus === DeviceStatus.on
  }

  private hasVideo(): boolean {
    return this.isScreenStream ? this.participant.screenShareStatus === DeviceStatus.on :
      this.participant.cameraStatus === DeviceStatus.on
  }

  private showsNetworkMark(): boolean {
    const quality = this.networkQuality
    return quality === NetworkQuality.bad || quality === NetworkQuality.veryBad || quality === NetworkQuality.down
  }

  private showsLocalBadge(): boolean {
    return this.isLocal && this.cellWidth >= 96
  }

  private showsRoleBadge(): boolean {
    const role = this.participant.role
    return role !== undefined && role !== ParticipantRole.generalUser && this.cellWidth >= 112
  }

  private sharingText(): string {
    const name = getParticipantDisplayName(this.participant)
    return name.length === 0 ? RoomResources.string('roomkit_room_view_sharing_screen') :
      RoomResources.string('roomkit_room_view_sharing_by', name)
  }

  private overlayWidth(): number {
    return Math.max(this.cellWidth - 12, 0)
  }

  private sharingTextMaxWidth(): number {
    return Math.max(this.overlayWidth() - 34, 0)
  }

  private displayNameMaxWidth(): number {
    let occupiedWidth = 26
    if (this.showsRoleBadge()) {
      occupiedWidth += 18
    }
    if (this.showsLocalBadge()) {
      occupiedWidth += this.localBadgeWidth + 4
    }
    return Math.max(this.overlayWidth() - occupiedWidth, 0)
  }

  build() {
    Stack() {
      if (!this.isScreenStream && !this.hasVideo()) {
        Column() {
          RoomAvatar({
            text: getParticipantDisplayName(this.participant),
            url: this.participant.avatarURL,
            avatarSize: 40,
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }

      if (this.isLocal && this.participant.cameraStatus === DeviceStatus.on) {
        Image(RoomResources.image('roomkit_icon_flip_camera_button'))
          .width(28)
          .height(28)
          .position({ left: 8, top: 8 })
          .scale({ x: this.isFlipPressed ? 0.96 : 1, y: this.isFlipPressed ? 0.96 : 1 })
          .animation({ duration: 100 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              event.stopPropagation()
            }
            this.isFlipPressed = event.type === TouchType.Down
          })
          .onClick(() => {
            DeviceStore.shared().switchCamera(!DeviceStore.shared().state.isFrontCamera)
          })
      }

      if (this.showsNetworkMark()) {
        Row({ space: 2 }) {
          ForEach([4, 8, 12], (height: number, index: number) => {
            Column()
              .width(3)
              .height(height)
              .borderRadius(1)
              .backgroundColor($r('app.color.roomkit_danger'))
              .opacity(index === 0 ? 1 : 0.18)
          })
        }
        .alignItems(VerticalAlign.Bottom)
        .position({ right: 8, top: 8 })
        .hitTestBehavior(HitTestMode.None)
      }

      if (this.isScreenStream) {
        Row({ space: 6 }) {
          Image(RoomResources.image('roomkit_icon_screen_share'))
            .width(12)
            .height(12)
            .fillColor($r('app.color.roomkit_fg_on_media'))
            .flexShrink(0)
          Text(this.sharingText())
            .fontSize(11)
            .fontWeight(600)
            .fontColor($r('app.color.roomkit_fg_on_media_muted'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: this.sharingTextMaxWidth() })
            .flexShrink(1)
        }
        .height(22)
        .padding({ left: 8, right: 8 })
        .backgroundColor($r('app.color.roomkit_bg_on_media'))
        .borderRadius(11)
        .constraintSize({ maxWidth: this.overlayWidth() })
        .position({ left: 6, bottom: 6 })
        .hitTestBehavior(HitTestMode.None)
      } else {
        Row({ space: 4 }) {
          Stack() {
            RoomMicLevelView({ level: this.microphoneOn() ? this.volume : 0 })
              .width(20)
              .height(20)
              .scale({ x: 0.6, y: 0.6 })
              .opacity(this.microphoneOn() ? 1 : 0)
            Image(RoomResources.image(this.microphoneOn() ?
              'roomkit_icon_microphone_on_roomview' : 'roomkit_icon_microphone_off_roomview'))
              .width(12)
              .height(12)
          }
          .width(12)
          .height(12)
          .flexShrink(0)
          if (this.showsRoleBadge()) {
            Image(RoomResources.image(this.participant.role === ParticipantRole.owner ?
              'roomkit_icon_role_owner' : 'roomkit_icon_role_admin'))
              .width(14)
              .height(14)
              .flexShrink(0)
          }
          Text(getParticipantDisplayName(this.participant))
            .fontSize(10)
            .fontColor($r('app.color.roomkit_fg_on_media'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: this.displayNameMaxWidth() })
            .flexShrink(1)
          if (this.showsLocalBadge()) {
            Text(RoomResources.string('roomkit_room_view_me'))
              .fontSize(10)
              .fontWeight(500)
              .fontColor($r('app.color.roomkit_fg_on_media'))
              .textAlign(TextAlign.Center)
              .height(16)
              .padding({ left: 4, right: 4 })
              .backgroundColor($r('app.color.roomkit_bg_press_on_media'))
              .borderRadius(8)
              .flexShrink(0)
              .onAreaChange((_: Area, area: Area) => {
                this.localBadgeWidth = area.width as number
              })
          }
        }
        .padding({ left: 4, right: 6, top: 2, bottom: 2 })
        .backgroundColor($r('app.color.roomkit_bg_on_media'))
        .borderRadius(10)
        .constraintSize({ maxWidth: this.overlayWidth() })
        .position({ left: 6, bottom: 6 })
        .hitTestBehavior(HitTestMode.None)
      }

      Stack()
        .width('100%')
        .height('100%')
        .borderRadius(12)
        .border({ width: this.microphoneOn() && this.volume > 0 ? 2 : 0,
          color: $r('app.color.roomkit_success_border') })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_: Area, area: Area) => {
      this.cellWidth = area.width as number
    })
  }
}
