import { LiveSummaryData } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveTheme, white } from '../../../common/theme/LiveTheme'
import { PusherLiveStatusContentStyle } from './PusherLiveStatusView'

class StatisticDescriptor {
  titleKey: string
  unitKey: string
  value: number

  constructor(titleKey: string, unitKey: string, value: number) {
    this.titleKey = titleKey
    this.unitKey = unitKey
    this.value = value
  }
}

@Component
export struct PusherLiveStatisticsView {
  @Prop data: LiveSummaryData = new LiveSummaryData()
  @Prop onlineCount: number = 0
  @Prop likeCount: number = 0

  private descriptors(): StatisticDescriptor[] {
    return [
      new StatisticDescriptor('metric.gift_score', 'unit.points', this.data.totalGiftCoins),
      new StatisticDescriptor('metric.gift_senders', 'unit.people', this.data.totalGiftUniqueSenders),
      new StatisticDescriptor('metric.gifts', 'unit.count', this.data.totalGiftsSent),
      new StatisticDescriptor('metric.online', 'unit.people', Math.max(0, this.onlineCount)),
      new StatisticDescriptor('metric.likes', 'unit.times', Math.max(0, this.likeCount)),
      new StatisticDescriptor('metric.messages', 'unit.messages', this.data.totalMessageSent),
    ]
  }

  @Builder
  statisticValue(descriptor: StatisticDescriptor) {
    Column() {
      Text(LiveKitResources.localizedString(`tuilivekit.pusher.status.${descriptor.titleKey}`))
        .attributeModifier(new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.tertiary))
        .maxLines(2)
        .width('100%')
        .height(32)
        .padding({ right: 4 })
      Row({ space: 5 }) {
        Text(`${descriptor.value}`)
          .fontSize(24)
          .fontWeight(600)
          .fontColor(white(0.96))
          .maxLines(1)
          .minFontSize(12)
          .maxFontSize(24)
          .flexShrink(1)
          .height(28)
        Text(LiveKitResources.localizedString(`tuilivekit.pusher.status.${descriptor.unitKey}`))
          .attributeModifier(new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.disabled))
          .height(13)
          .margin({ top: 12 })
      }
      .alignItems(VerticalAlign.Top)
      .margin({ top: 3 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .height(68)
  }

  build() {
    Column({ space: 12 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Text(LiveKitResources.localizedString('tuilivekit.pusher.status.realtime'))
          .attributeModifier(new LiveText(LiveTheme.TextRole.prominent))
          .height(23)
          .position({ x: 16, y: 18 })
        Text(LiveKitResources.localizedString('tuilivekit.pusher.status.cumulative'))
          .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.disabled, TextAlign.End))
          .height(15)
          .position({ right: 16, top: 21 })
        Column() {
          Divider().strokeWidth(0.5).color(PusherLiveStatusContentStyle.separator)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .position({ x: 0, y: 125 })

        ForEach([0, 3], (start: number) => {
          Row() {
            ForEach(this.descriptors().slice(start, start + 3), (descriptor: StatisticDescriptor) => {
              this.statisticValue(descriptor)
            }, (descriptor: StatisticDescriptor) => `${descriptor.titleKey}_${descriptor.value}`)
          }
          .width('100%')
          .padding({ left: 21, right: 21 })
          .position({ x: 0, y: 55 + start / 3 * 84 })
        }, (start: number) => `${start}`)
      }
      .width('100%')
      .height(232)
      .borderRadius(18)
      .borderWidth(1)
      .borderColor(PusherLiveStatusContentStyle.cardBorder)
      .backgroundColor(PusherLiveStatusContentStyle.cardBackground)

      Row({ space: 12 }) {
        Image(LiveKitResources.image('livekit_status_realtime')).width(34).height(34).objectFit(ImageFit.Contain)
        Column({ space: 5 }) {
          Text(LiveKitResources.localizedString('tuilivekit.pusher.status.updating'))
            .attributeModifier(new LiveText(LiveTheme.TextRole.action, LiveTheme.TextTone.secondary))
            .height(18)
          Text(LiveKitResources.localizedString('tuilivekit.pusher.status.update_detail'))
            .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.disabled))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .constraintSize({ minHeight: 64 })
      .padding({
        left: 15,
        right: 15,
        top: 13,
        bottom: 13
      })
      .borderRadius(15)
      .borderWidth(1)
      .borderColor(PusherLiveStatusContentStyle.cardBorder)
      .backgroundColor(PusherLiveStatusContentStyle.cardBackground)
    }
    .width('100%')
    .padding({ left: 18, right: 18 })
  }
}
