@Component
export struct AppPageHeader {
  title: Resource = $r('app.string.app_brand')
  @Prop saving: boolean = false
  @Prop showSave: boolean = false
  @Prop canSave: boolean = false
  onBack: () => void = () => {}
  onSave: () => void = () => {}

  build() {
    Stack() {
      Text(this.title).fontSize(18).fontWeight(600).fontColor(Color.Black).maxLines(1)
        .constraintSize({ maxWidth: '60%' })
      Row() {
        Image($r('app.media.mine_back')).width(44).height(44).padding(13).objectFit(ImageFit.Contain)
          .onClick(() => this.onBack())
        Blank()
        if (this.showSave) {
          Button($r('app.string.app_save')).fontSize(14).height(44).backgroundColor(Color.Transparent)
            .fontColor(this.canSave ? $r('app.color.app_primary') : $r('app.color.app_secondary'))
            .enabled(this.canSave && !this.saving).onClick(() => this.onSave())
        }
      }.width('100%')
    }.width('100%').height(44).backgroundColor(Color.White)
  }
}
