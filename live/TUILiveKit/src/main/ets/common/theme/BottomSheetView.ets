import { BottomSheetBackgroundView } from './BottomSheetBackgroundView'
import { LiveText } from './LiveText'
import { LiveTheme } from './LiveTheme'

const presentedPanels: Set<() => void> = new Set()

export function dismissAllBottomSheets(): void {
  Array.from(presentedPanels).forEach((dismiss: () => void) => dismiss())
}

@Component
export struct BottomSheetView {
  @Prop @Watch('onPresentationChanged') isPresented: boolean = false
  onDismiss?: () => void
  @Prop sheetHeight: number = 0
  @Prop sheetTitle: string = ''
  isDismissibleByTappingOutside: boolean = true
  sheetWillPresent?: () => void
  sheetWillDismiss?: () => void
  sheetDidDismiss?: () => void
  @BuilderParam content: () => void
  @State private isShowing: boolean = false
  @State private offsetY: number = 0
  @State private dimmingOpacity: number = 0
  private isMounted: boolean = false
  private isContentLaidOut: boolean = false
  private presentationRevision: number = 0
  private presentTask: number = -1
  private readonly dismissHandle: () => void = () => {
    this.onDismiss?.()
  }

  aboutToAppear(): void {
    this.isMounted = true
    if (this.isPresented) {
      this.present()
    }
  }

  aboutToDisappear(): void {
    this.isMounted = false
    this.presentationRevision++
    clearTimeout(this.presentTask)
    presentedPanels.delete(this.dismissHandle)
    if (this.isShowing && this.isPresented) {
      this.sheetWillDismiss?.()
    }
    this.isContentLaidOut = false
  }

  private onPresentationChanged(): void {
    this.isPresented ? this.present() : this.dismiss()
  }

  private present(): void {
    this.presentationRevision++
    clearTimeout(this.presentTask)
    presentedPanels.add(this.dismissHandle)
    this.sheetWillPresent?.()
    this.offsetY = this.sheetHeight
    this.dimmingOpacity = 0
    this.isShowing = true
    this.schedulePresentAnimation()
  }

  private schedulePresentAnimation(): void {
    if (!this.isContentLaidOut || !this.isPresented || !this.isMounted) {
      return
    }
    clearTimeout(this.presentTask)
    const revision = this.presentationRevision
    this.presentTask = setTimeout(() => {
      if (!this.isMounted || !this.isPresented || revision !== this.presentationRevision) {
        return
      }
      this.presentTask = -1
      this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
        this.dimmingOpacity = 1
        this.offsetY = 0
      })
    }, 0)
  }

  private dismiss(): void {
    if (!this.isShowing) {
      return
    }
    const revision = ++this.presentationRevision
    clearTimeout(this.presentTask)
    presentedPanels.delete(this.dismissHandle)
    this.sheetWillDismiss?.()
    this.getUIContext().animateTo({
      duration: 200, curve: Curve.EaseIn, onFinish: () => {
        if (!this.isMounted || this.isPresented || revision !== this.presentationRevision) {
          return
        }
        this.isShowing = false
        this.isContentLaidOut = false
        this.offsetY = 0
        this.sheetDidDismiss?.()
      }
    }, () => {
      this.dimmingOpacity = 0
      this.offsetY = this.sheetHeight
    })
  }

  build() {
    if (this.isShowing) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(LiveTheme.Color.sheetScrim)
          .opacity(this.dimmingOpacity)
          .onClick(() => {
            if (this.isDismissibleByTappingOutside) {
              this.onDismiss?.()
            }
          })
        Stack({ alignContent: Alignment.TopStart }) {
          BottomSheetBackgroundView()
          if (this.sheetTitle.length > 0) {
            Text(this.sheetTitle)
              .attributeModifier(
                new LiveText(LiveTheme.TextRole.sheetTitle, LiveTheme.TextTone.primary, TextAlign.Center))
              .width('100%')
              .height(18)
              .padding({ left: 16, right: 16 })
              .margin({ top: 30 })
          }
          this.content()
        }
        .width('100%')
        .height(this.sheetHeight)
        .animation({ duration: 220, curve: Curve.EaseInOut })
        .translate({ y: this.offsetY })
        .onAreaChange((_: Area, area: Area) => {
          if (!this.isContentLaidOut && Number(area.width) > 0 && Number(area.height) > 0) {
            this.isContentLaidOut = true
            this.schedulePresentAnimation()
          }
        })
      }
      .width('100%')
      .height('100%')
    }
  }
}
