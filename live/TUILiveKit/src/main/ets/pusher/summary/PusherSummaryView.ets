import { PusherSummary } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { black, LiveTheme, rgba, white } from '../../common/theme/LiveTheme'
import { formatPusherDuration } from '../living/status/PusherLiveStatusView'

export class PusherSummaryContext {
  startTime?: Date
  endTime: Date = new Date()
  pausedSeconds: number = 0
  interruptionMessage?: string
}

class StatCard {
  titleKey: string
  unitKey: string
  accentColor: string

  constructor(titleKey: string, unitKey: string, accentColor: string) {
    this.titleKey = titleKey
    this.unitKey = unitKey
    this.accentColor = accentColor
  }
}

const statCards: StatCard[] = [
  new StatCard('gifts_received', 'unit.items', rgba(0.941, 0.737, 0.373)),
  new StatCard('gift_value', 'unit.coins', rgba(1, 0.431, 0.616)),
  new StatCard('viewers', 'unit.people', rgba(0.412, 0.659, 1)),
  new StatCard('comments', 'unit.messages', rgba(0.745, 0.514, 1)),
  new StatCard('gift_senders', 'unit.people', rgba(0.341, 0.835, 0.749)),
  new StatCard('likes', 'unit.times', rgba(1, 0.482, 0.447)),
]

function localized(key: string): string {
  return LiveKitResources.localizedString(`tuilivekit.pusher.summary.${key}`)
}

function formatTime(date: Date): string {
  return `${date.getHours()}`.padStart(2, '0') + ':' + `${date.getMinutes()}`.padStart(2, '0')
}

@Component
export struct PusherSummaryView {
  @Prop context: PusherSummaryContext | undefined = undefined
  @Prop summary: PusherSummary | undefined = undefined
  onExit?: () => void
  @StorageProp(LiveKitSafeArea.topKey) safeTop: number = 0
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  private didRequestExit: boolean = false

  aboutToAppear(): void {
    this.didRequestExit = false
  }

  private values(): (number | undefined)[] {
    const summary = this.summary
    if (summary === undefined) {
      return [undefined, undefined, undefined, undefined, undefined, undefined]
    }
    return [summary.totalGiftsSent, summary.totalGiftCoins, summary.totalViewers, summary.totalMessageCount,
      summary.totalUniqueGiftSenders, summary.totalLikesReceived].map((value: number) => Math.max(0, value))
  }

  private exitSummary(): void {
    if (this.context === undefined || this.didRequestExit) {
      return
    }
    this.didRequestExit = true
    this.onExit?.()
  }

  @Builder
  heroLabel(text: string, top: number, height: number, size: number, weight: number, color: string) {
    Text(text)
      .fontSize(size)
      .fontWeight(weight)
      .fontColor(color)
      .textAlign(TextAlign.Center)
      .width('100%')
      .height(height)
      .padding({ left: 40, right: 40 })
      .position({ x: 0, y: top })
  }

  @Builder
  heroCard() {
    Stack({ alignContent: Alignment.Top }) {
      this.heroAccent()
      Column()
        .width(60)
        .height(60)
        .borderRadius(30)
        .backgroundColor(LiveTheme.Color.brand(0.08))
        .margin({ top: 13 })
      Stack() {
        Image(LiveKitResources.image('livekit_summary_done')).width(22).height(18).objectFit(ImageFit.Contain)
          .margin({ top: 2 })
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .borderWidth(1)
      .borderColor(LiveTheme.Color.brandBlue)
      .backgroundColor(rgba(0.098, 0.243, 0.42))
      .shadow({ radius: 22, color: LiveTheme.Color.brand(0.22), offsetY: 8 })
      .margin({ top: 19 })

      this.heroLabel(localized('ended'), 80, 27, 19, 700, white(0.95))
      Text(`${this.context?.startTime === undefined ? '--:--' : formatTime(this.context.startTime)} ~ ${formatTime(
        this.context?.endTime ?? new Date())}`)
        .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.tertiary, TextAlign.Center))
        .width('100%')
        .height(16)
        .padding({ left: 40, right: 40 })
        .position({ x: 0, y: 111 })
      this.heroLabel(localized('duration'), 146, 14, 10, 600, white(0.48))
      Text(this.summary === undefined ? '--' : formatPusherDuration(Math.max(0, this.summary.liveDuration)))
        .fontSize(30)
        .fontWeight(700)
        .fontColor(rgba(0.557, 0.812, 1))
        .textAlign(TextAlign.Center)
        .textShadow({ radius: 20, color: LiveTheme.Color.brand(0.34) })
        .width('100%')
        .height(40)
        .padding({ left: 40, right: 40 })
        .position({ x: 0, y: 165 })
      if ((this.context?.pausedSeconds ?? 0) !== 0) {
        Row() {
          Text(localized('paused_duration'))
            .fontSize(10)
            .fontColor(white(0.48))
            .constraintSize({ minWidth: 54 })
            .height(14)
          Blank().width(7)
          Text(formatPusherDuration(this.context?.pausedSeconds ?? 0))
            .attributeModifier(
              new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.secondary, TextAlign.End, true))
            .width(55)
            .height(14)
        }
        .height(27)
        .padding({ left: 11, right: 11 })
        .borderRadius(13.5)
        .borderWidth(1)
        .borderColor(white(0.07))
        .backgroundColor(white(0.045))
        .margin({ top: 211 })
        .constraintSize({ minWidth: 138 })
      }
    }
    .width('100%')
    .height(250)
    .borderRadius(22)
    .borderWidth(1)
    .borderColor(white(0.085))
    .linearGradient({ direction: GradientDirection.Bottom, colors: [[white(0.065), 0], [white(0.025), 1]] })
    .shadow({ radius: 42, color: black(0.22), offsetY: 18 })
  }

  @Builder
  heroAccent() {
    Column()
      .width('100%')
      .height(250)
      .borderRadius(22)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [[LiveTheme.Color.brand(0.13), 0], [LiveTheme.Color.brand(0.035), 0.38],
          [LiveTheme.Color.brand(0), 0.75]],
      })
      .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  statCard(card: StatCard, value: number | undefined) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [[`${card.accentColor.slice(0, -2)}0)`, 0], [`${card.accentColor.slice(0, -2)}0)`, 0.28],
            [`${card.accentColor.slice(0, -2)}0.085)`, 1]],
        })
      Column()
        .width(16)
        .height(4)
        .borderRadius(2)
        .backgroundColor(card.accentColor)
        .shadow({ radius: 9, color: card.accentColor })
        .position({ x: 13, y: 13 })
      Text(localized(card.titleKey))
        .attributeModifier(
          new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.tertiary, TextAlign.Start, true))
        .height(14)
        .padding({ right: 26 })
        .position({ x: 13, y: 26 })
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Baseline }) {
        Text(value === undefined ? '--' : `${value}`)
          .fontSize(23)
          .fontWeight(700)
          .fontColor(white(0.94))
          .maxLines(1)
          .minFontSize(11.5)
          .maxFontSize(23)
          .flexShrink(1)
        Text(localized(card.unitKey))
          .attributeModifier(new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.disabled))
          .margin({ left: 5 })
      }
      .height(31)
      .width('calc(100% - 26vp)')
      .position({ x: 13, y: 45 })
    }
    .layoutWeight(1)
    .height('100%')
    .borderRadius(16)
    .borderWidth(1)
    .borderColor(white(0.065))
    .linearGradient({ direction: GradientDirection.Right, colors: [[white(0.055), 0], [white(0.022), 1]] })
    .clip(true)
  }

  build() {
    Stack() {
      Image(LiveKitResources.image('livekit_summary_bg')).width('100%').height('100%').objectFit(ImageFit.Cover)
      Scroll() {
        Column() {
          Stack({ alignContent: Alignment.TopStart }) {
            Stack() {
              Image(LiveKitResources.image('livekit_summary_back'))
                .width(21)
                .height(21)
                .objectFit(ImageFit.Contain)
            }
            .width(38)
            .height(38)
            .position({ x: 12, y: 14 })
            .onClick(() => this.exitSummary())

            Text(this.context?.interruptionMessage ?? localized('statistics'))
              .fontSize(15)
              .fontWeight(600)
              .fontColor(white(0.9))
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .width('100%')
              .constraintSize({ maxHeight: 42 })
              .padding({ left: 80, right: 80 })
              .position({ x: 0, y: 14 })
              .height(38)
              .hitTestBehavior(HitTestMode.None)
          }
          .width('100%')
          .height(58)
          .margin({ top: Math.max(34, this.safeTop) })

          Column() {
            this.heroCard()
          }
          .padding({ left: 16, right: 16 })
          .margin({ top: 10 })

          Text(localized('session_data'))
            .fontSize(15)
            .fontWeight(600)
            .fontColor(white(0.9))
            .width(170)
            .height(21)
            .alignSelf(ItemAlign.Start)
            .margin({ left: 19, top: 20 })
          Column({ space: 10 }) {
            ForEach([0, 2, 4], (start: number) => {
              Row({ space: 10 }) {
                this.statCard(statCards[start], this.values()[start])
                this.statCard(statCards[start + 1], this.values()[start + 1])
              }
              .width('100%')
              .layoutWeight(1)
            }, (start: number) => `${start}_${this.values()[start]}_${this.values()[start + 1]}`)
          }
          .height(284)
          .padding({ left: 16, right: 16 })
          .margin({ top: 6, bottom: 20 + this.safeBottom })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}
