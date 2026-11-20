@Component
export struct LiveHomeHeaderView {
  @Prop preview: boolean = false
  @StorageProp('currentLanguage') private language: string = ''
  @State private containerWidth: number = 0
  onMode: (preview: boolean) => void = () => {}
  onStart: () => void = () => {}

  build() {
    Row({ space: 12 }) {
      Text($r('app.string.app_online_live')).fontSize(24).fontWeight(600).fontColor(Color.White)
        .maxLines(1).minFontSize(16.8).maxFontSize(24).layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Stack() {
        Row({ space: 2 }) {
          Column().layoutWeight(1).height(30).borderRadius(8)
            .backgroundColor(!this.preview ? '#424754' : Color.Transparent)
          Column().layoutWeight(1).height(30).borderRadius(8)
            .backgroundColor(this.preview ? '#24FFFFFF' : Color.Transparent)
        }.width('100%').height(36).padding(3)
          .backgroundColor(this.preview ? '#14000000' : '#20232C')
          .backdropBlur(this.preview ? 12 : 0).borderRadius(11)
          .border({ width: this.preview ? 1 : 0, color: '#1FFFFFFF' })
        Row() {
          Text($r('app.string.app_grid')).fontSize(13).fontWeight(!this.preview ? 600 : 500)
            .fontColor(!this.preview ? Color.White : '#C7FFFFFF').layoutWeight(1).height(44)
            .textAlign(TextAlign.Center).onClick(() => this.onMode(false))
          Text($r('app.string.app_preview')).fontSize(13).fontWeight(this.preview ? 600 : 500)
            .fontColor(this.preview ? Color.White : '#A0A7B5').layoutWeight(1).height(44)
            .textAlign(TextAlign.Center).onClick(() => this.onMode(true))
        }.width('100%')
      }.height(44).width(Math.min(132, Math.max(100, this.containerWidth - 248)))
      Stack() {
        Row({ space: 6 }) {
          Image($r('app.media.home_live_start')).width(18).height(18).objectFit(ImageFit.Contain)
          Text($r('app.string.app_start')).fontSize(14).fontWeight(500).fontColor('#E6FFFFFF')
            .maxLines(1).minFontSize(11.2).maxFontSize(14).layoutWeight(1)
        }.width(this.language.startsWith('zh') ? 72 : 92).height(36)
          .padding({ left: 10, right: 10 }).borderRadius(10)
          .backgroundColor(this.preview ? '#0F000000' : '#0DFFFFFF').backdropBlur(this.preview ? 12 : 0)
          .border({ width: 1, color: '#1AFFFFFF' })
      }.width(this.language.startsWith('zh') ? 80 : 100).height(44).onClick(() => this.onStart())
    }.width('100%').height(56).padding({ left: 16, right: 12 })
      .backgroundColor(this.preview ? Color.Transparent : $r('app.color.app_live_background'))
      .onAreaChange((old: Area, area: Area) => {
        const width = area.width as number
        if (this.containerWidth !== width) { this.containerWidth = width }
      })
  }
}
