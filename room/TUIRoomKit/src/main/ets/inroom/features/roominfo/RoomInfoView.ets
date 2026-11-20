import { RoomState, RoomStore } from '@tencentcloud/atomicxcore'
import { RoomPopup, RoomPopupContentHeight } from '../../../base/popup/RoomPopup'
import { RoomResources } from '../../../base/util/RoomResources'
import { RoomInfoPopup } from './RoomInfoPopup'

@Component
export struct RoomInfoView {
  @Prop roomID: string = ''
  @State private roomState: RoomState = RoomStore.shared().state
  @State private elapsed: string = '00:00'
  @State private isDetailOpen: boolean = false
  @State private isPopupPresented: boolean = false
  @State private isPressed: boolean = false
  private elapsedTimer: number = -1

  aboutToAppear(): void {
    this.tickElapsed()
    this.elapsedTimer = setInterval(() => this.tickElapsed(), 1000)
  }

  aboutToDisappear(): void {
    clearInterval(this.elapsedTimer)
  }

  private normalizeToMillis(raw: number): number {
    if (raw <= 0) {
      return 0
    }
    return raw >= 1000000000000 ? raw : raw * 1000
  }

  private static twoDigits(value: number): string {
    return value < 10 ? `0${value}` : `${value}`
  }

  private static formatElapsed(seconds: number): string {
    const minutes = Math.floor(seconds / 60)
    const remainder = seconds % 60
    if (minutes < 60) {
      return `${RoomInfoView.twoDigits(minutes)}:${RoomInfoView.twoDigits(remainder)}`
    }
    return `${RoomInfoView.twoDigits(Math.floor(minutes / 60))}:${RoomInfoView.twoDigits(minutes % 60)}` +
      `:${RoomInfoView.twoDigits(remainder)}`
  }

  private tickElapsed(): void {
    const room = this.roomState.currentRoom
    if (room === undefined || room.roomID !== this.roomID) {
      return
    }
    const base = this.normalizeToMillis(room.createTime)
    if (base <= 0) {
      return
    }
    const seconds = Math.max(0, Math.floor((Date.now() - base) / 1000))
    this.elapsed = RoomInfoView.formatElapsed(seconds)
  }

  private roomName(): string {
    const room = this.roomState.currentRoom
    if (room !== undefined && room.roomID === this.roomID && room.roomName.length > 0) {
      return room.roomName
    }
    return this.roomID
  }

  private openDetail(): void {
    if (this.isDetailOpen) {
      return
    }
    const room = this.roomState.currentRoom
    if (room === undefined || room.roomID.length === 0) {
      return
    }
    this.isDetailOpen = true
    this.isPopupPresented = true
  }

  private closeDetail(): void {
    this.isPopupPresented = false
    this.isDetailOpen = false
  }

  @Builder
  detailPopup() {
    RoomPopup({
      isPresented: this.isPopupPresented,
      contentHeight: RoomPopupContentHeight.AUTO,
      onDismiss: () => this.closeDetail(),
    }) {
      RoomInfoPopup({ roomID: this.roomID })
    }
  }

  build() {
    Stack() {
      Row() {
        Text(this.roomName())
          .fontSize(13)
          .fontWeight(600)
          .fontColor($r('app.color.roomkit_fg_primary'))
          .letterSpacing(-0.156)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 124 })
        Column()
          .width(1)
          .height(12)
          .backgroundColor($r('app.color.roomkit_separator'))
          .margin({ left: 7, right: 7 })
        Text(this.elapsed)
          .fontSize(13)
          .fontWeight(500)
          .fontColor($r('app.color.roomkit_fg_secondary'))
          .letterSpacing(0.26)
        Image(RoomResources.image(this.isDetailOpen ? 'roomkit_icon_collapse_accent' : 'roomkit_icon_collapse_tertiary'))
          .width(11)
          .height(11)
          .margin({ left: 2 })
          .rotate({ angle: this.isDetailOpen ? 180 : 0 })
          .animation({ duration: 250 })
      }
      .padding({ left: 6, right: 6, top: 4, bottom: 4 })
      .borderRadius(8)
      .backgroundColor(this.isPressed ? $r('app.color.roomkit_bg_press') : Color.Transparent)
      .constraintSize({ maxWidth: 220 })
      .onTouch((event: TouchEvent) => {
        this.isPressed = event.type === TouchType.Down
      })
      .onClick(() => this.openDetail())
      this.detailPopup()
    }
  }
}
