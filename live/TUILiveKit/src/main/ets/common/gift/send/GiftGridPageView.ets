import { LiveKitResources } from '../../LiveKitResources'
import { white } from '../../theme/LiveTheme'
import { GiftSendComboButton } from './GiftSendComboButton'
import { GiftPanelStyle } from './GiftSendPanelView'
import { GiftItem } from './GiftSendStore'

const columns: number = 4
const cellSpacing: number = 4
const rowSpacing: number = 2
const horizontalPadding: number = 10
const rowHeight: number = 104

@Component
struct GiftItemView {
  @Prop gift: GiftItem
  @Prop isSelected: boolean = false

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Image(this.gift.iconURL)
        .width(44)
        .height(44)
        .objectFit(ImageFit.Contain)
        .margin({ top: 10 })
      Column({ space: 2 }) {
        if (!this.isSelected) {
          Text(this.gift.name)
            .fontSize(12)
            .fontWeight(600)
            .fontColor(white(0.94))
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding({ left: 2, right: 2 })
        }
        Row({ space: 4 }) {
          Circle().width(8).height(8).fill(GiftPanelStyle.coin)
          Text(`${this.gift.coins}`)
            .fontSize(10)
            .fontWeight(this.isSelected ? 600 : 400)
            .fontColor(white(0.94))
        }
        if (this.isSelected) {
          Text(LiveKitResources.localizedString('tuilivekit.player.gift.send'))
            .fontSize(12)
            .fontWeight(600)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(22)
            .borderRadius(11)
            .margin({ top: 2 })
            .linearGradient({ angle: 90, colors: [[GiftPanelStyle.blue, 0], [GiftPanelStyle.deepBlue, 1]] })
        }
      }
      .position({ x: 0, y: this.isSelected ? 104 - 6 - 22 - 4 - 14 : 58 })
      .padding({ left: this.isSelected ? 6 : 0, right: this.isSelected ? 6 : 0 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .borderRadius(10)
    .borderWidth(1)
    .borderColor(this.isSelected ? GiftPanelStyle.blueAlpha(0.7) : 'rgba(0,0,0,0)')
    .backgroundColor(this.isSelected ? GiftPanelStyle.blueAlpha(0.15) : 'rgba(0,0,0,0)')
  }
}

@Component
export struct GiftGridPageView {
  @Prop gifts: GiftItem[] = []
  @Prop selectedGiftID: string = ''
  @Prop comboGiftID: string = ''
  onCellTapped?: (gift: GiftItem) => void
  onComboSend?: (gift: GiftItem) => void
  onComboExpired?: () => void
  @State private pageWidth: number = 0

  private cellWidth(): number {
    return Math.floor((this.pageWidth - horizontalPadding * 2 - cellSpacing * (columns - 1)) / columns)
  }

  build() {
    Scroll() {
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.gifts, (gift: GiftItem, index: number) => {
          Stack() {
            if (gift.id === this.comboGiftID) {
              GiftSendComboButton({
                giftID: gift.id,
                iconURL: gift.iconURL,
                onSendOnce: () => this.onComboSend?.(gift),
                onExpired: () => this.onComboExpired?.(),
              })
            } else {
              GiftItemView({ gift: gift, isSelected: gift.id === this.selectedGiftID })
                .onClick(() => this.onCellTapped?.(gift))
            }
          }
          .width(this.cellWidth())
          .height(rowHeight)
          .position({
            x: horizontalPadding + (index % columns) * (this.cellWidth() + cellSpacing),
            y: Math.floor(index / columns) * (rowHeight + rowSpacing) + 6,
          })
        }, (gift: GiftItem) => gift.id)
      }
      .width('100%')
      .height(Math.ceil(this.gifts.length / columns) * (rowHeight + rowSpacing) - rowSpacing + 6 + 14)
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .onAreaChange((_: Area, area: Area) => this.pageWidth = area.width as number)
  }
}
