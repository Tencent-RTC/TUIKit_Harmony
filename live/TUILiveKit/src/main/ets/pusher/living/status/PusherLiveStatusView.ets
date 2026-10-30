import { LiveSummaryData, LiveSummaryState, LiveSummaryStore } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveTheme, white } from '../../../common/theme/LiveTheme'
import { Presentation, PusherDeviceStatusView } from './PusherDeviceStatusView'
import { PusherLiveStatisticsView } from './PusherLiveStatisticsView'

const designHeight: number = 656

export function formatPusherDuration(seconds: number): string {
  const pad = (value: number) => `${Math.floor(value)}`.padStart(2, '0')
  return `${pad(seconds / 3600)}:${pad(seconds % 3600 / 60)}:${pad(seconds % 60)}`
}

export class PusherLiveStatusContentStyle {
  static readonly separator: string = white(0.065)
  static readonly cardBackground: string = white(0.02)
  static readonly cardBorder: string = white(0.07)
}

enum ContentCategory {
  realtimeStatistics,
  deviceStatus,
}

@Component
export struct PusherLiveStatusView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  @Prop liveID: string = ''
  @Prop elapsedSeconds: number = 0
  @Prop onlineCount: number = 0
  @Prop likeCount: number = 0
  @Prop devicePresentation: Presentation = new Presentation()
  onDismiss?: () => void
  onSetCaptureVolume?: (volume: number) => void
  @StorageProp(LiveKitSafeArea.topKey) safeTop: number = 0
  @State private category: ContentCategory = ContentCategory.realtimeStatistics
  @State private summaryData: LiveSummaryData = new LiveSummaryData()
  @State private containerHeight: number = 0
  @State @Watch('onSummaryChanged') private observedSummary: LiveSummaryState = new LiveSummaryState()

  aboutToAppear(): void {
    this.onPresentedChanged()
  }

  aboutToDisappear(): void {
    this.stopObservingStatistics()
  }

  private sheetHeight(): number {
    return this.containerHeight > 0 ? Math.min(designHeight, this.containerHeight - this.safeTop) : designHeight
  }

  private onPresentedChanged(): void {
    if (this.isPresented) {
      this.category = ContentCategory.realtimeStatistics
      this.startObservingStatistics()
    }
  }

  private startObservingStatistics(): void {
    if (this.liveID.length === 0) {
      return
    }
    this.observedSummary = LiveSummaryStore.create(this.liveID).liveSummaryState
    this.summaryData = this.observedSummary.summaryData
  }

  private stopObservingStatistics(): void {
    this.observedSummary = new LiveSummaryState()
  }

  private onSummaryChanged(): void {
    if (this.isPresented) {
      this.summaryData = this.observedSummary.summaryData
    }
  }

  @Builder
  categoryButton(titleKey: string, category: ContentCategory) {
    Text(LiveKitResources.localizedString(titleKey))
      .fontSize(14)
      .fontColor(white(this.category === category ? 1 : 0.5))
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(38)
      .borderRadius(11)
      .borderWidth(1)
      .borderColor(this.category === category ? LiveTheme.Color.brand(0.35) : Color.Transparent)
      .backgroundColor(this.category === category ? 'rgba(105, 175, 255, 0.303)' : Color.Transparent)
      .onClick(() => this.category = category)
  }

  build() {
    Stack() {
      BottomSheetView({
        isPresented: this.isPresented,
        sheetHeight: this.sheetHeight(),
        onDismiss: () => this.onDismiss?.(),
        sheetWillDismiss: () => this.stopObservingStatistics(),
      }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Text(LiveKitResources.localizedString('tuilivekit.pusher.status.title'))
            .attributeModifier(new LiveText(LiveTheme.TextRole.pageTitle))
            .height(28)
            .position({ x: 26, y: 40 })
          Row({ space: 0 }) {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(LiveTheme.Color.brandBlue)
              .margin({ right: -3 })
            Text(formatPusherDuration(this.elapsedSeconds))
              .fontSize(12)
              .fontFeature('"tnum" on')
              .fontColor('rgba(230, 230, 230, 1)')
              .textAlign(TextAlign.Center)
              .width(79)
              .height(24)
          }
          .position({ right: 16, top: 41 })

          Row({ space: 4 }) {
            this.categoryButton('tuilivekit.pusher.status.realtime', ContentCategory.realtimeStatistics)
            this.categoryButton('tuilivekit.pusher.status.device', ContentCategory.deviceStatus)
          }
          .width('calc(100% - 36vp)')
          .height(46)
          .padding(4)
          .borderRadius(14)
          .backgroundColor(white(0.06))
          .position({ x: 18, y: 81 })

          Scroll() {
            if (this.category === ContentCategory.realtimeStatistics) {
              PusherLiveStatisticsView(
                { data: this.summaryData, onlineCount: this.onlineCount, likeCount: this.likeCount })
                .constraintSize({ minHeight: 515 })
                .align(Alignment.Top)
            } else {
              PusherDeviceStatusView({
                presentation: this.devicePresentation,
                onSetCaptureVolume: (volume: number) => this.onSetCaptureVolume?.(volume),
              })
            }
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None)
          .align(Alignment.Top)
          .width('100%')
          .height(this.sheetHeight() - 141)
          .position({ x: 0, y: 141 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .onAreaChange((_: Area, area: Area) => this.containerHeight = area.height as number)
  }
}
