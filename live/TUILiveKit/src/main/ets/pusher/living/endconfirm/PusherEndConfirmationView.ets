import measure from '@ohos.measure'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { BottomSheetView } from '../../../common/theme/BottomSheetView'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveTheme, rgba, white } from '../../../common/theme/LiveTheme'

@Component
export struct PusherEndConfirmationView {
  @Prop isPresented: boolean = false
  @Prop viewerCount: number = 0
  onDismiss?: () => void
  onConfirmEnd?: () => void

  private buttonWidth(): number {
    const size = measure.measureText({
      textContent: LiveKitResources.localizedString('tuilivekit.pusher.end.continue'),
      fontSize: 15
    })
    return Math.max(108, Math.ceil(this.getUIContext().px2vp(size)) + 24)
  }

  private hasAudience(): boolean {
    return this.viewerCount > 0
  }

  @Builder
  actionButton(title: string, background: ResourceColor, isEnd: boolean, action: () => void) {
    Text(title)
      .fontSize(15)
      .fontColor(white(0.94))
      .textAlign(TextAlign.Center)
      .minFontSize(12.75)
      .maxFontSize(15)
      .maxLines(1)
      .width(this.buttonWidth())
      .height(44)
      .padding({ left: 12, right: 12 })
      .borderRadius(10)
      .backgroundColor(background)
      .shadow(isEnd ? { radius: 12, color: 'rgba(0,0,0,0.28)', offsetY: 4 } : { radius: 0, color: 'rgba(0,0,0,0)' })
      .onClick(action)
  }

  build() {
    BottomSheetView({
      isPresented: this.isPresented,
      sheetHeight: this.hasAudience() ? 250 : 210,
      onDismiss: () => this.onDismiss?.()
    }) {
      Stack({ alignContent: Alignment.Top }) {
        Column() {
          if (this.hasAudience()) {
            Text() {
              ForEach(LiveKitResources.localizedFormat('tuilivekit.pusher.end.audience_count', this.viewerCount)
                .split(`${this.viewerCount}`), (part: string, index: number) => {
                if (index > 0) {
                  Span(`${this.viewerCount}`)
                    .fontSize(23)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(rgba(0.557, 0.812, 1))
                }
                Span(part).fontSize(14).fontColor(white(0.76))
              })
            }
            .textAlign(TextAlign.Center)
            .textShadow({ radius: 14, color: LiveTheme.Color.brand(0.45) })
            .height(31)
            .margin({ top: 49 })

            Text(LiveKitResources.localizedString('tuilivekit.pusher.end.confirm'))
              .attributeModifier(
                new LiveText(LiveTheme.TextRole.sheetTitle, LiveTheme.TextTone.primary, TextAlign.Center))
              .height(24)
              .margin({ top: 14 })
          } else {
            Text(LiveKitResources.localizedString('tuilivekit.pusher.end.empty_audience'))
              .attributeModifier(new LiveText(LiveTheme.TextRole.body, LiveTheme.TextTone.secondary, TextAlign.Center))
              .padding({ left: 4, right: 4 })
              .margin({ top: 56 })
              .constraintSize({ maxHeight: 50 })
          }
        }

        Row({ space: 24 }) {
          this.actionButton(LiveKitResources.localizedString('tuilivekit.pusher.end.continue'), white(0.1), false,
            () => this.onDismiss?.())
          this.actionButton(LiveKitResources.localizedString('tuilivekit.pusher.end.end'), rgba(0.769, 0.267, 0.314),
            true,
            () => {
              this.onDismiss?.()
              this.onConfirmEnd?.()
            })
        }
        .position({ left: '50%', top: this.hasAudience() ? 153 : 118 })
        .translate({ x: '-50%' })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 24, right: 24 })
    }
  }
}
