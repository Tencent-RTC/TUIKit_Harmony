// ListRow.ets — generic white list row with left label and a right-aligned slot.

@Component
export struct ListRow {
  @Prop label: ResourceStr = '';
  @Prop showDivider: boolean = true;
  @BuilderParam trailing: () => void = this.emptyTrailing;

  @Builder emptyTrailing() {}

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        this.trailing();
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White);

      if (this.showDivider) {
        Divider()
          .color('#EEEEEE')
          .strokeWidth(1)
          .width('100%');
      }
    }
    .width('100%');
  }
}
