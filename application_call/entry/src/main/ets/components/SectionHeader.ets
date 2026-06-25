// SectionHeader.ets — gray group header bar, aligned with iOS basicSettingContentView (#AAAAAA).

@Component
export struct SectionHeader {
  @Prop title: ResourceStr = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor('#000000');
    }
    .width('100%')
    .height(30)
    .backgroundColor('#AAAAAA')
    .padding({ left: 20, right: 20 })
    .alignItems(VerticalAlign.Center);
  }
}
