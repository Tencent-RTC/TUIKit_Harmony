import { LiveKitResources, LiveKitSafeArea } from '../../../common/LiveKitResources'
import { black } from '../../../common/theme/LiveTheme'

@Component
export struct PusherPauseOverlayView {
  @Prop seconds: number = 0
  onResume?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private viewHeight: number = 0

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Text(LiveKitResources.localizedString('tuilivekit.pusher.living.paused'))
          .fontSize(21)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .height(29)
        Text(`${Math.floor(this.seconds / 60).toString().padStart(2, '0')}:${(this.seconds % 60).toString().padStart(2, '0')}`)
          .fontSize(36)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .height(37)
          .margin({ top: 21 })
      }
      .width('100%')
      .height(87)
      .margin({ top: this.viewHeight * 273 / 844 })
      Text(LiveKitResources.localizedString('tuilivekit.pusher.living.resume'))
        .fontSize(17)
        .fontWeight(600)
        .fontColor('rgba(17, 17, 17, 1)')
        .textAlign(TextAlign.Center)
        .width(205)
        .height(48)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .shadow({ radius: 28, color: 'rgba(0,0,0,0.28)', offsetY: 8 })
        .position({ left: '50%', bottom: this.safeBottom + 42 })
        .translate({ x: -102.5 })
        .onClick(() => this.onResume?.())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(black(0.9))
    .onAreaChange((_: Area, area: Area) => this.viewHeight = area.height as number)
  }
}
