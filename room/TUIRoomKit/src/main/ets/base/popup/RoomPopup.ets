import { inputMethod } from '@kit.IMEKit'
import { RoomSafeArea } from '../util/RoomSafeArea'

export enum RoomPopupContentHeight {
  FILL,
  AUTO,
}

export enum RoomPopupDismissReason {
  MASK,
  DRAG,
}

@Component
export struct RoomPopup {
  @Prop @Watch('onPresentationChanged') isPresented: boolean = false
  @Prop heightFraction: number = 0.84
  @Prop contentHeight: RoomPopupContentHeight = RoomPopupContentHeight.FILL
  @Prop panelBackgroundColor: ResourceColor = $r('app.color.roomkit_bg_surface')
  @Prop panelBorderWidth: number = 1
  @Prop panelBorderColor: ResourceColor = $r('app.color.roomkit_popup_border')
  @Prop showsHandleBar: boolean = true
  onDismiss?: (reason: RoomPopupDismissReason) => void
  @BuilderParam content: () => void
  @State private isShowing: boolean = false
  @State private offsetY: number = 0
  @State private dimmingOpacity: number = 0
  @State private rootHeight: number = 0
  private isMounted: boolean = false
  private isContentLaidOut: boolean = false
  private presentationRevision: number = 0
  private presentTask: number = -1

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
  }

  private onPresentationChanged(): void {
    this.isPresented ? this.present() : this.dismiss()
  }

  private panelHeight(): number | undefined {
    return this.contentHeight === RoomPopupContentHeight.FILL ? this.rootHeight * this.heightFraction : undefined
  }

  private present(): void {
    this.presentationRevision++
    clearTimeout(this.presentTask)
    this.offsetY = this.panelHeight() ?? this.rootHeight
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
    this.getUIContext().animateTo({
      duration: 200,
      curve: Curve.EaseIn,
      onFinish: () => {
        if (!this.isMounted || this.isPresented || revision !== this.presentationRevision) {
          return
        }
        this.isShowing = false
        this.isContentLaidOut = false
        this.offsetY = 0
      },
    }, () => {
      this.dimmingOpacity = 0
      this.offsetY = this.panelHeight() ?? this.rootHeight
    })
  }

  private dragEnd(): void {
    if (this.offsetY > 80) {
      this.onDismiss?.(RoomPopupDismissReason.DRAG)
      return
    }
    this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut }, () => {
      this.offsetY = 0
    })
  }

  build() {
    Column()
      .width(0)
      .height(0)
      .bindContentCover(this.isShowing, this.popupCover(), {
        backgroundColor: Color.Transparent,
        modalTransition: ModalTransition.NONE,
      })
  }

  @Builder
  private popupCover() {
    if (this.isShowing) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.roomkit_scrim'))
          .opacity(this.dimmingOpacity)
          .onClick(() => this.onDismiss?.(RoomPopupDismissReason.MASK))
        Column() {
          if (this.showsHandleBar) {
            Column() {
              Column()
                .width(36)
                .height(4)
                .backgroundColor($r('app.color.roomkit_drag_handle'))
                .borderRadius(999)
            }
            .width('100%')
            .height(20)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
          }
          Column() {
            this.content()
          }
          .width('100%')
          .layoutWeight(this.contentHeight === RoomPopupContentHeight.FILL ? 1 : 0)
        }
        .width('100%')
        .height(this.panelHeight())
        .constraintSize({ maxHeight: this.rootHeight * 0.9 })
        .padding({ bottom: RoomSafeArea.bottomClearance() })
        .backgroundColor(this.panelBackgroundColor)
        .border({
          width: { top: this.panelBorderWidth, left: this.panelBorderWidth, right: this.panelBorderWidth },
          color: this.panelBorderColor,
        })
        .borderRadius({ topLeft: 16, topRight: 16 })
        .translate({ y: this.offsetY })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            inputMethod.getController().stopInputSession()
          }
        })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical, distance: 12 })
            .onActionUpdate((event: GestureEvent) => {
              this.offsetY = Math.max(0, event.offsetY)
            })
            .onActionEnd(() => this.dragEnd())
        )
        .onAreaChange((_: Area, area: Area) => {
          if (!this.isContentLaidOut && Number(area.width) > 0 && Number(area.height) > 0) {
            this.isContentLaidOut = true
            this.schedulePresentAnimation()
          }
        })
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onAreaChange((_: Area, area: Area) => {
        const isInitialLayout = this.rootHeight === 0
        this.rootHeight = Number(area.height)
        if (isInitialLayout && this.isPresented) {
          this.offsetY = this.panelHeight() ?? this.rootHeight
        }
      })
    }
  }
}
