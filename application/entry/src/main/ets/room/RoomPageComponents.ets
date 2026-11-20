export function roomText(name: string, ...args: (string | number)[]): string {
  return getContext().resourceManager.getStringByNameSync(name, ...args)
}

export class RoomPageTheme {
  static readonly accent: string = '#FF0071E3'
  static readonly accentSoft: string = '#FF3890E9'
  static readonly canvas: string = '#FFF5F4F5'
  static readonly surface: string = '#FFFFFFFF'
  static readonly primary: string = '#FF1C1B1C'
  static readonly secondary: string = '#FF636263'
  static readonly tertiary: string = '#FF8E8D8E'
  static readonly hover: string = '#0F1C1B1C'
}

export enum RoomMediaDevice {
  MICROPHONE,
  SPEAKER,
  CAMERA,
}

@Component
export struct RoomPageHeader {
  title: string = ''
  onBack?: () => void
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Text(this.title)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(RoomPageTheme.primary)
          .padding({ left: 72, right: 72 })
        Row() {
          Button() {
            Image($r('app.media.roomkit_icon_back')).width(22).height(22)
          }
          .width(40)
          .height(40)
          .padding(9)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .accessibilityText(roomText('app_back'))
          .onClick(() => this.onBack?.())
        }
        .width('100%')
        .padding({ left: 8 })
      }
      .width('100%')
      .height(52)
    }
    .width('100%')
    .padding({ top: this.safeTop })
    .backgroundColor(RoomPageTheme.surface)
  }
}

@Component
export struct RoomMediaOptions {
  @Prop microphoneOn: boolean = true
  @Prop speakerOn: boolean = true
  @Prop cameraOn: boolean = true
  onChange?: (device: RoomMediaDevice, isOn: boolean) => void

  @Builder
  optionRow(title: string, isOn: boolean, device: RoomMediaDevice) {
    Row() {
      Text(title).fontSize(15).fontColor(RoomPageTheme.primary)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(RoomPageTheme.accent)
        .onChange((value: boolean) => this.onChange?.(device, value))
    }
    .width('100%')
    .height(56)
  }

  build() {
    Column() {
      this.optionRow(roomText('app_room_pre_mic_on'), this.microphoneOn, RoomMediaDevice.MICROPHONE)
      this.optionRow(roomText('app_room_pre_speaker_on'), this.speakerOn, RoomMediaDevice.SPEAKER)
      this.optionRow(roomText('app_room_pre_camera_on'), this.cameraOn, RoomMediaDevice.CAMERA)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 4 })
    .backgroundColor(RoomPageTheme.surface)
    .borderRadius(12)
    .clip(true)
  }
}
