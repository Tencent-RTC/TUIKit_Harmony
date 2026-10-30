import { LiveTheme, rgba, white } from './LiveTheme'

const cornerRadius: number = 26
const top: string = rgba(0.094, 0.086, 0.125)
const bottom: string = rgba(0.039, 0.035, 0.055)

class Glow {
  x: number
  y: number
  width: number
  height: number
  heightFactor: number
  color: string

  constructor(x: number, y: number, width: number, height: number, heightFactor: number, color: string) {
    this.x = x
    this.y = y
    this.width = width
    this.height = height
    this.heightFactor = heightFactor
    this.color = color
  }
}

const glows: Glow[] = [
  new Glow(-148.8, -180, 360, 360, 0.08, rgba(0.29, 0.62, 1, 0.319)),
  new Glow(218.8, -140, 280, 280, 0.01, rgba(0.49, 0.91, 1, 0.29)),
  new Glow(135, -60, 120, 120, 0.43, rgba(0, 0.32, 0.85, 0.348)),
  new Glow(-45.4, -100, 200, 200, 0.99, rgba(0.49, 0.91, 1, 0.232)),
  new Glow(262.2, -120, 240, 240, 0.99, rgba(0.29, 0.62, 1, 0.261)),
]

@Component
export struct BottomSheetBackgroundView {
  @State private viewWidth: number = 390
  @State private viewHeight: number = 0

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Column().width('100%').height('100%').linearGradient({ angle: 180, colors: [[top, 0], [bottom, 1]] })
        Column().width('100%').height('100%').linearGradient({ angle: 180, colors: [[white(0.05), 0], ['rgba(0,0,0,0)', 0.2]] })
        Column().width('100%').height('100%').linearGradient({ angle: 180, colors: [[white(0.035), 0], [white(0.015), 1]] })
        Column()
          .width(312 * this.viewWidth / 390).height(80)
          .position({ x: 39 * this.viewWidth / 390, y: this.viewHeight - 40 })
          .radialGradient({ center: ['50%', '50%'], radius: '50%', colors: [[LiveTheme.Color.brand(0.22), 0], ['rgba(0,0,0,0)', 1]] })
        ForEach(glows, (glow: Glow) => {
          Column()
            .width(glow.width * this.viewWidth / 390).height(glow.height)
            .position({ x: glow.x * this.viewWidth / 390, y: glow.y + glow.heightFactor * this.viewHeight })
            .radialGradient({ center: ['50%', '50%'], radius: '50%', colors: [[glow.color, 0], ['rgba(0,0,0,0)', 1]] })
        })
        Column().width('100%').height(0.5).backgroundColor(white(0.14))
        Column().width(36).height(4).borderRadius(2).backgroundColor(white(0.2))
          .position({ x: (this.viewWidth - 36) / 2, y: 10 })
      }
      .width('100%')
      .height('100%')
      .clip(true)
      .borderRadius({ topLeft: cornerRadius, topRight: cornerRadius })

      Column()
        .width('70%')
        .height(2)
        .position({ x: '15%', y: 0 })
        .linearGradient({
          angle: 90,
          colors: [['rgba(0,0,0,0)', 0], [LiveTheme.Color.brand(0.9), 0.3], [rgba(0.49, 0.91, 1, 0.9), 0.7], ['rgba(0,0,0,0)', 1]],
        })
        .shadow({ radius: 8, color: LiveTheme.Color.brand(0.7) })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(bottom)
    .borderRadius({ topLeft: cornerRadius, topRight: cornerRadius })
    .shadow({ radius: 80, color: 'rgba(0,0,0,0.7)', offsetY: -24 })
    .onAreaChange((_: Area, area: Area) => {
      this.viewWidth = area.width as number
      this.viewHeight = area.height as number
    })
  }
}
