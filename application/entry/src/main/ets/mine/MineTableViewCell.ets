@Component
export struct MineTableViewCell {
  title: Resource = $r('app.string.app_settings')
  icon: Resource = $r('app.media.mine_settings')
  onSelect: () => void = () => {}

  build() {
    Row({ space: 20 }) {
      Image(this.icon).width(24).height(24).objectFit(ImageFit.Contain)
      Text(this.title).fontSize(14).fontWeight(600).fontColor(Color.Black).layoutWeight(1).maxLines(1)
      Image($r('app.media.mine_detail')).width(18).height(18).objectFit(ImageFit.Contain)
    }.width('100%').height(58).padding({ left: 20, right: 20 }).onClick(() => this.onSelect())
  }
}
