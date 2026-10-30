import { curves } from '@kit.ArkUI'
import { LiveKitResources } from '../../LiveKitResources'
import { white } from '../../theme/LiveTheme'
import { GiftPanelStyle } from './GiftSendPanelView'

const comboDuration: number = 2000
const holdDelay: number = 300
const holdInterval: number = 300
const faceDiameter: number = 68
const coreRadius: number = faceDiameter / 2 - 8
const progressRadius: number = faceDiameter / 2 - 5
const innerDiameter: number = coreRadius * 2 * 46 / 52
const dashAngle: number = Math.PI * 8 / 180
const dashStep: number = Math.PI * 12 / 180

function formattedHint(raw: string): string {
  const trimmed = raw.trim()
  if (trimmed.includes(' ')) {
    return trimmed
  }
  const characters = Array.from(trimmed)
  return characters.length === 4 ? `${characters[0]}${characters[1]}\n${characters[2]}${characters[3]}` : trimmed
}

@Component
export struct GiftSendComboButton {
  giftID: string = ''
  iconURL: string = ''
  onSendOnce?: () => void
  onExpired?: () => void
  @State private comboCount: number = 0
  @State private badgeScale: number = 1
  private readonly faceContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private isFaceReady: boolean = false
  private countdownStartedAt: number = 0
  private countdownTimer: number = -1
  private expireTimer: number = -1
  private holdTimer: number = -1
  private holdRepeatTimer: number = -1
  private isPressing: boolean = false

  aboutToAppear(): void {
    this.comboCount = 0
    this.performSingleShot()
  }

  aboutToDisappear(): void {
    this.cancelTimers()
    this.isFaceReady = false
  }

  private remainingProgress(): number {
    return Math.min(Math.max(1 - (Date.now() - this.countdownStartedAt) / comboDuration, 0), 1)
  }

  private restartTimer(): void {
    clearInterval(this.countdownTimer)
    clearTimeout(this.expireTimer)
    this.countdownStartedAt = Date.now()
    this.drawFace(1)
    this.countdownTimer = setInterval(() => this.drawFace(this.remainingProgress()), 16)
    this.expireTimer = setTimeout(() => {
      this.drawFace(0)
      this.cancelTimers()
      this.onExpired?.()
    }, comboDuration)
  }

  private cancelTimers(): void {
    clearInterval(this.countdownTimer)
    this.countdownTimer = -1
    clearTimeout(this.expireTimer)
    clearTimeout(this.holdTimer)
    clearInterval(this.holdRepeatTimer)
    this.expireTimer = -1
    this.holdTimer = -1
    this.holdRepeatTimer = -1
    this.isPressing = false
  }

  private performSingleShot(): void {
    this.comboCount += 1
    this.getUIContext().animateTo({ duration: 0 }, () => this.badgeScale = 1.35)
    this.getUIContext().animateTo({ duration: 220, curve: curves.springMotion(0.22, 0.5) }, () => this.badgeScale = 1)
    this.restartTimer()
    this.onSendOnce?.()
  }

  private handleTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.isPressing = true
      this.performSingleShot()
      clearTimeout(this.holdTimer)
      this.holdTimer = setTimeout(() => {
        if (!this.isPressing) {
          return
        }
        clearInterval(this.holdRepeatTimer)
        this.holdRepeatTimer = setInterval(() => {
          if (!this.isPressing) {
            clearInterval(this.holdRepeatTimer)
            return
          }
          this.performSingleShot()
        }, holdInterval)
      }, holdDelay)
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.isPressing = false
      clearTimeout(this.holdTimer)
      clearInterval(this.holdRepeatTimer)
      this.holdTimer = -1
      this.holdRepeatTimer = -1
    }
  }

  private drawFace(progress: number): void {
    if (!this.isFaceReady) {
      return
    }
    const context = this.faceContext
    const center = faceDiameter / 2
    context.clearRect(0, 0, faceDiameter, faceDiameter)
    context.save()
    context.beginPath()
    context.arc(center, center, coreRadius, 0, Math.PI * 2)
    context.fillStyle = 'rgba(5, 6, 12, 0.9)'
    context.fill()
    this.drawProgress(progress, true)
    this.drawProgress(progress, false)

    const faceLeft = center - innerDiameter / 2
    const gradient = context.createLinearGradient(faceLeft, faceLeft, faceLeft + innerDiameter, faceLeft + innerDiameter)
    gradient.addColorStop(0, GiftPanelStyle.blue)
    gradient.addColorStop(0.55, GiftPanelStyle.blue)
    gradient.addColorStop(1, GiftPanelStyle.deepBlue)
    context.beginPath()
    context.arc(center, center, innerDiameter / 2, 0, Math.PI * 2)
    context.clip()
    context.fillStyle = gradient
    context.fillRect(faceLeft, faceLeft, innerDiameter, innerDiameter)
    const highlightY = faceLeft + innerDiameter * 0.15
    const highlight = context.createRadialGradient(center, highlightY, 0, center, highlightY, innerDiameter * 0.55)
    highlight.addColorStop(0, white(0.28))
    highlight.addColorStop(1, white(0))
    context.fillStyle = highlight
    context.fillRect(faceLeft, faceLeft, innerDiameter, innerDiameter)
    context.restore()
  }

  private drawProgress(progress: number, glow: boolean): void {
    const context = this.faceContext
    const center = faceDiameter / 2
    const startAngle = -Math.PI / 2
    const endAngle = startAngle - Math.PI * 2 * Math.min(Math.max(progress, 0), 1)
    context.save()
    context.lineWidth = 3
    context.lineCap = 'butt'
    context.strokeStyle = glow ? GiftPanelStyle.blueAlpha(0.72) : GiftPanelStyle.blue
    if (glow) {
      context.shadowColor = GiftPanelStyle.blueAlpha(0.72)
      context.shadowBlur = 5
    }
    for (let index = 0; index < 30; index++) {
      const dashStart = startAngle - index * dashStep
      const dashEnd = Math.max(dashStart - dashAngle, endAngle)
      if (dashEnd >= dashStart) {
        break
      }
      context.beginPath()
      context.arc(center, center, progressRadius, dashStart, dashEnd, true)
      context.stroke()
    }
    context.restore()
  }

  build() {
    Column() {
      Stack() {
        Canvas(this.faceContext)
          .width(faceDiameter)
          .height(faceDiameter)
          .hitTestBehavior(HitTestMode.None)
          .onReady(() => {
            this.isFaceReady = true
            this.drawFace(this.remainingProgress())
          })
        Text(formattedHint(LiveKitResources.localizedString('tuilivekit.player.gift.combo.hint')))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .padding({ left: 6, right: 6 })
          .hitTestBehavior(HitTestMode.None)
      }
      .width(faceDiameter)
      .height(faceDiameter)
      .margin({ top: 4 })
      .onTouch((event: TouchEvent) => this.handleTouch(event))
      Text(`${this.comboCount}`)
        .fontSize(12)
        .fontWeight(800)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .height(20)
        .constraintSize({ minWidth: 30 })
        .padding({ left: 6, right: 6 })
        .borderRadius(10)
        .backgroundColor(GiftPanelStyle.blue)
        .margin({ top: 6 })
        .scale({ x: this.badgeScale, y: this.badgeScale })
    }
    .width('100%')
    .height('100%')
  }
}
