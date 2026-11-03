import { MeasureUtils, UIContext } from '@kit.ArkUI'
import { PusherSummary } from '@tencentcloud/atomicxcore'
import { i18n, intl } from '@kit.LocalizationKit'
import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'

export class PusherSummaryContext {
  startTime?: Date
  endTime: Date = new Date()
  pausedSeconds: number = 0
  interruptionMessage?: string
}

function localized(key: string): string {
  return LiveKitResources.localizedString(`tuilivekit.pusher.summary.${key}`)
}

function formatTime(date: Date | undefined): string {
  if (date === undefined) {
    return '--:--'
  }
  return `${date.getHours()}`.padStart(2, '0') + ':' + `${date.getMinutes()}`.padStart(2, '0')
}

function durationText(duration: number): string {
  const seconds: number = Math.max(0, Math.floor(duration))
  const hours: number = Math.floor(seconds / 3600)
  const minutes: number = Math.floor(seconds / 60) % 60
  const remaining: number = seconds % 60
  const parts: string[] = []
  if (hours > 0) {
    parts.push(LiveKitResources.localizedFormat('tuilivekit.pusher.summary.duration.hours', hours))
  }
  if (minutes > 0) {
    parts.push(LiveKitResources.localizedFormat('tuilivekit.pusher.summary.duration.minutes', minutes))
  }
  if (remaining > 0 || parts.length === 0) {
    parts.push(LiveKitResources.localizedFormat('tuilivekit.pusher.summary.duration.seconds', remaining))
  }
  return parts.join('')
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

  private exitSummary(): void {
    if (this.context === undefined || this.didRequestExit) {
      return
    }
    this.didRequestExit = true
    this.onExit?.()
  }

  private timeDetails(): string {
    const duration: string = this.summary === undefined ? '--' : durationText(this.summary.liveDuration)
    return LiveKitResources.localizedFormat('tuilivekit.pusher.summary.time_details',
      formatTime(this.context?.startTime), formatTime(this.context?.endTime),
      LiveKitResources.localizedFormat('tuilivekit.pusher.summary.total_duration', duration))
  }

  @Builder
  informationLine(text: string) {
    Text(text)
      .fontSize(14)
      .fontWeight(400)
      .fontColor($r('app.color.tuilivekit_pusher_summary_secondary'))
      .lineHeight(22)
      .constraintSize({ minHeight: 22 })
      .width('100%')
      .textAlign(TextAlign.Start)
  }

  @Builder
  incomeCard() {
    Column() {
      SummaryMetricView({ titleKey: 'gift_value', unitKey: 'coins', value: this.summary?.totalGiftCoins,
        metricStyle: SummaryMetricStyle.income })
      Row().height(1).width('100%').backgroundColor($r('app.color.tuilivekit_pusher_summary_divider'))
      Row({ space: 16 }) {
        SummaryMetricView({ titleKey: 'gifts_received', unitKey: 'items', value: this.summary?.totalGiftsSent,
          metricStyle: SummaryMetricStyle.gift }).layoutWeight(1)
        SummaryMetricView({ titleKey: 'gift_senders', unitKey: 'people', value: this.summary?.totalUniqueGiftSenders,
          metricStyle: SummaryMetricStyle.gift }).layoutWeight(1)
      }
      .width('100%')
      .height(72)
    }
    .width('100%')
    .height(280)
    .padding(24)
    .justifyContent(FlexAlign.SpaceBetween)
    .borderRadius(20)
    .linearGradient({ direction: GradientDirection.RightBottom, colors: [
      [$r('app.color.tuilivekit_pusher_summary_income_start'), 0],
      [$r('app.color.tuilivekit_pusher_summary_income_end'), 1],
    ] })
  }

  @Builder
  interactionCard() {
    Column({ space: 20 }) {
      Text(localized('interaction_data'))
        .fontSize(15)
        .fontWeight(600)
        .fontColor($r('app.color.tuilivekit_pusher_summary_primary'))
        .width('100%')
        .height(22)
      Row({ space: 10 }) {
        SummaryMetricView({ titleKey: 'viewers', value: this.summary?.totalViewers }).layoutWeight(1)
        SummaryMetricView({ titleKey: 'comments', value: this.summary?.totalMessageCount }).layoutWeight(1)
        SummaryMetricView({ titleKey: 'likes', value: this.summary?.totalLikesReceived }).layoutWeight(1)
      }
      .width('100%')
      .height(70)
    }
    .width('100%')
    .padding(24)
    .borderRadius(20)
    .backgroundColor($r('app.color.tuilivekit_pusher_summary_interaction_background'))
  }

  build() {
    Column() {
      Row() {
        Stack() {
          Image(LiveKitResources.image('livekit_summary_back'))
            .width(44)
            .height(44)
            .objectFit(ImageFit.Contain)
        }
        .width(44)
        .height(44)
        .accessibilityText(localized('back'))
        .onClick(() => this.exitSummary())
        Text(localized('ended'))
          .fontSize(24)
          .fontWeight(600)
          .fontColor($r('app.color.tuilivekit_pusher_summary_primary'))
          .minFontSize(18)
          .maxFontSize(24)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .height(44)
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height(44)
      .padding({ left: 20, right: 20 })
      Blank().height(8)
      Scroll() {
        Column({ space: 24 }) {
          Column({ space: 4 }) {
            this.informationLine(this.timeDetails())
            if ((this.context?.pausedSeconds ?? 0) > 0) {
              this.informationLine(LiveKitResources.localizedFormat('tuilivekit.pusher.summary.pause_details',
                durationText(this.context?.pausedSeconds ?? 0)))
            }
            if ((this.context?.interruptionMessage ?? '').length > 0) {
              this.informationLine(this.context?.interruptionMessage ?? '')
            }
          }
          .width('100%')
          .padding({ left: 24 })
          this.incomeCard()
          this.interactionCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.safeTop + 8, bottom: this.safeBottom })
    .backgroundColor($r('app.color.tuilivekit_pusher_summary_background'))
  }
}

enum SummaryMetricStyle {
  income,
  gift,
  interaction,
}

class SummaryNumberFormats {
  // Immutable formatting helpers, not room/session state.
  static readonly locale: string = i18n.System.getAppPreferredLanguage()
  static readonly decimal: intl.NumberFormat = new intl.NumberFormat(SummaryNumberFormats.locale,
    { maximumFractionDigits: 0, useGrouping: true })
  static readonly compact: intl.NumberFormat = new intl.NumberFormat(SummaryNumberFormats.locale,
    { notation: 'compact', maximumSignificantDigits: 3 })
  static readonly scientific: intl.NumberFormat = new intl.NumberFormat(SummaryNumberFormats.locale,
    { notation: 'scientific', maximumFractionDigits: 2 })
}

class SummaryDisplayOption {
  text: string
  minimumWidth: number

  constructor(text: string, minimumWidth: number) {
    this.text = text
    this.minimumWidth = minimumWidth
  }
}

@Component
struct SummaryMetricView {
  @Prop titleKey: string = ''
  @Prop unitKey: string = ''
  @Prop @Watch('updateValue') value: number | undefined = undefined
  @Prop @Watch('updateValue') metricStyle: SummaryMetricStyle = SummaryMetricStyle.interaction
  @State private displayValue: string = '--'
  @State private fullValue: string = '--'
  private options: SummaryDisplayOption[] = []
  private availableWidth: number = 0

  aboutToAppear(): void {
    this.updateValue()
  }

  private valueSize(): number {
    return this.metricStyle === SummaryMetricStyle.income ? 48 : this.metricStyle === SummaryMetricStyle.gift ? 32 : 26
  }

  private valueHeight(): number {
    return this.metricStyle === SummaryMetricStyle.income ? 62 : this.metricStyle === SummaryMetricStyle.gift ? 40 : 38
  }

  private isIncome(): boolean {
    return this.metricStyle === SummaryMetricStyle.income
  }

  private caption(): string {
    const title: string = localized(this.titleKey)
    return this.unitKey.length === 0 ? title : LiveKitResources.localizedFormat(
      'tuilivekit.pusher.summary.metric_with_unit', title, localized(`unit.${this.unitKey}`))
  }

  private updateValue(): void {
    const value: number | undefined = this.value === undefined ? undefined : Math.max(0, this.value)
    const texts: string[] = []
    this.fullValue = value === undefined ? '--' : SummaryNumberFormats.decimal.format(value)
    texts.push(this.fullValue)
    if (value !== undefined) {
      texts.push(SummaryNumberFormats.compact.format(value))
      texts.push(SummaryNumberFormats.scientific.format(value))
    }
    const fontSize: number = this.valueSize()
    const uiContext: UIContext = this.getUIContext()
    const measurement: MeasureUtils = uiContext.getMeasureUtils()
    this.options = texts.map((text: string) => new SummaryDisplayOption(text,
      uiContext.px2vp(measurement.measureText({ textContent: text, fontSize: fontSize, fontWeight: 600 })) * 0.5))
    this.selectDisplayValue()
  }

  private selectDisplayValue(): void {
    if (this.options.length === 0) {
      return
    }
    const option: SummaryDisplayOption = this.availableWidth > 0 ?
      this.options.find((entry: SummaryDisplayOption) => entry.minimumWidth <= this.availableWidth) ??
      this.options[this.options.length - 1] : this.options[0]
    if (this.displayValue !== option.text) {
      this.displayValue = option.text
    }
  }

  @Builder
  captionLabel() {
    Text(this.caption())
      .fontSize(this.isIncome() ? 14 : 13)
      .fontWeight(400)
      .fontColor($r('app.color.tuilivekit_pusher_summary_secondary'))
      .minFontSize((this.isIncome() ? 14 : 13) * 0.75)
      .maxFontSize(this.isIncome() ? 14 : 13)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .height(this.isIncome() ? 20 : 24)
  }

  @Builder
  valueLabel() {
    Text(this.displayValue)
      .fontSize(this.valueSize())
      .fontWeight(600)
      .fontFeature('"tnum" 1')
      .fontColor(this.isIncome() ? $r('app.color.tuilivekit_pusher_summary_income') :
        $r('app.color.tuilivekit_pusher_summary_primary'))
      .minFontSize(this.valueSize() * 0.5)
      .maxFontSize(this.valueSize())
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .height(this.valueHeight())
  }

  build() {
    Column({ space: this.isIncome() ? 12 : 8 }) {
      if (this.isIncome()) {
        this.captionLabel()
        this.valueLabel()
      } else {
        this.valueLabel()
        this.captionLabel()
      }
    }
    .width('100%')
    .height(this.valueHeight() + (this.isIncome() ? 20 + 12 : 24 + 8))
    .accessibilityGroup(true)
    .accessibilityText(this.caption())
    .accessibilityDescription(this.fullValue)
    .onAreaChange((_: Area, area: Area) => {
      const width: number = area.width as number
      if (width !== this.availableWidth) {
        this.availableWidth = width
        this.selectDisplayValue()
      }
    })
  }
}
