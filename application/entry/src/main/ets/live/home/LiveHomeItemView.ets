import { LiveInfo } from '@tencentcloud/atomicxcore'

@Component
export struct LiveHomeItemView {
  @Prop @Watch('infoChanged') info: LiveInfo = new LiveInfo()
  onSelect: (info: LiveInfo, area: Area) => void = () => {}
  private area?: Area
  @State private coverFailed: boolean = false

  private infoChanged(): void { this.coverFailed = false }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.info.coverURL.length > 0 && !this.coverFailed) {
        Image(this.info.coverURL).width('100%').height('100%').objectFit(ImageFit.Cover)
          .onError(() => this.coverFailed = true)
      } else {
        Text($r('app.string.app_cover_unavailable')).fontSize(13).fontColor('#8CFFFFFF')
          .width('100%').height('100%').textAlign(TextAlign.Center)
      }
      Column().width('100%').height('100%').linearGradient({ angle: 180,
        colors: [['#26000000', 0], ['#00000000', 0.45], ['#B3000000', 1]] }).hitTestBehavior(HitTestMode.None)
      Row({ space: 5 }) {
        Column().width(8).height(8).borderRadius(4).backgroundColor('#FF3845')
        Text(`${this.info.totalViewerCount}`).fontSize(14).fontColor(Color.White)
      }.position({ top: 8, left: 8 })
      Column({ space: 6 }) {
        Text(this.info.liveName || $r('app.string.app_untitled')).fontSize(16).fontWeight(600).fontColor(Color.White)
          .width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 4 }) {
          Stack() {
            Text((this.info.liveOwner.userName || this.info.liveOwner.userID).slice(0, 1).toUpperCase())
              .fontSize(10).fontWeight(500).fontColor(Color.White)
            if (this.info.liveOwner.avatarURL.length > 0) {
              Image(this.info.liveOwner.avatarURL).width(20).height(20).objectFit(ImageFit.Cover)
            }
          }.width(20).height(20).borderRadius(10).clip(true).backgroundColor('#26FFFFFF')
          Text(this.info.liveOwner.userName || $r('app.string.app_unknown_host')).fontSize(12).fontColor('#B3FFFFFF')
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }.width('100%').padding(8)
    }.width('100%').height('100%').backgroundColor('#29364A').borderRadius(8).clip(true)
      .onAreaChange((old: Area, area: Area) => this.area = area)
      .onClick(() => { if (this.area !== undefined) { this.onSelect(this.info, this.area) } })
  }
}
