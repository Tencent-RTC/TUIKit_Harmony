import { inputMethod } from '@kit.IMEKit'
import { RoomToast } from 'tuiroomkit'
import { RoomMediaDevice, RoomMediaOptions, RoomPageHeader, RoomPageTheme, roomText } from './RoomPageComponents'

@Component
export struct RoomJoinPage {
  @Prop @Watch('activeChanged') active: boolean = true
  onBack?: () => void
  onJoin?: (roomID: string, microphoneOn: boolean, cameraOn: boolean, speakerOn: boolean) => void
  @State private roomID: string = ''
  @State private microphoneOn: boolean = true
  @State private speakerOn: boolean = true
  @State private cameraOn: boolean = true
  @State private pushing: boolean = false
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0

  private activeChanged(): void { if (this.active) { this.pushing = false } }
  private mediaChanged(device: RoomMediaDevice, isOn: boolean): void {
    if (device === RoomMediaDevice.MICROPHONE) { this.microphoneOn = isOn }
    else if (device === RoomMediaDevice.SPEAKER) { this.speakerOn = isOn }
    else { this.cameraOn = isOn }
  }
  private join(): void {
    const roomID = this.roomID.trim()
    if (roomID.length === 0) { RoomToast.show(roomText('app_room_join_invalid')); return }
    if (this.pushing) { return }
    this.pushing = true
    inputMethod.getController().stopInputSession()
    this.onJoin?.(roomID, this.microphoneOn, this.cameraOn, this.speakerOn)
  }

  build() {
    Column() {
      RoomPageHeader({ title: roomText('app_room_join_title'), onBack: () => this.onBack?.() })
      Scroll() {
        Column() {
          Row() {
            Text(roomText('app_room_join_id')).fontSize(15).fontColor(RoomPageTheme.primary)
            TextInput({ text: $$this.roomID, placeholder: roomText('app_room_join_placeholder') })
              .layoutWeight(1).height(48).padding({ top: 4, bottom: 4 }).margin({ left: 16 }).fontSize(15)
              .fontColor(RoomPageTheme.secondary).placeholderColor(RoomPageTheme.tertiary)
              .textAlign(TextAlign.End).backgroundColor(Color.Transparent).enterKeyType(EnterKeyType.Done)
              .onSubmit(() => this.join())
          }
          .width('100%').height(60).padding({ left: 16, right: 16 })
          .backgroundColor(RoomPageTheme.surface).borderRadius(12)
          RoomMediaOptions({ microphoneOn: this.microphoneOn, speakerOn: this.speakerOn, cameraOn: this.cameraOn,
            onChange: (device: RoomMediaDevice, isOn: boolean) => this.mediaChanged(device, isOn) }).margin({ top: 12 })
        }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 16 })
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
      Row() {
        Button(roomText('app_room_join_title')).width('100%').height(48).fontSize(15).fontColor(Color.White)
          .backgroundColor(RoomPageTheme.accent).borderRadius(12).enabled(!this.pushing).onClick(() => this.join())
      }.width('100%').padding({ left: 16, right: 16 }).margin({ bottom: Math.max(this.safeBottom, 20) })
    }.width('100%').height('100%').backgroundColor(RoomPageTheme.canvas)
    .gesture(TapGesture().onAction(() => inputMethod.getController().stopInputSession()), GestureMask.Normal)
  }
}
