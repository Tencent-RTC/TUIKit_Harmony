import { LoginState, LoginStore } from '@tencentcloud/atomicxcore'
import { RoomAvatar, RoomToast } from 'tuiroomkit'
import { RoomHomeProfilePopup } from './RoomHomeProfilePopup'
import { RoomPageTheme, roomText } from './RoomPageComponents'

@Component
export struct RoomHomePage {
  onQuickMeeting?: () => void
  onJoinMeeting?: () => void
  onSettings?: () => void
  @State private loginState: LoginState = LoginStore.shared().state as LoginState
  @State private profilePresented: boolean = false
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0

  private displayName(): string {
    const profile = this.loginState.loginUserInfo
    const nickname = profile?.nickname ?? ''
    return nickname.length > 0 ? nickname : profile?.userID ?? ''
  }

  @Builder
  entry(icon: Resource, title: string, showsWell: boolean, action: () => void) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        if (showsWell) {
          Column() { Image(icon).width(6).height(6) }
            .width(22).height(22).justifyContent(FlexAlign.Center).backgroundColor(Color.White).borderRadius(6)
        } else {
          Image(icon).width(22).height(22)
        }
      }
      .width(68)
      .height(68)
      .borderRadius(34)
      .linearGradient({ direction: GradientDirection.Bottom,
        colors: [[RoomPageTheme.accentSoft, 0], [RoomPageTheme.accent, 1]] })
      Text(title)
        .width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).textAlign(TextAlign.Center)
        .fontSize(13).fontWeight(FontWeight.Medium).fontColor(RoomPageTheme.primary).margin({ top: 10 })
    }
    .layoutWeight(1)
    .height(96)
    .onClick(action)
  }

  build() {
    Stack() {
      Column() {
        Row({ space: 8 }) {
          RoomAvatar({ text: this.displayName(), url: this.loginState.loginUserInfo?.avatarURL ?? '', avatarSize: 32 })
            .onClick(() => this.profilePresented = true)
          Text(this.displayName())
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(17).fontWeight(FontWeight.Medium).fontColor(RoomPageTheme.primary)
        }
        .width('100%').height(32).margin({ top: this.safeTop + 10 }).padding({ left: 16, right: 16 })

        Row() {
          this.entry($r('app.media.roomkit_icon_quick_meeting_white'), roomText('app_room_home_quick'), false,
            () => this.onQuickMeeting?.())
          this.entry($r('app.media.roomkit_icon_plus_accent'), roomText('app_room_home_join'), true,
            () => this.onJoinMeeting?.())
          this.entry($r('app.media.roomkit_icon_calendar_white'), roomText('app_room_home_schedule'), false,
            () => RoomToast.show(roomText('app_room_coming_soon')))
        }
        .width('100%').height(96).margin({ top: 16 }).padding({ left: 20, right: 20 })

        Column() {
          Column() {
            Row({ space: 8 }) {
              Column().width(3).height(12).borderRadius(1.5).backgroundColor(RoomPageTheme.accent)
              Text(roomText('app_room_agenda'))
                .fontSize(15).fontWeight(FontWeight.Medium).fontColor(RoomPageTheme.primary)
            }
            .width('100%').margin({ top: 14 }).padding({ left: 16, right: 16 })
            Column({ space: 12 }) {
              Image($r('app.media.roomkit_illustration_agenda_empty'))
                .width('78%').constraintSize({ maxWidth: 232 }).aspectRatio(2).objectFit(ImageFit.Contain)
              Text(roomText('app_room_agenda_empty'))
                .fontSize(15).lineHeight(20).fontColor(RoomPageTheme.secondary).textAlign(TextAlign.Center)
            }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).padding({ bottom: 52 })
          }
          .width('100%').height('100%').backgroundColor(RoomPageTheme.surface).borderRadius(20).clip(true)
        }
        .width('100%').layoutWeight(1).margin({ top: 28, bottom: 16 }).padding({ left: 12, right: 12 })
      }
      .width('100%').height('100%')

      RoomHomeProfilePopup({ isPresented: this.profilePresented,
        onDismiss: () => this.profilePresented = false, onSettings: () => this.onSettings?.() })
    }
    .width('100%').height('100%').backgroundColor(RoomPageTheme.canvas)
  }
}
