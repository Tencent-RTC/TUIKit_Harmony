import { pusherVideoBottomInset } from '../video/PusherVideoView'
import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { rgba, white } from '../../common/theme/LiveTheme'

@Component
export struct CountdownView {
  @Prop @Watch('scheduleAnimation') number: number = 0
  onCancel?: () => void
  onReady?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private numberOpacity: number = 0
  @State private numberScale: number = 1.6
  private isLaidOut: boolean = false
  private animationTask: number = -1

  aboutToDisappear(): void {
    this.isLaidOut = false
    clearTimeout(this.animationTask)
  }

  private scheduleAnimation(): void {
    clearTimeout(this.animationTask)
    if (!this.isLaidOut) {
      return
    }
    // Start after the initial text layout has established its render node.
    this.animationTask = setTimeout(() => {
      this.animationTask = -1
      if (!this.isLaidOut || this.number <= 0) {
        return
      }
      this.show()
      this.onReady?.()
    }, 0)
  }

  private show(): void {
    if (this.number <= 0) {
      this.stopAnimation()
      return
    }
    this.numberOpacity = 0
    this.numberScale = 1.6
    this.getUIContext().keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: 180, curve: Curve.EaseOut, event: () => {
        this.numberOpacity = 1
        this.numberScale = 1
      }
      },
      { duration: 620, event: () => this.numberOpacity = 1 },
      {
        duration: 200, curve: Curve.EaseIn, event: () => {
        this.numberOpacity = 0
        this.numberScale = 0.85
      }
      },
    ])
  }

  stopAnimation(): void {
    this.numberOpacity = 0
    this.numberScale = 1
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height(pusherVideoBottomInset)
        .backgroundColor(rgba(0.04, 0.04, 0.06))
        .position({ left: 0, bottom: 0 })
        .hitTestBehavior(HitTestMode.None)
      Column()
        .width(150)
        .height(150)
        .borderRadius(75)
        .backgroundColor(white(0.16))
        .margin({ bottom: pusherVideoBottomInset })
      Text(`${this.number}`)
        .fontSize(96)
        .fontWeight(300)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(150)
        .height(140)
        .margin({ bottom: pusherVideoBottomInset })
        .textShadow({ radius: 12, color: 'rgba(0,0,0,0.5)', offsetY: 4 })
        .opacity(this.numberOpacity)
        .scale({ x: this.numberScale, y: this.numberScale })
        .onAreaChange((_: Area, area: Area) => {
          if (!this.isLaidOut && Number(area.width) > 0 && Number(area.height) > 0) {
            this.isLaidOut = true
            this.scheduleAnimation()
          }
        })
      Text(LiveKitResources.localizedString('tuilivekit.common.cancel'))
        .fontSize(16)
        .fontColor(white(0.92))
        .textAlign(TextAlign.Center)
        .width(200)
        .height(50)
        .borderRadius(14)
        .backgroundColor(rgba(0.15, 0.15, 0.17, 0.86))
        .position({ left: '50%', bottom: this.safeBottom + 8 })
        .translate({ x: -100 })
        .onClick(() => this.onCancel?.())
    }
    .width('100%')
    .height('100%')
  }
}
