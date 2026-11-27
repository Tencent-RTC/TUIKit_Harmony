import { LiveKitResources, LiveKitSafeArea } from '../../LiveKitResources'
import { rgba } from '../../theme/LiveTheme'
import { BarrageEmoji } from './BarrageEmojiConverter'

@Component
struct BarrageEmojiCell {
  @Prop @Watch('onEmojiChanged') emoji: BarrageEmoji
  @State private imageFailed: boolean = false
  onSelect: (emoji: BarrageEmoji) => void = () => {}

  private onEmojiChanged(): void {
    this.imageFailed = false
  }

  build() {
    if (this.imageFailed) {
      Text(this.emoji.token)
        .width(29)
        .height(29)
        .fontSize(8)
        .fontColor(rgba(0, 0, 0, 0.48))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .onClick(() => this.onSelect(this.emoji))
    } else {
      Image(LiveKitResources.image(this.emoji.assetName))
        .width(29)
        .height(29)
        .objectFit(ImageFit.Contain)
        .accessibilityText(this.emoji.token)
        .onError(() => {
          this.imageFailed = true
        })
        .onClick(() => this.onSelect(this.emoji))
    }
  }
}

@Component
export struct BarrageEmojiPanelView {
  @Prop contentHeight: number = 274
  @Prop isDeleteEnabled: boolean = false
  @Prop isSendEnabled: boolean = false
  onSelect: (emoji: BarrageEmoji) => void = () => {}
  onDelete: () => void = () => {}
  onSend: () => void = () => {}
  @StorageProp(LiveKitSafeArea.bottomKey) private safeBottom: number = 0
  private scroller: Scroller = new Scroller()

  private static readonly titleTop: number = 8
  private static readonly contentTop: number = 40.5
  private static readonly itemSize: number = 29
  private static readonly verticalGap: number = 11
  private static readonly columnCount: number = 8
  private static readonly gridHorizontalInset: number = 9
  private static readonly controlsHeight: number = 64

  build() {
    Stack() {
      Text(LiveKitResources.localizedString('tuilivekit_comment_emoji_frequently'))
        .fontSize(12)
        .height(22)
        .fontColor(rgba(0, 0, 0, 0.48))
        .position({ left: 16, top: BarrageEmojiPanelView.titleTop })

      Grid(this.scroller) {
        ForEach(BarrageEmoji.all, (emoji: BarrageEmoji) => {
          GridItem() {
            Stack() {
              BarrageEmojiCell({
                emoji: emoji,
                onSelect: (selected: BarrageEmoji) => this.onSelect(selected),
              })
            }
            .width('100%')
            .height(BarrageEmojiPanelView.itemSize)
            .alignContent(Alignment.Center)
          }
          .height(BarrageEmojiPanelView.itemSize)
        }, (emoji: BarrageEmoji) => emoji.token)
      }
      .columnsTemplate(this.columnsTemplate())
      .columnsGap(0)
      .rowsGap(BarrageEmojiPanelView.verticalGap)
      .padding({
        left: BarrageEmojiPanelView.gridHorizontalInset,
        right: BarrageEmojiPanelView.gridHorizontalInset,
        bottom: BarrageEmojiPanelView.controlsHeight + 16
      })
      .scrollBar(BarState.Off)
      .width('100%')
      .height(this.gridHeight())
      .position({ left: 0, top: BarrageEmojiPanelView.contentTop })

      Column()
        .width('100%')
        .height(BarrageEmojiPanelView.controlsHeight + this.safeBottom)
        .linearGradient({
          angle: 180,
          colors: [
            [rgba(1, 1, 1, 0), 0],
            [Color.White, 0.2],
            [Color.White, 1],
          ],
        })
        .position({ left: 0, bottom: 0 })
        .onClick(() => {})

      Stack() {
        Image(LiveKitResources.image('livekit_comment_page_down'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      }
      .width(32)
      .height(34)
      .alignContent(Alignment.Center)
      .position({ left: 10, bottom: this.safeBottom })
      .onClick(() => this.pageDown())

      Row() {
        Button() {
          Image(LiveKitResources.image('livekit_comment_delete'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        }
        .width(44)
        .height(32)
        .padding(0)
        .backgroundColor('#E4E6EB')
        .borderRadius(8)
        .enabled(this.isDeleteEnabled)
        .opacity(this.isDeleteEnabled ? 1 : 0.45)
        .onClick(() => this.onDelete())

        Button(LiveKitResources.localizedString('tuilivekit.player.comment.send'))
          .width(64)
          .height(32)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundImage(LiveKitResources.image('livekit_comment_send_background'))
          .backgroundImageSize(ImageSize.FILL)
          .borderRadius(8)
          .enabled(this.isSendEnabled)
          .opacity(this.isSendEnabled ? 1 : 0.45)
          .onClick(() => this.onSend())
          .margin({ left: 8 })
      }
      .height(32)
      .alignItems(VerticalAlign.Center)
      .position({ right: 10, bottom: this.safeBottom + 1 })
    }
    .width('100%')
    .height(Math.max(0, this.contentHeight) + this.safeBottom)
    .backgroundColor(Color.White)
    .clip(true)
  }

  private columnsTemplate(): string {
    let template = ''
    for (let index = 0; index < BarrageEmojiPanelView.columnCount; index++) {
      template += index === 0 ? '1fr' : ' 1fr'
    }
    return template
  }

  private gridHeight(): number {
    return Math.max(0, this.contentHeight - BarrageEmojiPanelView.contentTop)
  }

  private pageDown(): void {
    const gridHeight = this.gridHeight()
    if (gridHeight <= 0) {
      return
    }
    const rows = Math.ceil(BarrageEmoji.all.length / BarrageEmojiPanelView.columnCount)
    const contentHeight = rows * BarrageEmojiPanelView.itemSize +
      Math.max(0, rows - 1) * BarrageEmojiPanelView.verticalGap + BarrageEmojiPanelView.controlsHeight + 16
    const visibleHeight = Math.max(0, gridHeight - BarrageEmojiPanelView.controlsHeight)
    const maximumOffset = Math.max(0, contentHeight - gridHeight)
    const currentOffset = this.scroller.currentOffset().yOffset
    const targetOffset = Math.min(currentOffset + visibleHeight, maximumOffset)
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: targetOffset,
      animation: { duration: 250, curve: Curve.EaseInOut },
    })
  }
}
