import measure from '@ohos.measure'
import { LiveKitResources } from '../LiveKitResources'
import { black, rgba, white } from './LiveTheme'

class Tier {
  colors: string[]
  assetName: string
  borderColor: string
  textColor: string
  borderWidth: number
  isElite: boolean

  constructor(colors: string[], assetName: string, borderColor: string, textColor: string, borderWidth: number,
    isElite: boolean = false) {
    this.colors = colors
    this.assetName = assetName
    this.borderColor = borderColor
    this.textColor = textColor
    this.borderWidth = borderWidth
    this.isElite = isElite
  }

  static of(level: number): Tier {
    if (level < 10) {
      return new Tier([rgba(0.325, 0.388, 0.498), rgba(0.443, 0.525, 0.678)], 'livekit_level_basic',
        'rgba(0,0,0,0)', rgba(0.859, 0.906, 1), 0)
    }
    if (level < 25) {
      return new Tier([rgba(0.224, 0.482, 0.847), rgba(0.333, 0.725, 0.863)], 'livekit_level_advanced',
        rgba(0.824, 0.965, 1, 0.3), rgba(0.914, 0.984, 1), 0.5)
    }
    if (level < 40) {
      return new Tier([rgba(0.4, 0.333, 0.91), rgba(0.639, 0.365, 0.941), rgba(0.906, 0.427, 0.741)],
        'livekit_level_premium', white(0.42), rgba(1, 0.953, 1), 0.5)
    }
    return new Tier([rgba(0.898, 0.529, 0.263), rgba(0.945, 0.784, 0.325), rgba(0.459, 0.408, 0.941)],
      'livekit_level_elite', rgba(1, 0.98, 0.812), rgba(1, 0.976, 0.867), 0.5, true)
  }

  gradientStops(): Array<[ResourceColor, number]> {
    return this.colors.map((color: string, index: number): [ResourceColor, number] =>
    [color, index / Math.max(1, this.colors.length - 1)])
  }
}

@Component
export struct LevelBadgeView {
  @Prop level: number = 0
  @Prop isInline: boolean = false

  private tier(): Tier {
    return Tier.of(Math.max(0, this.level))
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(LiveKitResources.image(this.tier().assetName))
        .width(10)
        .height(10)
        .objectFit(ImageFit.Contain)
        .syncLoad(this.isInline)
        .position({ x: 4, y: 2.5 })
      Text(`${Math.max(0, Math.floor(this.level))}`)
        .fontSize(8.5)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tier().textColor)
        .textAlign(TextAlign.Center)
        .height(12)
        .width(LevelBadgeTier.width(this.level, this.getUIContext()) - 18)
        .position({ x: 14, y: 1 })
        .textShadow({ radius: 2, color: black(0.34), offsetY: 1 })
    }
    .width(LevelBadgeTier.width(this.level, this.getUIContext()))
    .height(15)
    .borderRadius(7.5)
    .borderWidth(this.tier().borderWidth)
    .borderColor(this.tier().borderColor)
    .linearGradient({ direction: GradientDirection.RightBottom, colors: this.tier().gradientStops() })
    .shadow(
      this.tier().isElite && !this.isInline ? { radius: 6, color: rgba(0.93, 0.67, 0.29, 0.44) } :
        { radius: 0, color: 'rgba(0,0,0,0)' })
  }
}

export class LevelBadgeTier {
  static width(level: number, context: UIContext): number {
    const pixels = measure.measureText({
      textContent: `${Math.max(0, Math.floor(level))}`, fontSize: 8.5,
      fontWeight: '700'
    })
    return Math.max(34, 18 + Math.ceil(context.px2vp(pixels)))
  }

  static assetName(level: number): string {
    return Tier.of(Math.max(0, level)).assetName
  }

  static background(level: number): string {
    const colors = Tier.of(Math.max(0, level)).colors
    return colors[Math.floor(colors.length / 2)]
  }

  static textColor(level: number): string {
    return Tier.of(Math.max(0, level)).textColor
  }
}
