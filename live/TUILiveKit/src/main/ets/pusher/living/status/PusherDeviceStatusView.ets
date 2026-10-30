import { DeviceError, DeviceStatus, NetworkQuality, NetworkType } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { LiveSlider } from '../../../common/theme/LiveSlider'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveTheme, rgba, white } from '../../../common/theme/LiveTheme'
import { PusherLiveStatusContentStyle } from './PusherLiveStatusView'

export enum MediaStatus {
  normal,
  off,
  deviceError,
  streamError,
}

export enum TemperatureStatus {
  normal,
  fair,
  serious,
}

export class PusherDeviceStatusState {
  temperatureStatus: TemperatureStatus = TemperatureStatus.normal
  networkKind: NetworkType = NetworkType.unknown
  networkQuality: number = 0
  delay: number = 0
  downLoss: number = 0
  upLoss: number = 0
  videoBitrate: number = 0
  videoWidth: number = 0
  videoHeight: number = 0
  frameRate: number = 0
  audioSampleRate: number = 0
  audioBitrate: number = 0
  hasAVStatistics: boolean = false
  cameraStatus: DeviceStatus = DeviceStatus.off
  microphoneStatus: DeviceStatus = DeviceStatus.off
  cameraError: DeviceError = DeviceError.noError
  microphoneError: DeviceError = DeviceError.noError

  copy(): PusherDeviceStatusState {
    const state = new PusherDeviceStatusState()
    Object.keys(this).forEach((key: string) => Reflect.set(state, key, Reflect.get(this, key)))
    return state
  }

  equals(other: PusherDeviceStatusState): boolean {
    return Object.keys(this).every((key: string) => Reflect.get(this, key) === Reflect.get(other, key))
  }

  get videoStatus(): MediaStatus {
    const isAbnormal = this.networkQuality === NetworkQuality.down || (this.hasAVStatistics && this.frameRate < 15)
    return PusherDeviceStatusState.mediaStatus(this.cameraStatus, this.cameraError, isAbnormal)
  }

  get audioStatus(): MediaStatus {
    const isAbnormal = this.hasAVStatistics && (this.audioSampleRate === 0 || this.audioBitrate === 0)
    return PusherDeviceStatusState.mediaStatus(this.microphoneStatus, this.microphoneError, isAbnormal)
  }

  get videoInformation(): string {
    if (!this.hasAVStatistics) {
      return '--\n--\n--'
    }
    const resolution = this.videoWidth > 0 && this.videoHeight > 0 ? `${this.videoWidth}×${this.videoHeight}` : '--'
    const bitrate = this.videoBitrate > 0 ? `${this.videoBitrate} kbps` : '--'
    const fps = this.frameRate > 0 ? `${this.frameRate} FPS` : '--'
    return `${resolution}\n${bitrate}\n${fps}`
  }

  get audioInformation(): string {
    if (!this.hasAVStatistics) {
      return '--\n--'
    }
    const sampleRate = this.audioSampleRate > 0 ? `${this.audioSampleRate} Hz` : '--'
    const bitrate = this.audioBitrate > 0 ? `${this.audioBitrate} kbps` : '--'
    return `${sampleRate}\n${bitrate}`
  }

  private static mediaStatus(status: DeviceStatus, error: DeviceError, streamIsAbnormal: boolean): MediaStatus {
    if (error !== DeviceError.noError) {
      return MediaStatus.deviceError
    }
    if (status !== DeviceStatus.on) {
      return MediaStatus.off
    }
    return streamIsAbnormal ? MediaStatus.streamError : MediaStatus.normal
  }
}

export class Presentation {
  isMuted: boolean = false
  captureVolume: number = 100
  status: PusherDeviceStatusState = new PusherDeviceStatusState()
}

const statusNormal: string = LiveTheme.Color.brandBlue
const statusWarning: string = rgba(1, 0.54, 0.24)
const statusCritical: string = rgba(1, 0.36, 0.38)
const statusUnknown: string = rgba(0.54, 0.58, 0.66)

class DeviceStatusRowModel {
  title: string
  detail: string
  tintColor: string
  icon?: string

  constructor(title: string, detail: string, tintColor: string, icon?: string) {
    this.title = title
    this.detail = detail
    this.tintColor = tintColor
    this.icon = icon
  }

  private static localized(suffix: string): string {
    return LiveKitResources.localizedString(`tuilivekit.pusher.status.${suffix}`)
  }

  static media(kind: string, status: MediaStatus): DeviceStatusRowModel {
    const keys: string[][] =
      [['normal', 'normal'], ['off', 'off'], ['error', 'device_error'], ['error', 'stream_error']]
    const colors: string[] = [statusNormal, statusWarning, statusWarning, statusCritical]
    return new DeviceStatusRowModel(DeviceStatusRowModel.localized(`${kind}.${keys[status][0]}.title`),
      DeviceStatusRowModel.localized(`${kind}.${keys[status][1]}.detail`), colors[status],
      `livekit_status_${kind}${['', '_off', '_error',
        kind === 'audio' ? '_capture_error' : '_stream_error'][status]}`)
  }

  static temperature(status: TemperatureStatus): DeviceStatusRowModel {
    const key = ['normal', 'fair', 'serious'][status]
    return new DeviceStatusRowModel(DeviceStatusRowModel.localized(`temperature.${key}.title`),
      DeviceStatusRowModel.localized(`temperature.${key}.detail`),
      [statusNormal, statusWarning, statusCritical][status],
      ['livekit_status_temperature', 'livekit_status_temperature_warm', 'livekit_status_temperature_hot'][status])
  }

  static network(status: PusherDeviceStatusState): DeviceStatusRowModel {
    const kind = DeviceStatusRowModel.localized(status.networkKind === NetworkType.wifi ? 'network.wifi' :
      status.networkKind === NetworkType.cellular ? 'network.cellular' : 'network.unknown')
    let content: [string, string, string, string | undefined] =
      ['network.checking', 'network.checking_detail', statusUnknown, 'livekit_status_network_checking']
    switch (status.networkQuality) {
      case 1:
        content = ['network.excellent', 'network.keep', statusNormal, undefined]
        break
      case 2:
        content = ['network.good', 'network.keep', statusNormal, undefined]
        break
      case 3:
        content = ['network.poor', 'network.fluctuating', statusWarning, 'livekit_status_network_poor']
        break
      case 4:
        content = ['network.bad', 'network.switch', statusCritical, 'livekit_status_network_bad']
        break
      case 5:
        content = ['network.very_bad', 'network.switch', statusCritical, 'livekit_status_network_bad']
        break
      case 6:
        content = ['network.disconnected', 'network.disconnected_detail', statusCritical, 'livekit_status_network_down']
        break
      default:
        break
    }
    return new DeviceStatusRowModel(LiveKitResources.localizedFormat('tuilivekit.pusher.status.network.title', kind,
      DeviceStatusRowModel.localized(content[0])), DeviceStatusRowModel.localized(content[1]), content[2], content[3])
  }
}

@Component
export struct PusherDeviceStatusView {
  @Prop presentation: Presentation = new Presentation()
  onSetCaptureVolume?: (volume: number) => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0

  private captureVolume(): number {
    return Math.min(Math.max(this.presentation.captureVolume, 0), 100)
  }

  @Builder
  statusRow(icon: string, model: DeviceStatusRowModel, titleTrailingInset: number = 0) {
    Row({ space: 13 }) {
      Image(LiveKitResources.image(model.icon ?? icon)).width(30).height(30).objectFit(ImageFit.Contain)
        .margin({ top: 4 })
      Column({ space: 4 }) {
        Text(model.title)
          .attributeModifier(new LiveText(LiveTheme.TextRole.body, LiveTheme.TextTone.secondary, TextAlign.Start, true))
          .padding({ right: titleTrailingInset })
        Text(model.detail).attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.disabled))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .constraintSize({ minHeight: 42 })
    .padding({ left: 21, right: 21 })
  }

  @Builder
  separator() {
    Column() {
      Divider().strokeWidth(0.5).color(PusherLiveStatusContentStyle.separator)
    }
    .width('100%')
    .padding({
      left: 21,
      right: 21,
      top: 12,
      bottom: 12
    })
  }

  @Builder
  streamColumn(titleKey: string, fieldsKey: string, fieldWidth: number, valueSpacing: number, lines: number,
    value: string) {
    Column() {
      Text(LiveKitResources.localizedString(`tuilivekit.pusher.status.${titleKey}`))
        .attributeModifier(new LiveText(LiveTheme.TextRole.sectionTitle, LiveTheme.TextTone.secondary))
        .fontColor(white(0.82))
        .height(16)
        .margin({ top: 14 })
      Row({ space: valueSpacing }) {
        Text(LiveKitResources.localizedString(`tuilivekit.pusher.status.${fieldsKey}`))
          .attributeModifier(
            new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.disabled, TextAlign.Start, false, 19))
          .fontColor(white(0.34))
          .maxLines(lines)
          .minFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.metadata) * 0.75)
          .maxFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.metadata))
          .constraintSize({ minWidth: fieldWidth })
          .height(lines * 19)
        Text(value)
          .attributeModifier(
            new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.secondary, TextAlign.Start, false, 19))
          .fontColor(white(0.68))
          .maxLines(lines)
          .minFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.metadata) * 0.75)
          .maxFontSize(LiveTheme.Typography.size(LiveTheme.TextRole.metadata))
          .layoutWeight(1)
          .height(lines * 19)
      }
      .alignItems(VerticalAlign.Top)
      .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .height('100%')
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        this.statusRow('livekit_status_video',
          DeviceStatusRowModel.media('video', this.presentation.status.videoStatus), 57)
        Text(this.presentation.status.hasAVStatistics && this.presentation.status.videoWidth > 0 ?
          `${this.presentation.status.videoWidth}P` : '--')
          .attributeModifier(new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.tertiary, TextAlign.End))
          .width(49)
          .height(16)
          .margin({ top: 2, right: 23 })
      }
      .margin({ top: 14 })

      this.separator()
      this.statusRow('livekit_status_audio', DeviceStatusRowModel.media('audio',
        this.presentation.isMuted || this.presentation.captureVolume === 0 ? MediaStatus.off :
          this.presentation.status.audioStatus))
      Row() {
        Slider({
          value: this.captureVolume(),
          min: 0,
          max: 100,
          step: 1
        })
          .attributeModifier(new LiveSlider())
          .layoutWeight(1)
          .height(23)
          .margin({ left: 64, right: 13 })
          .accessibilityText(LiveKitResources.localizedString('tuilivekit.pusher.status.voice_volume'))
          .onChange((value: number) => this.onSetCaptureVolume?.(Math.round(value)))
        Text(`${this.captureVolume()}`)
          .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.tertiary, TextAlign.End))
          .width(28)
          .height(15)
          .margin({ right: 23 })
      }
      .width('100%')
      .height(35)
      .alignItems(VerticalAlign.Top)

      this.separator()
      this.statusRow('livekit_status_temperature',
        DeviceStatusRowModel.temperature(this.presentation.status.temperatureStatus))
      this.separator()
      this.statusRow('livekit_status_network', DeviceStatusRowModel.network(this.presentation.status))
      Blank().height(12)
      Row() {
        ForEach([[`${this.presentation.status.delay}ms`, 'rtt'], [`${this.presentation.status.downLoss}%`, 'down_loss'],
          [`${this.presentation.status.upLoss}%`, 'up_loss']], (item: string[]) => {
          Column() {
            Text(item[0])
              .fontSize(20)
              .fontWeight(600)
              .fontColor(statusNormal)
              .textAlign(TextAlign.Center)
              .height(25)
              .margin({ top: 11 })
            Text(LiveKitResources.localizedString(`tuilivekit.pusher.status.${item[1]}`))
              .attributeModifier(
                new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.tertiary, TextAlign.Center))
              .fontColor(white(0.42))
              .maxLines(2)
              .constraintSize({ minHeight: 14 })
              .margin({ top: 6, bottom: 12 })
          }
          .layoutWeight(1)
        }, (item: string[]) => item[1])
      }
      .borderRadius(15)
      .borderWidth(1)
      .borderColor(PusherLiveStatusContentStyle.cardBorder)
      .backgroundColor(PusherLiveStatusContentStyle.cardBackground)
      .margin({ left: 18, right: 18 })

      Row({ space: 14 }) {
        this.streamColumn('video_info', 'video_fields', 55, 8, 3, this.presentation.status.videoInformation)
        this.streamColumn('audio_info', 'audio_fields', 52, 7, 2, this.presentation.status.audioInformation)
      }
      .height(112)
      .padding({ left: 15, right: 15 })
      .borderRadius(15)
      .borderWidth(1)
      .borderColor(PusherLiveStatusContentStyle.cardBorder)
      .backgroundColor(PusherLiveStatusContentStyle.cardBackground)
      .margin({
        left: 18,
        right: 18,
        top: 9,
        bottom: Math.max(26, this.safeBottom)
      })
    }
    .width('100%')
    .constraintSize({ minHeight: 515 })
  }
}
