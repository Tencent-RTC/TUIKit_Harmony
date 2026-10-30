import { curves } from '@kit.ArkUI'
import { LiveKitResources } from '../../LiveKitResources'
import { LiveTheme, rgba, white } from '../../theme/LiveTheme'
import { GiftDisplayItem } from './GiftDisplayView'

const maximumChannelCount: number = 2
let entrySeed: number = 0

@Observed
class Entry {
  id: number = ++entrySeed
  key: string
  gift: GiftDisplayItem
  count: number
  isLeaving: boolean = false
  offsetX: number = 0
  opacity: number = 0
  countScale: number = 1
  countHighlighted: boolean = false
  expiration: number = -1
  startTask: number = -1

  constructor(gift: GiftDisplayItem, count: number) {
    this.key = gift.comboKey
    this.gift = gift
    this.count = count
  }
}

class PendingEntry {
  key: string
  gift: GiftDisplayItem
  count: number

  constructor(gift: GiftDisplayItem) {
    this.key = gift.comboKey
    this.gift = gift
    this.count = gift.count
  }
}

@Observed
export class GiftNoticeController {
  activeEntries: Entry[] = []
  uiContext?: UIContext
  width: number = 0
  private queue: PendingEntry[] = []
  private generation: number = 0

  enqueue(gift: GiftDisplayItem): void {
    if (gift.count <= 0) {
      return
    }
    const active = this.activeEntries.find((entry: Entry) => entry.key === gift.comboKey && !entry.isLeaving)
    if (active !== undefined) {
      active.gift = gift
      active.count = Math.min(Number.MAX_SAFE_INTEGER, active.count + gift.count)
      this.bumpCount(active)
      this.scheduleExpiration(active)
      return
    }
    const leaving = this.activeEntries.find((entry: Entry) => entry.key === gift.comboKey && entry.isLeaving)
    if (leaving !== undefined) {
      this.finish(leaving)
    }
    const pending = this.queue.find((entry: PendingEntry) => entry.key === gift.comboKey)
    if (pending !== undefined) {
      pending.gift = gift
      pending.count = Math.min(Number.MAX_SAFE_INTEGER, pending.count + gift.count)
      return
    }
    const next = new PendingEntry(gift)
    if (this.activeEntries.length < maximumChannelCount) {
      this.activate(next)
    } else {
      this.queue.push(next)
    }
  }

  reset(): void {
    this.generation++
    this.activeEntries.forEach((entry: Entry) => {
      clearTimeout(entry.expiration)
      clearTimeout(entry.startTask)
    })
    this.activeEntries = []
    this.queue = []
  }

  private animate(duration: number, curve: Curve | ICurve, event: () => void, onFinish?: () => void): void {
    if (this.uiContext === undefined) {
      event()
      onFinish?.()
      return
    }
    this.uiContext.animateTo({ duration: duration, curve: curve, onFinish: onFinish }, event)
  }

  private activate(pending: PendingEntry): void {
    const entry = new Entry(pending.gift, pending.count)
    entry.offsetX = -(this.width + 12)
    this.activeEntries = this.activeEntries.concat([entry])
  }

  start(entry: Entry): void {
    if (!this.activeEntries.includes(entry) || entry.startTask !== -1) {
      return
    }
    entry.startTask = setTimeout(() => {
      if (!this.activeEntries.includes(entry)) {
        return
      }
      this.animate(260, Curve.EaseOut, () => entry.opacity = 1)
      this.animate(520, curves.cubicBezierCurve(0.16, 0.82, 0.22, 1), () => entry.offsetX = 0)
    }, 0)
    this.scheduleExpiration(entry)
  }

  private bumpCount(entry: Entry): void {
    this.animate(99, Curve.EaseOut, () => {
      entry.countScale = 1.24
      entry.countHighlighted = true
    }, () => {
      if (this.activeEntries.includes(entry)) {
        this.animate(121, Curve.EaseIn, () => {
          entry.countScale = 1
          entry.countHighlighted = false
        })
      }
    })
  }

  private scheduleExpiration(entry: Entry): void {
    clearTimeout(entry.expiration)
    const generation = this.generation
    entry.expiration = setTimeout(() => {
      if (this.generation === generation) {
        this.dismiss(entry)
      }
    }, 2000)
  }

  private dismiss(entry: Entry): void {
    if (!this.activeEntries.includes(entry) || entry.isLeaving) {
      return
    }
    entry.isLeaving = true
    entry.expiration = -1
    this.animate(320, Curve.EaseIn, () => {
      entry.opacity = 0
      entry.offsetX = -24
    }, () => this.finish(entry))
  }

  private finish(entry: Entry): void {
    if (!this.activeEntries.includes(entry)) {
      return
    }
    clearTimeout(entry.expiration)
    clearTimeout(entry.startTask)
    this.activeEntries = this.activeEntries.filter((item: Entry) => item !== entry)
    const next = this.queue.shift()
    if (next !== undefined) {
      this.activate(next)
    }
  }
}

@Component
struct GiftNoticeItemView {
  @ObjectLink entry: Entry
  @State private hasGiftImage: boolean = false
  onReady?: () => void

  build() {
    Row() {
      Row() {
        Image(this.entry.gift.senderAvatarURL)
          .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
          .width(38)
          .height(38)
          .borderRadius(19)
          .borderWidth(1)
          .borderColor(white(0.72))
          .objectFit(ImageFit.Cover)
          .margin({ left: 3 })
        Column({ space: 2 }) {
          Text(this.entry.gift.senderName.length === 0 ? this.entry.gift.senderID : this.entry.gift.senderName)
            .fontSize(12)
            .fontWeight(600)
            .fontColor(Color.White)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(LiveKitResources.localizedFormat('tuilivekit.pusher.gift.sent', this.entry.gift.name))
            .fontSize(9)
            .fontColor(white(0.72))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 7, right: 2 })

        Stack() {
          if (!this.hasGiftImage) {
            Text(LiveKitResources.localizedString('tuilivekit.pusher.gift.fallback'))
              .fontSize(17)
              .fontWeight(800)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .width(34)
              .height(34)
              .borderRadius(12)
              .linearGradient({
                direction: GradientDirection.RightBottom,
                colors: [[LiveTheme.Color.brandBlue, 0], [rgba(0.51, 0.35, 0.96), 1]]
              })
          }
          Image(this.entry.gift.iconURL)
            .width(37)
            .height(37)
            .objectFit(ImageFit.Contain)
            .onComplete(() => this.hasGiftImage = true)
            .onError(() => this.hasGiftImage = false)
        }
        .width(37)
        .height(37)
        .margin({ right: 5 })
      }
      .width(178)
      .height(44)
      .borderRadius(22)
      .backgroundColor(rgba(0.031, 0.039, 0.059, 0.28))
      .flexShrink(1)

      Text('×')
        .fontSize(17)
        .fontWeight(800)
        .fontColor(Color.White)
        .margin({ left: 4, top: 4 })
      Text(`${this.entry.count}`)
        .fontSize(26)
        .fontWeight(800)
        .fontFeature('"tnum" on')
        .fontColor(this.entry.countHighlighted ? rgba(0.47, 0.85, 1) : Color.White)
        .minFontSize(15.6)
        .maxFontSize(26)
        .maxLines(1)
        .constraintSize({ minWidth: 28 })
        .margin({ left: 2, top: 2 })
        .textShadow({ radius: 4, color: 'rgba(0,0,0,0.55)', offsetY: 2 })
        .scale({ x: this.entry.countScale, y: this.entry.countScale })
    }
    .width('100%')
    .height(44)
    .opacity(this.entry.opacity)
    .translate({ x: this.entry.offsetX })
    .onAreaChange(() => this.onReady?.())
  }
}

@Component
export struct GiftNoticeView {
  @ObjectLink controller: GiftNoticeController

  aboutToAppear(): void {
    this.controller.uiContext = this.getUIContext()
  }

  aboutToDisappear(): void {
    this.controller.reset()
    this.controller.uiContext = undefined
  }

  build() {
    Column({ space: 4 }) {
      ForEach(this.controller.activeEntries, (entry: Entry) => {
        GiftNoticeItemView({ entry: entry, onReady: () => this.controller.start(entry) })
      }, (entry: Entry) => `${entry.id}`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .hitTestBehavior(HitTestMode.None)
    .onAreaChange((_: Area, area: Area) => this.controller.width = area.width as number)
  }
}
