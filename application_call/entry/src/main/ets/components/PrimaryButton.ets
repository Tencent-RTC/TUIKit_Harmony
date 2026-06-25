// PrimaryButton.ets — primary blue action button aligned with iOS callButton.

@Component
export struct PrimaryButton {
  @Prop title: ResourceStr = '';
  @Prop enabledState: boolean = true;
  onTap: () => void = () => {};

  build() {
    Button(this.title, { type: ButtonType.Normal })
      .height(60)
      .width('100%')
      .fontSize(20)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .backgroundColor('#006EFF')
      .borderRadius(10)
      .shadow({
        radius: 16,
        color: 'rgba(0, 110, 255, 0.4)',
        offsetX: 0,
        offsetY: 6,
      })
      .enabled(this.enabledState)
      .opacity(this.enabledState ? 1.0 : 0.5)
      .onClick(() => this.onTap());
  }
}
