@Component
export struct MainMenuCard {
  icon: Resource = $r('app.media.main_call');
  title: Resource | string = '';
  desc: Resource | string = '';

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#FFCCDEFF', 0], ['#4DCCDEFF', 0.5], ['#00CCDEFF', 1]]
        })
        .borderRadius(6)

      Column() {
        Row() {
          Image(this.icon)
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)

          Text(this.title)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#262B32')
            .margin({ left: 2 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.desc)
          .fontSize(12)
          .fontColor('#626E84')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 12 })
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 14, right: 14, top: 16, bottom: 14 })
      .backgroundColor('#CCFFFFFF')
      .borderRadius(6)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height(106)
    .borderRadius(6)
  }
}
