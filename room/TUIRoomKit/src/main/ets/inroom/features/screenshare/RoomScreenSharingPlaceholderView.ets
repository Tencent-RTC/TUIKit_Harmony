import {
  DeviceStatus,
  DeviceStore,
  RoomParticipantState,
  RoomParticipantStore,
} from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../base/util/RoomResources'

@Component
export struct RoomScreenSharingPlaceholderView {
  @Prop @Watch('bindRoom') roomID: string = ''
  @State private participantState?: RoomParticipantState = undefined
  @State private liveDotOpacity: number = 1

  aboutToAppear(): void {
    this.bindRoom()
  }

  private bindRoom(): void {
    this.participantState = this.roomID.length > 0 ? RoomParticipantStore.create(this.roomID).state : undefined
  }

  private isSharing(): boolean {
    return this.participantState?.localParticipant?.screenShareStatus === DeviceStatus.on
  }

  build() {
    if (this.isSharing()) {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Image(RoomResources.image('roomkit_icon_screen_share_accent'))
            .width(48)
            .height(48)
          Text(RoomResources.string('roomkit_screen_share_sharing_phone'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.roomkit_fg_primary'))
            .margin({ top: 14 })
          Row({ space: 6 }) {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor($r('app.color.roomkit_danger'))
              .opacity(this.liveDotOpacity)
              .animation({ duration: 700, curve: Curve.Linear, iterations: -1, playMode: PlayMode.Alternate })
              .onAppear(() => {
                this.liveDotOpacity = 0.35
              })
            Text(RoomResources.string('roomkit_screen_share_live'))
              .fontSize(12)
              .fontColor($r('app.color.roomkit_danger'))
          }
          .margin({ top: 8 })
          Text(RoomResources.string('roomkit_screen_share_sharing_phone_hint'))
            .fontSize(12)
            .lineHeight(17)
            .fontColor($r('app.color.roomkit_fg_secondary'))
            .textAlign(TextAlign.Center)
            .constraintSize({ maxWidth: 248 })
            .margin({ top: 8 })
          Button(RoomResources.string('roomkit_screen_share_stop'))
            .height(36)
            .constraintSize({ minWidth: 128 })
            .padding({ left: 20, right: 20 })
            .fontSize(14)
            .fontColor($r('app.color.roomkit_fg_on_danger'))
            .backgroundColor($r('app.color.roomkit_danger'))
            .borderRadius(18)
            .margin({ top: 22 })
            .onClick(() => DeviceStore.shared().stopScreenShare())
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 40, right: 40, top: 24, bottom: 36 })
      .backgroundColor($r('app.color.roomkit_bg_share_placeholder'))
    }
  }
}
