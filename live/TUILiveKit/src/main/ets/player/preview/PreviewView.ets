import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources, LiveKitSafeArea } from '../../common/LiveKitResources'
import { white } from '../../common/theme/LiveTheme'

const barCount: number = 3
const barWidth: number = 2
const barBaseHeight: number = 4
const barAmplitude: number = 11
const barSpacing: number = 3

@Component
export struct EntranceAnimationView {
  @Prop @Watch('updateAnimationState') isAnimating: boolean = false
  @State private progress: number = 0
  private timer: number = -1
  private animationStart: number = 0

  aboutToAppear(): void {
    this.updateAnimationState()
  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  private updateAnimationState(): void {
    clearInterval(this.timer)
    this.timer = -1
    if (!this.isAnimating) {
      this.progress = 0
      return
    }
    this.animationStart = Date.now()
    this.timer = setInterval(() => {
      const t = ((Date.now() - this.animationStart) / 1000) % 2
      this.progress = t <= 1 ? t : 2 - t
    }, 16)
  }

  private barHeight(index: number): number {
    const adjusted = (this.progress + index * 0.6) % 1
    return barBaseHeight + Math.abs(Math.sin((adjusted < 0 ? adjusted + 1 : adjusted) * Math.PI)) * barAmplitude
  }

  build() {
    Row({ space: barSpacing }) {
      ForEach(Array.from<number>({ length: barCount }).map((_: number, index: number) => index), (index: number) => {
        Column().width(barWidth).height(this.barHeight(index)).borderRadius(1).backgroundColor(Color.White)
      }, (index: number) => `${index}`)
    }
    .width(15)
    .height(15)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct PreviewView {
  @Prop liveInfo: LiveInfo
  @Prop isEnabled: boolean = true
  @Prop isShowing: boolean = false
  onTapEnter?: () => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row({ space: 8 }) {
        EntranceAnimationView({ isAnimating: this.isShowing })
        Text(LiveKitResources.localizedString('tuilivekit.player.enter_room_hint'))
          .fontSize(14)
          .fontColor(Color.White)
          .maxLines(1)
      }
      .height(40)
      .padding({ left: 25, right: 25 })
      .borderRadius(20)
      .borderWidth(0.3)
      .borderColor(Color.White)
      .backgroundColor(white(0.14))
      .margin({ left: 24, right: 24, bottom: this.safeBottom + 234 })
      .enabled(this.isEnabled)
      .onClick(() => this.onTapEnter?.())
      Column({ space: 5 }) {
        Text(this.liveInfo.liveName.length === 0 ? this.liveInfo.liveID : this.liveInfo.liveName)
          .fontSize(20)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 8 }) {
          Image(this.liveInfo.liveOwner.avatarURL)
            .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
            .width(24)
            .height(24)
            .borderRadius(12)
            .objectFit(ImageFit.Cover)
          Text(this.liveInfo.liveOwner.userName.length === 0 ? this.liveInfo.liveOwner.userID : this.liveInfo.liveOwner.userName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(white(0.55))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .flexShrink(1)
        }
        .margin({ bottom: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20, right: 20 })
      .margin({ bottom: this.safeBottom + 34 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
