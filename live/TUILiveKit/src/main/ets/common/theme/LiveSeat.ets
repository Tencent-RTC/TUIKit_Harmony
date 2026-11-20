import { AnimatorResult, curves } from '@kit.ArkUI'
import { LiveKitResources } from '../LiveKitResources'
import { LiveText } from './LiveText'
import { black, LiveTheme, rgba, white } from './LiveTheme'

export const volumeWaveThreshold: number = 0

@Observed
export class LiveSeatState {
  name: string = ''
  avatarURL: string = ''
  microphoneOn: boolean = false
  isEmpty: boolean = true
  showsNoVideo: boolean = false
  showsOverlay: boolean = false
  volume: number = 0

  updateContent(name: string, avatarURL: string, microphoneOn: boolean): void {
    this.name = name
    this.avatarURL = avatarURL
    this.microphoneOn = microphoneOn
    if (!microphoneOn) this.volume = 0
  }

  updateVisibility(isEmpty: boolean, showsNoVideo: boolean, showsOverlay: boolean): void {
    this.isEmpty = isEmpty
    this.showsNoVideo = showsNoVideo
    this.showsOverlay = showsOverlay
  }

  updateVolume(volume: number): void {
    const value = this.microphoneOn ? Math.min(100, Math.max(0, volume)) : 0
    if (this.volume !== value) {
      this.volume = value
    }
  }
}

@Component
export struct LiveSeat {
  @ObjectLink seat: LiveSeatState
  emptyTitle: string = ''
  @State private seatWidth: number = 0
  @State private seatHeight: number = 0
  @State private waveProgress: number = 0
  private waveAnimator?: AnimatorResult
  private readonly waveCurve = curves.cubicBezierCurve(0.16, 0.5, 0.4, 1)

  aboutToDisappear(): void {
    this.stopWave()
  }

  private shortSide(): number {
    return Math.min(this.seatWidth, this.seatHeight)
  }

  private avatarSize(): number {
    // Shared logical-unit policy: leave room for the full wave and bottom nickname.
    const targetDiameter = Math.min(67, Math.max(42, this.shortSide() * 0.44))
    const waveSpace = Math.max(0, Math.min(this.seatWidth - 16, this.seatHeight - 32))
    const fittingDiameter = Math.max(0, waveSpace / 1.38 - 6)
    return Math.min(targetDiameter, fittingDiameter)
  }

  private showsWave(): boolean {
    return !this.seat.isEmpty && this.seat.showsNoVideo && this.seat.microphoneOn &&
      this.seat.volume > volumeWaveThreshold
  }

  private ringProgress(phaseOffset: number): number {
    return this.waveCurve.interpolate((this.waveProgress + phaseOffset) % 1)
  }

  private ringScale(phaseOffset: number): number {
    return 1 + 0.38 * this.ringProgress(phaseOffset)
  }

  private ringOpacity(phaseOffset: number): number {
    const progress = this.ringProgress(phaseOffset)
    if (progress <= 0) return 0
    if (progress < 0.14) return 0.78 * progress / 0.14
    if (progress < 0.7) return 0.78 + (0.22 - 0.78) * (progress - 0.14) / (0.7 - 0.14)
    if (progress < 1) return 0.22 * (1 - progress) / (1 - 0.7)
    return 0
  }

  @Builder
  waveRing(phaseOffset: number) {
    Circle()
      .width(this.avatarSize() + 4)
      .height(this.avatarSize() + 4)
      .fill(Color.Transparent)
      .stroke(white(0.9))
      .strokeWidth(2)
      .scale({ x: this.ringScale(phaseOffset), y: this.ringScale(phaseOffset) })
      .opacity(this.ringOpacity(phaseOffset))
      .onDisAppear(() => {
        if (phaseOffset === 0) this.stopWave()
      })
      .onAppear(() => {
        if (phaseOffset === 0) this.startWave()
      })
  }

  @Builder
  noVideoView() {
    Stack() {
      if (this.showsWave()) {
        this.waveRing(0)
        this.waveRing(0.5)
      }
      Image(this.seat.avatarURL.length > 0 ? this.seat.avatarURL :
        LiveKitResources.image('livekit_livelist_default_avatar'))
        .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
        .width(this.avatarSize())
        .height(this.avatarSize())
        .borderRadius(this.avatarSize() / 2)
        .objectFit(ImageFit.Cover)
    }
    .width('100%')
    .height('100%')
    .linearGradient(
      { direction: GradientDirection.RightBottom, colors: [[rgba(0.1, 0.18, 0.27), 0], [rgba(0.03, 0.06, 0.12), 1]] })
  }

  @Builder
  overlayView() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.seatWidth > 12 && this.seatHeight >= 14) {
        Column()
          .width('100%')
          .height(14)
          .position({ x: 0, y: this.seatHeight - 14 })
          .linearGradient({ angle: 180, colors: [[black(0), 0], [black(0.4), 1]] })
        Row() {
          Image(
            LiveKitResources.image(this.seat.microphoneOn ? 'livekit_coguest_seat_mic' : 'livekit_coguest_seat_muted'))
            .width(12)
            .height(12)
            .objectFit(ImageFit.Contain)
        }
        .width(Math.min(20, this.seatWidth - 12))
        .height(14)
        .borderRadius(7)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(black(0.32))
        .position({ x: 6, y: 6 })

        Text(this.seat.name)
          .fontSize(10)
          .fontColor(white(0.8))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(Math.max(0, this.seatWidth - 8))
          .height(14)
          .position({ x: 4, y: Math.max(0, this.seatHeight - 14) })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  emptyView() {
    Column({ space: 3 }) {
      Text('+')
        .fontSize(this.shortSide() - 2 <= 110 ? 29 : 26)
        .fontWeight(100)
        .fontColor(white(0.46))
        .height(this.shortSide() - 2 <= 110 ? 32 : 30)
      if (this.seatHeight - 2 >= (this.shortSide() - 2 <= 110 ? 32 : 30) + 17) {
        Text(this.emptyTitle)
          .attributeModifier(new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.tertiary, TextAlign.Center))
          .height(14)
      }
    }
    .width('100%')
    .height('100%')
    .margin(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(white(this.shortSide() - 2 <= 110 ? 0.055 : 0.035))
  }

  private startWave(): void {
    if (this.waveAnimator !== undefined || !this.showsWave()) return
    const context = this.getUIContext()
    const animation = context.createAnimator({
      duration: 1400,
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: -1,
      begin: 0,
      end: 1,
    })
    this.waveAnimator = animation
    this.waveProgress = 0
    animation.onFrame = (progress: number) => {
      context.runScopedTask(() => {
        if (this.waveAnimator !== animation) return
        if (!this.showsWave()) {
          this.stopWave()
          return
        }
        this.waveProgress = progress
      })
    }
    animation.play()
  }

  private stopWave(): void {
    const animation = this.waveAnimator
    this.waveAnimator = undefined
    animation?.cancel()
    this.waveProgress = 0
  }

  build() {
    Stack() {
      if (!this.seat.isEmpty && this.seat.showsNoVideo) {
        this.noVideoView()
      }
      if (!this.seat.isEmpty && this.seat.showsOverlay) {
        this.overlayView()
      }
      if (this.seat.isEmpty) {
        this.emptyView()
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
    .onAreaChange((_: Area, area: Area) => {
      this.seatWidth = area.width as number
      this.seatHeight = area.height as number
    })
  }
}

export enum LivingScrimDirection { top, bottom, horizontalCenter }

@Component
export struct LivingScrimView {
  scrimDirection: LivingScrimDirection = LivingScrimDirection.top
  build() {
    Column().width('100%').height('100%')
      .linearGradient({
        direction: this.scrimDirection === LivingScrimDirection.horizontalCenter ?
          GradientDirection.Right : GradientDirection.Bottom,
        colors: this.scrimDirection === LivingScrimDirection.horizontalCenter ?
          [['#00000000', 0], ['#85000000', 0.5], ['#00000000', 1]] :
          (this.scrimDirection === LivingScrimDirection.top ? [['#80000000', 0], ['#00000000', 1]] :
          [['#00000000', 0], ['#94000000', 1]])
      }).hitTestBehavior(HitTestMode.None)
  }
}
