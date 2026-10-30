import { BusinessError } from '@kit.BasicServicesKit'
import { image } from '@kit.ImageKit'
import { LevelBadgeView } from '../theme/LevelBadgeView'
import { LiveGiftBarrage } from '../gift/GiftBarrageStore'
import { LiveKitResources } from '../LiveKitResources'
import { LevelBadgeTier } from '../theme/LevelBadgeView'
import { LiveTheme, rgba, white } from '../theme/LiveTheme'

export const defaultWidthRatio: number = 0.8

const maximumMessageCount: number = 100
const bottomThreshold: number = 8
const topFadeHeight: number = 22

export class Message {
  id: string
  userName: string
  content: string
  level: number
  isHost: boolean
  gift?: LiveGiftBarrage

  constructor(id: string, userName: string, content: string, level: number, isHost: boolean = false,
    gift?: LiveGiftBarrage) {
    this.id = id
    this.userName = userName
    this.content = content
    this.level = level
    this.isHost = isHost
    this.gift = gift
  }
}

export class LiveCommentRowStyle {
  static readonly background: string = LiveTheme.Color.control(0.34)
  static readonly fontSize: number = 13
  static readonly cornerRadius: number = 9
  static readonly horizontalInset: number = 8

  static displayUserName(raw: string): string {
    const name = raw.split(/\r?\n/).join(' ')
    const characters = Array.from(name)
    return characters.length > 20 ? characters.slice(0, 20).join('') + '…' : name
  }
}

function displayContent(raw: string): string {
  const characters = Array.from(raw)
  return characters.length > 200 ? characters.slice(0, 200).join('') + '...' : raw
}

function senderName(barrage: LiveGiftBarrage): string {
  const name = barrage.senderName.length === 0 ? barrage.senderID : barrage.senderName
  return name.length === 0 ? LiveKitResources.localizedString('tuilivekit.common.viewer') : name
}

class CommentBadgeCache {
  private images: Map<string, Promise<image.PixelMap>> = new Map()
  private isReleased: boolean = false

  get(key: string, context: UIContext, builder: CustomBuilder): Promise<image.PixelMap> {
    if (this.isReleased) {
      return Promise.reject(new Error('Comment badge owner released'))
    }
    const cached = this.images.get(key)
    if (cached !== undefined) {
      return cached
    }
    // Snapshot may throw before returning a Promise; keep failures in the same rejection path.
    const pending = Promise.resolve().then(() => {
      if (this.isReleased) {
        throw new Error('Comment badge owner released')
      }
      return context.getComponentSnapshot().createFromBuilder(builder, 0, true,
        { waitUntilRenderFinished: true })
    }).then((bitmap: image.PixelMap) => {
      if (this.isReleased) {
        bitmap.release()
        throw new Error('Comment badge owner released')
      }
      return bitmap
    }).catch((error: Error) => {
      this.images.delete(key)
      throw error
    })
    this.images.set(key, pending)
    return pending
  }

  release(): void {
    this.isReleased = true
    this.images.forEach((pending: Promise<image.PixelMap>) => {
      pending.then((bitmap: image.PixelMap) => bitmap.release()).catch(() => {
      })
    })
    this.images.clear()
  }
}

@Component
struct CommentContentView {
  message: Message = new Message('', '', '', 0)
  cache: CommentBadgeCache = new CommentBadgeCache()
  @State private levelImage: image.PixelMap | undefined = undefined
  @State private hostImage: image.PixelMap | undefined = undefined
  private isMounted: boolean = false
  private badgeRequest: number = 0
  private badgeRetryTasks: number[] = []

  @Builder
  levelBadgeSpan(width: number) {
    ImageSpan(this.levelImage ?? '')
      .width(width)
      .height(15)
      .objectFit(ImageFit.Contain)
      .margin({ right: 4 })
      .verticalAlign(ImageSpanAlignment.CENTER)
  }

  @Builder
  messageRow(message: Message, badgeWidth: number) {
    Text() {
      this.levelBadgeSpan(badgeWidth)
      if (message.isHost) {
        ImageSpan(this.hostImage ?? '')
          .width(29)
          .height(15)
          .objectFit(ImageFit.Contain)
          .margin({ right: 4 })
          .verticalAlign(ImageSpanAlignment.CENTER)
      }
      Span(`${LiveCommentRowStyle.displayUserName(message.userName)}：`)
        .fontColor(LiveTheme.Color.nickname)
      Span(displayContent(message.content))
        .fontColor(white(0.94))
    }
    .fontSize(LiveCommentRowStyle.fontSize)
    .fontWeight(600)
    .lineHeight(17)
    .wordBreak(WordBreak.BREAK_ALL)
    .padding({
      left: 8,
      right: 8,
      top: 2,
      bottom: 2
    })
    .constraintSize({ minHeight: 21 })
    .backgroundColor(LiveCommentRowStyle.background)
    .borderRadius(LiveCommentRowStyle.cornerRadius)
    .accessibilityText(`${message.userName}：${displayContent(message.content)}`)
  }

  @Builder
  giftBarrageRow(barrage: LiveGiftBarrage, badgeWidth: number) {
    Text() {
      this.levelBadgeSpan(badgeWidth)
      Span(LiveCommentRowStyle.displayUserName(senderName(barrage)))
        .fontColor(LiveTheme.Color.nickname)
      Span(` ${LiveKitResources.localizedString('tuilivekit.common.gift.sent')} `)
        .fontColor(rgba(1, 0.957, 0.812))
      Span(`${barrage.giftName} `)
        .fontColor(rgba(1, 0.906, 0.639))
      if (barrage.giftIconURL.length > 0) {
        ImageSpan(barrage.giftIconURL)
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .verticalAlign(ImageSpanAlignment.CENTER)
        Span(' ')
      }
      Span(`×${barrage.count}`)
        .fontColor(rgba(1, 0.906, 0.639))
        .fontWeight(FontWeight.Bold)
    }
    .fontSize(LiveCommentRowStyle.fontSize)
    .fontWeight(600)
    .lineHeight(22)
    .wordBreak(WordBreak.BREAK_ALL)
    .padding({
      left: 8,
      right: 8,
      top: 3,
      bottom: 3
    })
    .constraintSize({ minHeight: 28 })
    .backgroundColor(LiveCommentRowStyle.background)
    .borderRadius(LiveCommentRowStyle.cornerRadius)
    .clip(true)
    .accessibilityText(`${senderName(barrage)} ${LiveKitResources.localizedString(
      'tuilivekit.common.gift.sent')} ${barrage.giftName} ×${barrage.count}`)
  }

  @Builder
  levelBadgeImage(level: number) {
    LevelBadgeView({ level: level, isInline: true })
      .clip(true)
  }

  @Builder
  hostBadgeImage() {
    Text(LiveKitResources.localizedString('tuilivekit.common.host'))
      .fontSize(8.5)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .textAlign(TextAlign.Center)
      .width(29)
      .height(15)
      .padding({ top: 2, bottom: 2 })
      .borderRadius(7.5)
      .borderWidth(0.5)
      .borderColor(rgba(0.61, 0.93, 1, 0.49))
      .backgroundColor(rgba(0.196, 0.4, 0.643))
  }

  aboutToAppear(): void {
    this.isMounted = true
    const request = ++this.badgeRequest
    const level = this.message.gift?.senderLevel ?? this.message.level
    this.loadBadge(`level:${level}`, () => this.levelBadgeImage(level), false, request)
    if (this.message.isHost && this.message.gift === undefined) {
      this.loadBadge('host', () => this.hostBadgeImage(), true, request)
    }
  }

  private loadBadge(key: string, builder: CustomBuilder, isHost: boolean, request: number, attempt: number = 0): void {
    if (!this.isMounted || request !== this.badgeRequest) {
      return
    }
    this.cache.get(key, this.getUIContext(), builder).then((bitmap: image.PixelMap) => {
      if (!this.isMounted || request !== this.badgeRequest) {
        return
      }
      if (isHost) {
        this.hostImage = bitmap
      } else {
        this.levelImage = bitmap
      }
    }).catch((error: BusinessError) => {
      if (!this.isMounted || request !== this.badgeRequest) {
        return
      }
      if (error.code === 160001 && attempt < 2) {
        this.badgeRetryTasks.push(setTimeout(() => {
          this.loadBadge(key, builder, isHost, request, attempt + 1)
        }, 80 * (attempt + 1)))
      } else {
        console.error(`Comment ${isHost ? 'host' : 'level'} badge: code=${error.code}, ${error.message}`)
      }
    })
  }

  aboutToDisappear(): void {
    this.isMounted = false
    this.badgeRequest += 1
    this.badgeRetryTasks.forEach((task: number) => clearTimeout(task))
    this.badgeRetryTasks = []
  }

  build() {
    if (this.message.gift !== undefined) {
      this.giftBarrageRow(this.message.gift,
        LevelBadgeTier.width(this.message.gift.senderLevel, this.getUIContext()))
    } else {
      this.messageRow(this.message,
        LevelBadgeTier.width(this.message.level, this.getUIContext()))
    }
  }
}

@Component
export struct BarrageStreamView {
  @Prop @Watch('onMessagesChanged') messages: Message[] = []
  onVisibleContentHeightChanged?: (height: number) => void
  @State private rows: Message[] = []
  @State private unreadCount: number = 0
  @State private viewportHeight: number = 0
  private isFollowingLatest: boolean = true
  private isUserScrolling: boolean = false
  private scrollRequest: number = 0
  private scrollTasks: number[] = []
  private contentHeight: number = 0
  private lastVisibleContentHeight: number = -1
  private scroller: Scroller = new Scroller()
  private badgeCache: CommentBadgeCache = new CommentBadgeCache()

  aboutToAppear(): void {
    this.badgeCache = new CommentBadgeCache()
    this.onMessagesChanged()
  }

  aboutToDisappear(): void {
    this.badgeCache.release()
    this.cancelScrollTasks()
  }

  private cancelScrollTasks(): void {
    this.scrollRequest += 1
    this.scrollTasks.forEach((task: number) => clearTimeout(task))
    this.scrollTasks = []
  }

  private onMessagesChanged(): void {
    const next = this.messages.slice(-maximumMessageCount)
    if (next.length === this.rows.length && next.every((message: Message, index: number) =>
    JSON.stringify(message) === JSON.stringify(this.rows[index]))) {
      return
    }
    const wasEmpty = this.rows.length === 0
    const addedCount = this.numberOfNewMessages(this.rows, next)
    const latestIsHost = next.length > 0 && next[next.length - 1].isHost
    this.rows = next
    if (wasEmpty || this.isFollowingLatest || latestIsHost) {
      this.isFollowingLatest = true
      this.unreadCount = 0
      this.scheduleScrollToLatest(!wasEmpty)
    } else if (addedCount > 0) {
      this.unreadCount += addedCount
    }
  }

  prepareForReuse(): void {
    this.cancelScrollTasks()
    this.rows = []
    this.unreadCount = 0
    this.isFollowingLatest = true
    this.isUserScrolling = false
    this.lastVisibleContentHeight = -1
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
  }

  private numberOfNewMessages(previous: Message[], next: Message[]): number {
    if (previous.length === 0) {
      return 0
    }
    for (let overlap = Math.min(previous.length, next.length); overlap >= 1; overlap--) {
      const tail = previous.slice(previous.length - overlap)
      if (tail.every((message: Message, index: number) => message.id === next[index].id)) {
        return next.length - overlap
      }
    }
    return 0
  }

  private scheduleScrollToLatest(animated: boolean): void {
    this.isUserScrolling = false
    this.cancelScrollTasks()
    const request = this.scrollRequest
    this.scrollTasks.push(setTimeout(() => {
      if (this.scrollRequest === request && this.isFollowingLatest) {
        this.scroller.scrollEdge(Edge.Bottom, { velocity: animated ? 1200 : 0 })
      }
    }, 0))
    this.scrollTasks.push(setTimeout(() => {
      if (this.scrollRequest === request && this.isFollowingLatest) {
        this.scroller.scrollEdge(Edge.Bottom)
      }
    }, 320))
  }

  private isNearBottom(): boolean {
    return this.contentHeight - this.scroller.currentOffset().yOffset - this.viewportHeight <= bottomThreshold
  }

  private updateFollowingState(): void {
    this.isFollowingLatest = this.isNearBottom()
    if (this.isFollowingLatest) {
      this.unreadCount = 0
    }
  }

  private notifyVisibleContentHeightIfNeeded(): void {
    const visibleContentHeight = Math.min(this.viewportHeight, Math.max(0, this.contentHeight - topFadeHeight))
    if (Math.abs(visibleContentHeight - this.lastVisibleContentHeight) <= 0.5) {
      return
    }
    this.lastVisibleContentHeight = visibleContentHeight
    this.onVisibleContentHeightChanged?.(visibleContentHeight)
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Stack() {
        Scroll(this.scroller) {
          Column() {
            Column({ space: 2 }) {
              ForEach(this.rows, (message: Message) => {
                CommentContentView({ message: message, cache: this.badgeCache })
              }, (message: Message) => JSON.stringify(message))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .onAreaChange((_: Area, area: Area) => {
              this.contentHeight = (area.height as number) + topFadeHeight
              this.notifyVisibleContentHeightIfNeeded()
              if (this.isFollowingLatest && this.rows.length > 0) {
                this.scheduleScrollToLatest(false)
              }
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ top: topFadeHeight })
          .constraintSize({ minHeight: this.viewportHeight })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height('100%')
        .onScrollStart(() => {
          this.scrollRequest += 1
          this.isUserScrolling = true
        })
        .onDidScroll(() => {
          if (this.isUserScrolling) {
            this.updateFollowingState()
          }
        })
        .onScrollStop(() => {
          this.updateFollowingState()
          this.isUserScrolling = false
        })

        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [['rgba(0,0,0,0)', 0],
              ['rgba(0,0,0,1)', Math.min(0.5, topFadeHeight / Math.max(1, this.viewportHeight))],
              ['rgba(0,0,0,1)', 1]],
          })
          .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height('100%')
      .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
      .onAreaChange((_: Area, area: Area) => {
        this.viewportHeight = area.height as number
        this.notifyVisibleContentHeightIfNeeded()
        if (this.isFollowingLatest && this.rows.length > 0) {
          this.scheduleScrollToLatest(false)
        }
      })

      if (this.unreadCount > 0) {
        Button(LiveKitResources.localizedFormat('tuilivekit.pusher.living.new_messages', this.unreadCount))
          .fontSize(11)
          .fontWeight(600)
          .fontColor(Color.White)
          .height(26)
          .padding({ left: 10, right: 10 })
          .backgroundColor(LiveTheme.Color.overlay(0.96))
          .borderRadius(13)
          .borderWidth(1)
          .borderColor(rgba(0.61, 0.93, 1, 0.34))
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.38)', offsetY: 5 })
          .onClick(() => {
            this.isFollowingLatest = true
            this.unreadCount = 0
            this.scheduleScrollToLatest(true)
          })
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .visibility(this.rows.length === 0 ? Visibility.Hidden : Visibility.Visible)
  }
}
