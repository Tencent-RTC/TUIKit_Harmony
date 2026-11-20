import { inputMethod } from '@kit.IMEKit'

export enum RoomDialogVariant {
  PRIMARY,
  GHOST,
  DANGER,
}

@Component
export struct RoomDialog {
  @Prop @Watch('onPresentationChanged') isPresented: boolean = false
  @Prop title: string = ''
  @Prop message: string = ''
  @Prop closable: boolean = false
  @Prop cancelable: boolean = true
  @Prop primaryText: string = ''
  @Prop primaryVariant: RoomDialogVariant = RoomDialogVariant.PRIMARY
  @Prop secondaryText: string = ''
  @Prop keepsOpenOnPrimary: boolean = false
  @Prop inputFocusID: string = ''
  onPrimary?: () => void
  onSecondary?: () => void
  onCancel?: () => void
  onDismiss?: () => void
  @BuilderParam content?: () => void

  aboutToAppear(): void {
    if (this.isPresented) {
      this.focusInput()
    }
  }

  private onPresentationChanged(): void {
    if (this.isPresented) {
      this.focusInput()
    }
  }

  private focusInput(): void {
    if (this.inputFocusID.length === 0) {
      return
    }
    setTimeout(() => {
      if (this.isPresented) {
        this.getUIContext().getFocusController().requestFocus(this.inputFocusID)
      }
    }, 0)
  }

  private cancel(): void {
    this.onCancel?.()
    this.onDismiss?.()
  }

  private primaryAction(): void {
    this.onPrimary?.()
    if (!this.keepsOpenOnPrimary) {
      this.onDismiss?.()
    }
  }

  private secondaryAction(): void {
    this.onSecondary?.()
    this.onDismiss?.()
  }

  private normalColor(variant: RoomDialogVariant): ResourceColor {
    switch (variant) {
      case RoomDialogVariant.GHOST: return $r('app.color.roomkit_bg_hover')
      case RoomDialogVariant.DANGER: return $r('app.color.roomkit_danger')
      default: return $r('app.color.roomkit_accent')
    }
  }

  private pressedColor(variant: RoomDialogVariant): ResourceColor {
    switch (variant) {
      case RoomDialogVariant.GHOST: return $r('app.color.roomkit_bg_press')
      case RoomDialogVariant.DANGER: return $r('app.color.roomkit_danger_pressed')
      default: return $r('app.color.roomkit_accent_soft')
    }
  }

  private textColor(variant: RoomDialogVariant): ResourceColor {
    switch (variant) {
      case RoomDialogVariant.GHOST: return $r('app.color.roomkit_fg_primary')
      case RoomDialogVariant.DANGER: return $r('app.color.roomkit_fg_on_danger')
      default: return $r('app.color.roomkit_fg_on_accent')
    }
  }

  @Builder
  actionButton(text: string, variant: RoomDialogVariant, action: () => void) {
    Button(text)
      .layoutWeight(1)
      .height(40)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.textColor(variant))
      .backgroundColor(this.normalColor(variant))
      .borderRadius(8)
      .stateStyles({
        pressed: {
          .backgroundColor(this.pressedColor(variant))
        },
        normal: {
          .backgroundColor(this.normalColor(variant))
        },
      })
      .onClick(action)
  }

  build() {
    Column()
      .width(0)
      .height(0)
      .bindContentCover(this.isPresented, this.dialogCover(), {
        backgroundColor: Color.Transparent,
        modalTransition: ModalTransition.NONE,
      })
  }

  @Builder
  private dialogCover() {
    Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.roomkit_scrim'))
          .onClick(() => {
            if (this.cancelable) {
              this.cancel()
            } else {
              inputMethod.getController().stopInputSession()
            }
          })
        Stack({ alignContent: Alignment.Center }) {
          Column() {
            if (this.title.length > 0 || this.closable) {
              Row() {
                if (this.title.length > 0) {
                  Text(this.title)
                    .layoutWeight(1)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.roomkit_fg_primary'))
                    .textAlign(this.closable ? TextAlign.Start : TextAlign.Center)
                }
                if (this.closable) {
                  Button() {
                    Image($r('app.media.roomkit_icon_close')).width(16).height(16)
                  }
                  .width(28)
                  .height(28)
                  .padding(6)
                  .margin({ left: 8 })
                  .backgroundColor(Color.Transparent)
                  .onClick(() => this.cancel())
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }
            if (this.message.length > 0) {
              Text(this.message)
                .width('100%')
                .fontSize(13)
                .lineHeight(19)
                .fontColor($r('app.color.roomkit_fg_secondary'))
                .textAlign(this.closable ? TextAlign.Start : TextAlign.Center)
                .margin({ top: this.title.length > 0 || this.closable ? 8 : 0 })
            }
            if (this.content !== undefined) {
              Column() {
                this.content()
              }
              .width('100%')
              .margin({ top: this.title.length > 0 || this.message.length > 0 || this.closable ? 12 : 0 })
            }
            if (this.primaryText.length > 0 || this.secondaryText.length > 0) {
              Row({ space: 8 }) {
                if (this.secondaryText.length > 0) {
                  this.actionButton(this.secondaryText, RoomDialogVariant.GHOST, () => this.secondaryAction())
                }
                if (this.primaryText.length > 0) {
                  this.actionButton(this.primaryText, this.primaryVariant, () => this.primaryAction())
                }
              }
              .width('100%')
              .margin({ top: 16 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 18, bottom: 14 })
          .backgroundColor($r('app.color.roomkit_bg_surface'))
          .borderRadius(12)
          .onClick(() => inputMethod.getController().stopInputSession())
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
      .width('100%')
      .height('100%')
      .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
  }
}
