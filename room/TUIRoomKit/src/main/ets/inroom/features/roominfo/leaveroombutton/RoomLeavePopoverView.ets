export enum RoomLeavePopoverAlign {
  START,
  CENTER,
  END,
}

@Component
export struct RoomLeavePopoverView {
  @Prop isPresented: boolean = false
  @Prop popoverAlign: RoomLeavePopoverAlign = RoomLeavePopoverAlign.CENTER
  @Prop gap: number = 10
  @Prop minWidth: number = 176
  @Prop showsArrow: boolean = false
  onClose?: () => void
  @BuilderParam anchor: () => void
  @BuilderParam content: () => void

  private placement(): Placement {
    switch (this.popoverAlign) {
      case RoomLeavePopoverAlign.START: return Placement.BottomLeft
      case RoomLeavePopoverAlign.END: return Placement.BottomRight
      default: return Placement.Bottom
    }
  }

  @Builder
  popupContent() {
    Column() {
      Column() {
        this.content()
      }
      .width(this.minWidth)
    }
    .padding(9)
    .backgroundColor($r('app.color.roomkit_bg_popover_solid'))
    .border({ width: 1, color: $r('app.color.roomkit_popup_border') })
    .borderRadius(10)
  }

  build() {
    Column() {
      this.anchor()
    }
    .bindPopup(this.isPresented, {
      builder: this.popupContent,
      placement: this.placement(),
      targetSpace: this.gap,
      mask: { color: Color.Transparent },
      popupColor: $r('app.color.roomkit_bg_popover_solid'),
      enableArrow: this.showsArrow,
      radius: 10,
      shadow: { radius: 12, color: $r('app.color.roomkit_shadow_lg'), offsetY: 8 },
      onStateChange: (event) => {
        if (!event.isVisible) {
          this.onClose?.()
        }
      },
    })
  }
}
