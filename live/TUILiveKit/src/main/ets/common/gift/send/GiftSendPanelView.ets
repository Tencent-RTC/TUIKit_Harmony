import { LiveKitResources, LiveKitSafeArea } from '../../LiveKitResources'
import { BottomSheetBackgroundView } from '../../theme/BottomSheetBackgroundView'
import { LiveTheme, white } from '../../theme/LiveTheme'
import { GiftGridPageView } from './GiftGridPageView'
import { GiftCategoryGroup, GiftItem } from './GiftSendStore'

const contentHeightAboveSafeArea: number = 348
const underlineInset: number = 6

export class GiftPanelStyle {
  static readonly blue: string = 'rgba(74, 158, 255, 1)'
  static readonly deepBlue: string = 'rgba(0, 82, 217, 1)'
  static readonly coin: string = 'rgba(255, 202, 76, 1)'

  static blueAlpha(alpha: number): string {
    return `rgba(74, 158, 255, ${alpha})`
  }
}

@Component
export struct GiftSendPanelView {
  @Prop @Watch('onPresentedChanged') isPresented: boolean = false
  onDismiss?: () => void
  @Prop @Watch('onCategoriesChanged') categories: GiftCategoryGroup[] = []
  @Prop isLoading: boolean = false
  onSendGift?: (gift: GiftItem, count: number) => void
  onPresentationChanged?: (isPresented: boolean, heightAboveSafeArea: number) => void
  onAdvancedComboStart?: (gift: GiftItem) => void
  @StorageProp(LiveKitSafeArea.bottomKey) safeBottom: number = 0
  @State private isShowing: boolean = false
  @State private offsetY: number = 0
  @State private dimmingOpacity: number = 0
  @State private selectedCategoryIndex: number = 0
  @State private selectedGiftID: string = ''
  @State private comboGiftID: string = ''
  @State private tabTextWidths: number[] = []
  private swiperController: SwiperController = new SwiperController()
  private tabsScroller: Scroller = new Scroller()

  private panelHeight(): number {
    return contentHeightAboveSafeArea + this.safeBottom
  }

  private onCategoriesChanged(): void {
    if (this.selectedCategoryIndex >= this.categories.length) {
      this.selectedCategoryIndex = 0
    }
    const gifts = this.categories.flatMap((group: GiftCategoryGroup) => group.gifts)
    if (!gifts.some((gift: GiftItem) => gift.id === this.selectedGiftID)) {
      this.selectedGiftID = ''
    }
    if (!gifts.some((gift: GiftItem) => gift.id === this.comboGiftID)) {
      this.comboGiftID = ''
    }
  }

  private onPresentedChanged(): void {
    this.isPresented ? this.present() : this.dismiss()
  }

  private present(): void {
    if (this.isShowing) {
      return
    }
    this.isShowing = true
    this.onPresentationChanged?.(true, contentHeightAboveSafeArea)
    this.offsetY = this.panelHeight()
    this.dimmingOpacity = 0
    this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.dimmingOpacity = 1
      this.offsetY = 0
    })
  }

  private dismiss(): void {
    if (!this.isShowing) {
      return
    }
    this.getUIContext().animateTo({
      duration: 200, curve: Curve.EaseIn, onFinish: () => {
        this.isShowing = false
        this.offsetY = 0
        this.selectedGiftID = ''
        this.comboGiftID = ''
        this.onPresentationChanged?.(false, contentHeightAboveSafeArea)
      }
    }, () => {
      this.dimmingOpacity = 0
      this.offsetY = this.panelHeight()
    })
  }

  private selectCategory(index: number): void {
    if (index < 0 || index >= this.categories.length) {
      return
    }
    if (index !== this.selectedCategoryIndex) {
      this.selectedCategoryIndex = index
      this.comboGiftID = ''
      this.selectedGiftID = ''
    }
    this.swiperController.changeIndex(index, true)
  }

  private handleCellTapped(gift: GiftItem): void {
    this.comboGiftID = ''
    if (this.selectedGiftID !== gift.id) {
      this.selectedGiftID = gift.id
      return
    }
    this.selectedGiftID = ''
    if (gift.resourceURL.length > 0) {
      this.onAdvancedComboStart?.(gift)
      this.onDismiss?.()
    } else {
      this.comboGiftID = gift.id
    }
  }

  private handleComboExpired(): void {
    if (this.comboGiftID.length === 0) {
      return
    }
    this.selectedGiftID = this.comboGiftID
    this.comboGiftID = ''
  }

  private updateTabTextWidth(index: number, width: number): void {
    if (this.tabTextWidths[index] === width) {
      return
    }
    const widths = this.tabTextWidths.slice()
    widths[index] = width
    this.tabTextWidths = widths
  }

  private underlineWidth(index: number): number {
    return Math.max((this.tabTextWidths[index] ?? 0) - underlineInset * 2, 0)
  }

  @Builder
  categoryTabs() {
    Scroll(this.tabsScroller) {
      Row({ space: 24 }) {
        ForEach(this.categories, (category: GiftCategoryGroup, index: number) => {
          Stack({ alignContent: Alignment.Bottom }) {
            Text(category.name)
              .fontSize(14)
              .fontWeight(index === this.selectedCategoryIndex ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(index === this.selectedCategoryIndex ? Color.White : white(0.5))
              .padding({ left: 1, right: 1 })
              .height('100%')
              .onAreaChange((_: Area, area: Area) => this.updateTabTextWidth(index, area.width as number))
            if (index === this.selectedCategoryIndex && this.underlineWidth(index) > 0) {
              Column()
                .height(2)
                .width(this.underlineWidth(index))
                .borderRadius(1)
                .linearGradient({ angle: 90, colors: [[GiftPanelStyle.blue, 0], [GiftPanelStyle.deepBlue, 1]] })
            }
          }
          .height('100%')
          .onClick(() => this.selectCategory(index))
        }, (category: GiftCategoryGroup) => category.id)
      }
      .height('100%')
      .padding({ left: 17, right: 17 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .align(Alignment.Start)
    .width('100%')
    .height(32)
    .margin({ top: 10 })
  }

  build() {
    if (this.isShowing) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(LiveTheme.Color.sheetScrim)
          .opacity(this.dimmingOpacity)
          .onClick(() => this.onDismiss?.())
        Stack({ alignContent: Alignment.Top }) {
          BottomSheetBackgroundView()
          Column() {
            Text(LiveKitResources.localizedString('tuilivekit.player.gift.title'))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(white(0.94))
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(32)
              .margin({ top: 14 })
            this.categoryTabs()
            Stack() {
              Swiper(this.swiperController) {
                ForEach(this.categories, (category: GiftCategoryGroup) => {
                  GiftGridPageView({
                    gifts: category.gifts,
                    selectedGiftID: this.selectedGiftID,
                    comboGiftID: this.comboGiftID,
                    onCellTapped: (gift: GiftItem) => this.handleCellTapped(gift),
                    onComboSend: (gift: GiftItem) => this.onSendGift?.(gift, 1),
                    onComboExpired: () => this.handleComboExpired(),
                  })
                }, (category: GiftCategoryGroup) => category.id)
              }
              .index(this.selectedCategoryIndex)
              .loop(false)
              .indicator(false)
              .width('100%')
              .height('100%')
              .onChange((index: number) => {
                if (index !== this.selectedCategoryIndex) {
                  this.selectedCategoryIndex = index
                  this.comboGiftID = ''
                  this.selectedGiftID = ''
                  this.tabsScroller.scrollToIndex(index, true)
                }
              })
              if (this.isLoading && this.categories.length === 0) {
                LoadingProgress().width(24).height(24).color(white(0.7))
              } else if (!this.isLoading && this.categories.length === 0) {
                Text(LiveKitResources.localizedString('tuilivekit.player.gift.empty'))
                  .fontSize(14)
                  .fontColor(white(0.5))
                  .textAlign(TextAlign.Center)
                  .padding({ left: 24, right: 24 })
              }
            }
            .width('100%')
            .layoutWeight(1)
            .margin({ top: 10, bottom: this.safeBottom + 20 })
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height(this.panelHeight())
        .translate({ y: this.offsetY })
      }
      .width('100%')
      .height('100%')
    }
  }
}
