import { DeviceState, DeviceStore, NetworkQuality } from '@tencentcloud/atomicxcore'
import { RoomResources } from '../../../../base/util/RoomResources'

@Component
export struct RoomNetworkInfoPopup {
  @State private deviceState: DeviceState = DeviceStore.shared().state

  private statusTitle(): string {
    switch (this.deviceState.networkInfo.quality) {
      case NetworkQuality.excellent:
      case NetworkQuality.good:
        return RoomResources.string('roomkit_network_good')
      case NetworkQuality.poor:
        return RoomResources.string('roomkit_network_fair')
      case NetworkQuality.bad:
      case NetworkQuality.veryBad:
        return RoomResources.string('roomkit_network_weak')
      default:
        return RoomResources.string('roomkit_network_disconnected')
    }
  }

  private metricLevel(value: number, warn: number, bad: number): number {
    if (value >= bad) {
      return 2
    }
    return value >= warn ? 1 : 0
  }

  private valueColor(level: number): ResourceColor {
    if (level === 2) {
      return $r('app.color.roomkit_danger')
    }
    return level === 1 ? $r('app.color.roomkit_warning') : $r('app.color.roomkit_fg_primary')
  }

  @Builder
  metricCell(icon: string, label: string, value: number, unit: string, level: number) {
    Column({ space: 1 }) {
      Row({ space: 2 }) {
        if (icon.length > 0) {
          Image(RoomResources.image(icon))
            .width(8)
            .height(8)
            .opacity(0.72)
        }
        Text(label)
          .fontSize(10)
          .fontColor($r('app.color.roomkit_fg_tertiary'))
      }
      Row({ space: 2 }) {
        Text(`${Math.round(value)}`)
          .fontSize(13)
          .fontWeight(600)
          .fontColor(this.valueColor(level))
        Text(unit)
          .fontSize(10)
          .fontWeight(500)
          .fontColor($r('app.color.roomkit_fg_secondary'))
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10, left: 8, right: 8 })
    .backgroundColor($r('app.color.roomkit_bg_hover'))
    .borderRadius(8)
  }

  build() {
    Column() {
      Text(this.statusTitle())
        .width('100%')
        .padding({ top: 4, left: 16, right: 16 })
        .fontSize(15)
        .fontWeight(600)
        .fontColor($r('app.color.roomkit_fg_primary'))
      Row({ space: 8 }) {
        this.metricCell(
          '',
          RoomResources.string('roomkit_network_latency'),
          this.deviceState.networkInfo.delay,
          'ms',
          this.metricLevel(this.deviceState.networkInfo.delay, 100, 200),
        )
        this.metricCell(
          'roomkit_icon_dir_up_tertiary',
          RoomResources.string('roomkit_network_packet_loss'),
          this.deviceState.networkInfo.upLoss,
          '%',
          this.metricLevel(this.deviceState.networkInfo.upLoss, 2, 8),
        )
        this.metricCell(
          'roomkit_icon_dir_down_tertiary',
          RoomResources.string('roomkit_network_packet_loss'),
          this.deviceState.networkInfo.downLoss,
          '%',
          this.metricLevel(this.deviceState.networkInfo.downLoss, 2, 8),
        )
      }
      .width('100%')
      .padding({ top: 10, left: 16, right: 16, bottom: 20 })
    }
    .width('100%')
  }
}
