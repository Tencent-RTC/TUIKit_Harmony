import { pusherVideoBottomInset } from '../video/PusherVideoView'
import { black } from '../../common/theme/LiveTheme'

@Component
export struct PusherPrepareGradientOverlayView {
  @State private viewHeight: number = 0

  private stageHeight(): number {
    return Math.max(0, this.viewHeight - pusherVideoBottomInset)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(this.stageHeight() * 337 / 732)
        .linearGradient({ angle: 180, colors: [[black(0.55), 0], [black(0.28), 0.4], [black(0), 1]] })
      Column()
        .width('100%')
        .height(this.stageHeight() * 307 / 732)
        .position({ x: 0, y: this.stageHeight() * 425 / 732 })
        .linearGradient({ angle: 180, colors: [[black(0), 0], [black(0.32), 0.62], [black(0.7), 1]] })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .onAreaChange((_: Area, area: Area) => this.viewHeight = area.height as number)
  }
}
