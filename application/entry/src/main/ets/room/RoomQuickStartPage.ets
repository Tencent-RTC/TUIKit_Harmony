import { inputMethod } from '@kit.IMEKit'
import { LoginState, LoginStore, RoomStore } from '@tencentcloud/atomicxcore'
import { MeetingLoadingView } from 'tuiroomkit'
import { RoomMediaDevice, RoomMediaOptions, RoomPageHeader, RoomPageTheme, roomText } from './RoomPageComponents'

const roomNotFoundCode: number = 100004

@Component
export struct RoomQuickStartPage {
  @Prop @Watch('activeChanged') active: boolean = true
  onBack?: () => void
  onStart?: (roomID: string, roomName: string, microphoneOn: boolean, cameraOn: boolean, speakerOn: boolean) => void
  @State private loginState: LoginState = LoginStore.shared().state as LoginState
  @State private roomName: string = ''
  @State private microphoneOn: boolean = true
  @State private speakerOn: boolean = true
  @State private cameraOn: boolean = true
  @State private pushing: boolean = false
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0
  private requestID: number = 0

  aboutToAppear(): void { this.updateRoomName() }
  aboutToDisappear(): void { this.cancelPending() }
  private activeChanged(): void {
    if (this.active) { this.pushing = false; this.updateRoomName() } else { this.cancelPending() }
  }
  private cancelPending(): void { this.requestID++; this.pushing = false }
  private updateRoomName(): void {
    if (this.roomName.length > 0) { return }
    const profile = this.loginState.loginUserInfo
    const nickname = profile?.nickname ?? ''
    const source = nickname.length > 0 ? nickname : profile?.userID ?? ''
    if (source.length === 0) { return }
    this.roomName = roomText('app_room_quick_name_value', Array.from(source).slice(0, 10).join(''))
  }
  private mediaChanged(device: RoomMediaDevice, isOn: boolean): void {
    if (device === RoomMediaDevice.MICROPHONE) { this.microphoneOn = isOn }
    else if (device === RoomMediaDevice.SPEAKER) { this.speakerOn = isOn }
    else { this.cameraOn = isOn }
  }
  private start(): void {
    if (this.pushing) { return }
    this.pushing = true
    inputMethod.getController().stopInputSession()
    const request = ++this.requestID
    this.generateUnusedRoomID(request, 5, (roomID: string) => {
      if (!this.active || request !== this.requestID) { return }
      this.pushing = false
      const name = this.roomName.trim().length > 0 ? this.roomName.trim() : roomID
      this.onStart?.(roomID, name, this.microphoneOn, this.cameraOn, this.speakerOn)
    })
  }
  private generateUnusedRoomID(request: number, retries: number, onReady: (roomID: string) => void): void {
    const candidate = `${Math.floor(100000 + Math.random() * 900000)}`
    RoomStore.shared().getRoomInfo(candidate).then(() => {
      if (!this.active || request !== this.requestID) { return }
      if (retries > 0) { this.generateUnusedRoomID(request, retries - 1, onReady) }
      else { onReady(this.fallbackRoomID(candidate)) }
    }).catch((error: Error) => {
      if (!this.active || request !== this.requestID) { return }
      const code = Number(Reflect.get(error, 'code') ?? -1)
      onReady(code === roomNotFoundCode ? candidate : this.fallbackRoomID(candidate))
    })
  }
  private fallbackRoomID(base: string): string { return `${base}-${`${Date.now()}`.substring(0, 6)}` }

  build() {
    Stack() {
      Column() {
        RoomPageHeader({ title: roomText('app_room_quick_title'), onBack: () => this.onBack?.() })
        Scroll() {
          Column() {
            Row() {
              Text(roomText('app_room_quick_name')).fontSize(15).fontColor(RoomPageTheme.primary)
              Text(this.roomName).layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.End).fontSize(15).fontColor(RoomPageTheme.secondary).margin({ left: 16 })
            }
            .width('100%').height(60).padding({ left: 16, right: 16 })
            .backgroundColor(RoomPageTheme.surface).borderRadius(12)
            RoomMediaOptions({ microphoneOn: this.microphoneOn, speakerOn: this.speakerOn, cameraOn: this.cameraOn,
              onChange: (device: RoomMediaDevice, isOn: boolean) => this.mediaChanged(device, isOn) }).margin({ top: 12 })
          }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 16 })
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
        Row() {
          Button(roomText('app_room_quick_title')).width('100%').height(48).fontSize(15).fontColor(Color.White)
            .backgroundColor(RoomPageTheme.accent).borderRadius(12).enabled(!this.pushing).onClick(() => this.start())
        }.width('100%').padding({ left: 16, right: 16 }).margin({ bottom: Math.max(this.safeBottom, 20) })
      }.width('100%').height('100%')
      MeetingLoadingView({ isVisible: this.pushing })
    }.width('100%').height('100%').backgroundColor(RoomPageTheme.canvas)
  }
}
