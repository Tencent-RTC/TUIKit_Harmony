import { RoomResources } from '../../../base/util/RoomResources'
import { RoomSettingsPage } from './RoomSettingsPage'

@Component
export struct RoomSettingsButton {
  @Prop showsTitle: boolean = false
  onRequestDismiss?: () => void
  onShowSettings?: () => void
  @State private isPressed: boolean = false
  @State private isSettingsVisible: boolean = false

  private handleTap(): void {
    this.onRequestDismiss?.()
    if (this.onShowSettings !== undefined) {
      this.onShowSettings!()
      return
    }
    this.isSettingsVisible = true
  }

  @Builder
  settingsPage() {
    RoomSettingsPage({
      onBack: () => {
        this.isSettingsVisible = false
      },
    })
  }

  build() {
    Column({ space: this.showsTitle ? 7 : 0 }) {
      Stack() {
        Image(RoomResources.image('roomkit_icon_settings'))
          .width(this.showsTitle ? 21 : 20)
          .height(this.showsTitle ? 21 : 20)
      }
      .width(this.showsTitle ? 46 : 44)
      .height(this.showsTitle ? 46 : 44)
      .borderRadius(this.showsTitle ? 23 : 22)
      .backgroundColor($r('app.color.roomkit_bg_hover'))
      if (this.showsTitle) {
        Text(RoomResources.string('roomkit_settings_title'))
          .fontSize(11)
          .fontColor($r('app.color.roomkit_fg_secondary'))
          .textAlign(TextAlign.Center)
      }
    }
    .scale({ x: this.isPressed ? 0.92 : 1, y: this.isPressed ? 0.92 : 1 })
    .onTouch((event: TouchEvent) => {
      this.isPressed = event.type === TouchType.Down
    })
    .onClick(() => this.handleTap())
    .bindContentCover(this.isSettingsVisible, this.settingsPage(), {
      modalTransition: ModalTransition.DEFAULT,
      onDisappear: () => this.isSettingsVisible = false,
    })
  }
}
