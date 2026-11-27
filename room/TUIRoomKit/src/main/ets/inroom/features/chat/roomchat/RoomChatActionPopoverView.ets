@Component
export struct RoomChatActionPopoverView {
  @Prop isPresented: boolean = false
  onClose?: () => void
  @BuilderParam anchor: () => void
  @BuilderParam content: () => void

  @Builder
  private popupContent() {
    Row() {
      this.content()
    }
    .padding(4)
    .backgroundColor($r('app.color.roomkit_bg_popover_solid'))
    .border({ width: 1, color: $r('app.color.roomkit_border_strong') })
    .borderRadius(14)
  }

  build() {
    Column() {
      this.anchor()
    }
    .bindPopup(this.isPresented, {
      builder: this.popupContent,
      placement: Placement.Top,
      targetSpace: 8,
      arrowPointPosition: ArrowPointPosition.CENTER,
      mask: { color: Color.Transparent },
      popupColor: $r('app.color.roomkit_bg_popover_solid'),
      enableArrow: true,
      radius: 14,
      shadow: { radius: 12, color: $r('app.color.roomkit_shadow_lg'), offsetY: 8 },
      onStateChange: (event) => {
        if (!event.isVisible) {
          this.onClose?.()
        }
      },
    })
  }
}
