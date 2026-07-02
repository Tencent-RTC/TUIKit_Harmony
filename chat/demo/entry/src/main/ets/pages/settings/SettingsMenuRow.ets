/**
 * 设置页菜单行，对齐 Android `SuperTextView` + `InfoItem.Account` 样式。
 */
@Component
export struct SettingsMenuRow {
  @Prop title: string = '';
  @Prop rightText: string = '';
  @Prop showArrow: boolean = true;
  @Prop showNewBadge: boolean = false;
  @Prop isFirst: boolean = false;
  @Prop isLast: boolean = false;
  onTap?: () => void;

  build() {
    Row() {
      Text(this.title)
        .fontSize(16)
        .fontColor('#000000')
        .layoutWeight(1)

      if (this.rightText.length > 0) {
        Text(this.rightText)
          .fontSize(14)
          .fontColor('#8a8a8a')
          .margin({ right: 4 })
      }

      if (this.showNewBadge) {
        Circle()
          .width(8)
          .height(8)
          .fill('#FF3B30')
          .margin({ right: 6 })
      }

      if (this.showArrow) {
        Text('›')
          .fontSize(20)
          .fontColor('#8a8a8a')
          .margin({ top: -1 })
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius({
      topLeft: this.isFirst ? 10 : 0,
      topRight: this.isFirst ? 10 : 0,
      bottomLeft: this.isLast ? 10 : 0,
      bottomRight: this.isLast ? 10 : 0,
    })
    .onClick(() => {
      if (this.onTap !== undefined) {
        this.onTap();
      }
    })
  }
}
