// RadioButton.ets — circle + label, aligned with iOS RadioButton.swift.

@Component
export struct RadioButton {
  @Prop selected: boolean = false;
  @Prop title: ResourceStr = '';
  onTap: () => void = () => {};

  build() {
    Row({ space: 8 }) {
      Stack() {
        Circle()
          .width(16)
          .height(16)
          .fill(Color.Transparent)
          .stroke(this.selected ? '#006EFF' : '#CCCCCC')
          .strokeWidth(1.5);

        if (this.selected) {
          Circle()
            .width(8)
            .height(8)
            .fill('#006EFF');
        }
      }
      .width(18)
      .height(18);

      Text(this.title)
        .fontSize(16)
        .fontColor(this.selected ? '#006EFF' : '#333333');
    }
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.onTap());
  }
}
