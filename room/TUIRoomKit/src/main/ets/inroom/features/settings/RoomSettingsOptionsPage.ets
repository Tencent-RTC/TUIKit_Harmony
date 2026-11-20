import { DeviceState, DeviceStore, VideoQuality } from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../base/util/RoomResources'
import { RoomSafeArea } from '../../../base/util/RoomSafeArea'
import { RoomSettingsNavBar, RoomSettingsRow, RoomSettingsRowStyle } from './RoomSettingsPage'

export function roomVideoQualityDisplayName(quality: VideoQuality): string {
  switch (quality) {
    case VideoQuality.quality1080P:
      return RoomResources.string('roomkit_settings_quality1080_p')
    case VideoQuality.quality540P:
      return RoomResources.string('roomkit_settings_quality540_p')
    case VideoQuality.quality360P:
      return RoomResources.string('roomkit_settings_quality360_p')
    default:
      return RoomResources.string('roomkit_settings_quality720_p')
  }
}

@Component
export struct RoomSettingsOptionsPage {
  onBack?: () => void
  @State private deviceState: DeviceState = DeviceStore.shared().state
  private backTimer: number = -1
  private readonly qualities: VideoQuality[] = [
    VideoQuality.quality1080P,
    VideoQuality.quality720P,
    VideoQuality.quality540P,
    VideoQuality.quality360P,
  ]

  aboutToAppear(): void {
    RoomSafeArea.observe()
  }

  aboutToDisappear(): void {
    clearTimeout(this.backTimer)
    RoomSafeArea.stopObserving()
  }

  private select(quality: VideoQuality): void {
    if (quality !== this.deviceState.localVideoQuality) {
      DeviceStore.shared().updateVideoQuality(quality)
    }
    clearTimeout(this.backTimer)
    this.backTimer = setTimeout(() => {
      this.onBack?.()
    }, 180)
  }

  build() {
    Column() {
      RoomSettingsNavBar({
        title: RoomResources.string('roomkit_settings_resolution'),
        onBack: () => this.onBack?.(),
      })
      Scroll() {
        Column() {
          Column() {
            ForEach(this.qualities, (quality: VideoQuality, index: number) => {
              RoomSettingsRow({
                style: RoomSettingsRowStyle.OPTION,
                title: roomVideoQualityDisplayName(quality),
                isChecked: quality === this.deviceState.localVideoQuality,
                showsSeparator: index > 0,
                onTap: () => this.select(quality),
              })
            })
          }
          .backgroundColor($r('app.color.roomkit_bg_surface'))
          .borderRadius(12)
          .clip(true)
          .margin({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.roomkit_bg_canvas'))
  }
}
