import { RoomResources } from '../../../base/util/RoomResources'

@Component
export struct RoomPageIndicatorView {
  @Prop @Watch('onPageChanged') currentPage: number = 0
  @Prop @Watch('onPageCountChanged') pageCount: number = 0
  @Prop @Watch('onStageTap') stageTapRevision: number = 0
  @State private isVisible: boolean = false
  @State private contentOpacity: number = 0
  onPreviousPage?: () => void
  onNextPage?: () => void
  private hideTimer: number = -1
  private removeTimer: number = -1

  aboutToDisappear(): void {
    clearTimeout(this.hideTimer)
    clearTimeout(this.removeTimer)
  }

  private onPageChanged(): void {
    this.show()
  }

  private onPageCountChanged(): void {
    if (this.pageCount > 1) {
      return
    }
    clearTimeout(this.hideTimer)
    clearTimeout(this.removeTimer)
    this.isVisible = false
    this.contentOpacity = 0
  }

  private onStageTap(): void {
    this.toggle()
  }

  private toggle(): void {
    if (this.pageCount <= 1) {
      return
    }
    if (this.isVisible) {
      this.hide()
    } else {
      this.show()
    }
  }

  private show(): void {
    if (this.pageCount <= 1) {
      return
    }
    clearTimeout(this.removeTimer)
    this.isVisible = true
    this.getUIContext().animateTo({ duration: 160 }, () => {
      this.contentOpacity = 1
    })
    clearTimeout(this.hideTimer)
    this.hideTimer = setTimeout(() => this.hide(), 2500)
  }

  private hide(): void {
    clearTimeout(this.hideTimer)
    clearTimeout(this.removeTimer)
    this.getUIContext().animateTo({ duration: 160 }, () => {
      this.contentOpacity = 0
    })
    this.removeTimer = setTimeout(() => {
      this.isVisible = false
    }, 170)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.pageCount > 1 && this.isVisible) {
        Image(RoomResources.image('roomkit_icon_page_arrow_prev'))
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.roomkit_bg_page_indicator'))
          .position({ left: 8, top: '50%' })
          .translate({ y: -16 })
          .opacity(this.contentOpacity * (this.currentPage > 0 ? 1 : 0.22))
          .enabled(this.currentPage > 0)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.onPreviousPage?.()
          })
        Image(RoomResources.image('roomkit_icon_page_arrow_next'))
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor($r('app.color.roomkit_bg_page_indicator'))
          .position({ right: 8, top: '50%' })
          .translate({ y: -16 })
          .opacity(this.contentOpacity * (this.currentPage < this.pageCount - 1 ? 1 : 0.22))
          .enabled(this.currentPage < this.pageCount - 1)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.onNextPage?.()
          })
        Text(RoomResources.string('roomkit_room_view_page_number', this.currentPage + 1, this.pageCount))
          .fontSize(11)
          .fontWeight(500)
          .fontColor($r('app.color.roomkit_fg_on_media'))
          .textAlign(TextAlign.Center)
          .height(20)
          .padding({ left: 8, right: 8 })
          .backgroundColor($r('app.color.roomkit_bg_page_indicator'))
          .borderRadius(8)
          .margin({ bottom: 8 })
          .opacity(this.contentOpacity)
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
