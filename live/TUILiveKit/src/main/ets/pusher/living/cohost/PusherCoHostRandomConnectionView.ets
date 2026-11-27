import { AnimatorResult, curves } from '@kit.ArkUI'
import { image } from '@kit.ImageKit'
import { LiveKitResources } from '../../../common/LiveKitResources'
import { LiveKitLog } from '../../../common/log/LiveKitLog'
import { LiveToast } from '../../../common/theme/LiveToastView'
import { CoHostUser } from './PusherCoHostStore'

class RadarPoint {
  x: number
  y: number
  size: number
  constructor(x: number, y: number, size: number) { this.x = x; this.y = y; this.size = size }
}

@Component
struct CoHostRadarSweep {
  @Prop angle: number = 0
  private readonly context: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private generation: number = 0
  private bitmap?: image.PixelMap

  aboutToDisappear(): void {
    this.generation++
    this.bitmap?.release()
    this.bitmap = undefined
  }

  private async draw(): Promise<void> {
    const host = this.getUIContext().getHostContext()
    if (!host) return
    const generation = ++this.generation
    let source: image.ImageSource | undefined = undefined
    let bitmap: image.PixelMap | undefined = undefined
    try {
      const bytes = await host.resourceManager.getMediaContent($r('app.media.livekit_cohost_radar_sweep'))
      source = image.createImageSource(bytes.buffer as ArrayBuffer)
      bitmap = await source.createPixelMap()
      if (generation !== this.generation) return
      // The 136 x 142 export has its scan center at (68, 74), including glow padding.
      // A 202 square contains its entire rotating canvas, including all four corners.
      this.context.clearRect(0, 0, 202, 202)
      this.context.drawImage(bitmap, 33, 27, 136, 142)
      this.context.globalCompositeOperation = 'destination-out'
      this.context.beginPath()
      this.context.arc(101, 101, 20.5, 0, Math.PI * 2)
      this.context.fill()
      this.context.globalCompositeOperation = 'source-over'
      this.bitmap?.release()
      this.bitmap = bitmap
      bitmap = undefined
    } catch (error) {
      if (generation === this.generation) LiveKitLog.error('[CoHostRadar] sweep image rendering failed')
    } finally {
      if (bitmap) await bitmap.release()
      if (source) await source.release()
    }
  }

  build() {
    Canvas(this.context).width(202).height(202)
      .rotate({ x: 0, y: 0, z: 1, angle: this.angle, centerX: 101, centerY: 101 })
      .onReady(() => this.draw())
      .hitTestBehavior(HitTestMode.None)
  }
}

@Component
struct CoHostRadar {
  @Prop @Watch('updateAnimation') active: boolean = false
  @Prop hostAvatar: string = ''
  @Prop @Watch('updateURLs') candidates: CoHostUser[] = []
  @State private elapsed: number = 0
  @State private urls: string[] = []
  private scanAnimator?: AnimatorResult
  private laidOut: boolean = false
  private startTask: number = -1
  private points: RadarPoint[] = [new RadarPoint(51, 17, 18), new RadarPoint(129, 45, 16),
    new RadarPoint(56, 72, 15), new RadarPoint(104, 12, 16), new RadarPoint(105, 74, 17)]
  private readonly easeOut: ICurve = curves.cubicBezierCurve(0, 0, 0.58, 1)
  private readonly keyTimes: number[] = [0, 0.04, 0.08, 0.22, 0.42, 1]
  private readonly opacities: number[] = [0, 1, 0.92, 0.92, 0, 0]
  private readonly saturations: number[] = [0.55, 1, 1, 1, 0.65, 0.65]
  private readonly brightnesses: number[] = [0.8, 1.2, 1.08, 1.08, 0.85, 0.85]
  private readonly scales: number[] = [0.72, 1.08, 1, 1, 0.96, 0.96]
  aboutToAppear(): void {
    this.randomize()
    this.updateURLs()
  }
  aboutToDisappear(): void {
    this.stop()
    this.laidOut = false
  }
  private stop(): void {
    clearTimeout(this.startTask)
    this.scanAnimator?.cancel()
    this.scanAnimator = undefined
    this.elapsed = 0
  }
  private updateAnimation(): void {
    this.stop()
    if (!this.active || !this.laidOut) return
    this.startTask = setTimeout(() => {
      if (!this.active || !this.laidOut) return
      const animation = this.getUIContext().createAnimator({ duration: 33600, iterations: -1,
        easing: 'linear', begin: 0, end: 33600, fill: 'forwards', delay: 0, direction: 'normal' })
      this.scanAnimator = animation
      animation.onFrame = (time: number) => {
        if (this.scanAnimator === animation && this.active) {
          this.getUIContext().runScopedTask(() => this.elapsed = time)
        }
      }
      animation.play()
    }, 0)
  }
  private randomize(): void {
    for (let attempt = 0; attempt < 8; attempt++) {
      const points: RadarPoint[] = []
      const sizes: number[] = [18, 16, 15, 16, 17]
      for (let index = 0; index < sizes.length; index++) {
        const size = sizes[index]
        const radius = size * 1.08 / 2
        for (let sample = 0; sample < 160; sample++) {
          const x = 33 + radius + 6 + Math.random() * (112 - radius * 2 - 10)
          const y = radius + 3 + Math.random() * (84 - radius * 2 - 6)
          const distance = Math.hypot(x - 89, y - 42)
          if (distance < 17 + radius + 5 || distance > 54 || points.some((point: RadarPoint) =>
            Math.hypot(x - point.x, y - point.y) < radius + point.size * 1.08 / 2 + 6)) continue
          points.push(new RadarPoint(x, y, size))
          break
        }
        if (points.length !== index + 1) break
      }
      if (points.length === 5) { this.points = points; return }
    }
  }
  private peerTime(point: RadarPoint): number {
    const phase = (Math.atan2(point.x - 89, 42 - point.y) / (Math.PI * 2) + 1) % 1
    const time = this.elapsed / 4800 - phase
    return time < 0 ? 0 : time % 1
  }
  private value(time: number, values: number[]): number {
    for (let i = 1; i < this.keyTimes.length; i++) {
      if (time <= this.keyTimes[i]) {
        const t = this.easeOut.interpolate((time - this.keyTimes[i - 1]) / (this.keyTimes[i] - this.keyTimes[i - 1]))
        return values[i - 1] + (values[i] - values[i - 1]) * t
      }
    }
    return values[values.length - 1]
  }
  private pulseTime(index: number): number { return Math.max(0, this.elapsed - index * 1400) % 2800 / 2800 }
  private updateURLs(): void {
    const seen = new Set<string>()
    this.urls = this.candidates.filter((user: CoHostUser) => {
      if (seen.has(user.userID)) return false
      seen.add(user.userID)
      return true
    }).slice(0, 5).map((user: CoHostUser) => user.avatarURL)
  }
  private pulseProgress(index: number): number {
    return this.easeOut.interpolate(Math.min(1, this.pulseTime(index) / 0.76))
  }
  private pulseColor(index: number): string {
    const progress = this.pulseProgress(index)
    return `rgba(${Math.round(255 - 129 * progress)},${Math.round(255 - 23 * progress)},255,${0.82 - 0.74 * progress})`
  }
  @Builder
  pulse(index: number) {
    Circle().width(34).height(34).fill(Color.Transparent).stroke(this.pulseColor(index)).strokeWidth(1)
      .position({ x: 72, y: 25 })
      .scale({ x: 0.95 + this.pulseProgress(index) * 0.95,
        y: 0.95 + this.pulseProgress(index) * 0.95 })
      .opacity(this.elapsed < index * 1400 ? 0 : 0.68 * (1 - this.pulseProgress(index)))
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.active) {
        this.pulse(0)
        this.pulse(1)
        CoHostRadarSweep({ angle: this.elapsed % 4800 / 4800 * 360 })
          .position({ x: -12, y: -59 })
        ForEach(this.points, (point: RadarPoint, index: number) => {
          Image(this.urls[index] || LiveKitResources.image('livekit_livelist_default_avatar'))
            .alt(LiveKitResources.image('livekit_livelist_default_avatar')).objectFit(ImageFit.Cover)
            .width(point.size).height(point.size).borderRadius(point.size / 2).clip(true)
            .position({ x: point.x - point.size / 2, y: point.y - point.size / 2 })
            .opacity(this.value(this.peerTime(point), this.opacities))
            .scale({ x: this.value(this.peerTime(point), this.scales),
              y: this.value(this.peerTime(point), this.scales) })
            .saturate(this.value(this.peerTime(point), this.saturations))
            .brightness(this.value(this.peerTime(point), this.brightnesses))
        }, (point: RadarPoint) => `${point.x}:${point.y}`)
        Image(this.hostAvatar || LiveKitResources.image('livekit_livelist_default_avatar'))
          .alt(LiveKitResources.image('livekit_livelist_default_avatar')).objectFit(ImageFit.Cover)
          .width(34).height(34).borderRadius(17).clip(true).position({ x: 72, y: 25 })
          .shadow({ radius: 7, color: '#664A9EFF' })
      }
    }.width(132).height(84).clip(false).hitTestBehavior(HitTestMode.None)
      .onAreaChange((_: Area, area: Area) => {
        if (!this.laidOut && Number(area.width) > 0 && Number(area.height) > 0) {
          this.laidOut = true
          this.updateAnimation()
        }
      })
  }
}

@Component
export struct PusherCoHostRandomConnectionView {
  @Prop active: boolean = false
  @Prop hostAvatar: string = ''
  @Prop candidates: CoHostUser[] = []
  @State private containerWidth: number = 0
  private radarLeft(): number { return Math.max(96, this.containerWidth - 52 - 132) }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column().width('100%').height('100%')
        .radialGradient({ center: ['30%', '55%'], radius: '57%', colors: [['#3D4A9EFF', 0], ['#004A9EFF', 0.34]] })
      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.RightBottom,
          colors: [['#00FFFFFF', 0.16], ['#09FFFFFF', 0.42], ['#00FFFFFF', 0.68]] })
      Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_title'))
        .fontSize(17).fontWeight(FontWeight.Bold).fontColor(Color.White).height(22).maxLines(1)
        .minFontSize(12.75).maxFontSize(17).width(Math.max(0, this.radarLeft() + 25 - 17))
        .position({ x: 17, y: 19 })
      Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_subtitle'))
        .fontSize(12).fontWeight(300).fontColor(Color.White).height(17).maxLines(1)
        .minFontSize(9).maxFontSize(12).width(Math.max(0, this.radarLeft() + 25 - 17))
        .position({ x: 17, y: 48 })
      CoHostRadar({ active: this.active, hostAvatar: this.hostAvatar, candidates: this.candidates })
        .position({ x: this.radarLeft(), y: 2 })
      Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_button'))
        .fontSize(13).fontWeight(600).fontColor(Color.White).height(40)
        .textAlign(TextAlign.Center).width('calc(100% - 34vp)').position({ x: 17, y: 87 })
        .borderRadius(11).border({ width: 1, color: '#6661AAFF' })
        .linearGradient({ direction: GradientDirection.RightTop, colors: [['#0348B8', 0], ['#3A76BD', 1]] })
        .shadow({ radius: 9, color: '#330052D9', offsetY: 7 })
        .onClick(() => LiveToast.show(LiveKitResources.localizedString('tuilivekit.pusher.cohost.random_developing')))
    }.width('100%').height(142).borderRadius(17).border({ width: 1, color: '#17FFFFFF' })
      .linearGradient({ direction: GradientDirection.RightBottom, colors: [['#EB121E32', 0], ['#F00B0C14', 1]] })
      .clip(true).onAreaChange((_: Area, area: Area) => this.containerWidth = Number(area.width))
  }
}
