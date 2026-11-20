import { LiveInfo } from '@tencentcloud/atomicxcore'

@Component
export struct LiveHomeRoomTransition {
  @Prop coverURL: string = ''
  @Prop info: LiveInfo = new LiveInfo()
  @Prop canvasWidth: number = 1
  @Prop canvasHeight: number = 1
  @Prop sourceX: number = 0
  @Prop sourceY: number = 0
  @Prop sourceWidth: number = 1
  @Prop sourceHeight: number = 1
  onReady: () => void = () => {}
  onFinish: () => void = () => {}
  @State private expanded: boolean = false
  @State private faded: boolean = false
  private timer: number = -1
  private started: boolean = false
  private alive: boolean = false

  aboutToAppear(): void { this.alive = true }
  aboutToDisappear(): void { this.alive = false; clearTimeout(this.timer) }

  private start(): void {
    if (this.started || this.canvasWidth <= 1 || this.canvasHeight <= 1) { return }
    this.started = true
    this.timer = setTimeout(() => {
      if (!this.alive) { return }
      this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseInOut, onFinish: () => {
        if (!this.alive) { return }
        this.onReady()
        this.getUIContext().animateTo({ duration: 120, curve: Curve.EaseOut, onFinish: () => {
          if (this.alive) { this.onFinish() }
        } }, () => this.faded = true)
      } }, () => this.expanded = true)
    }, 16)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(this.coverURL).width('100%').height('100%').objectFit(ImageFit.Cover)
        .backgroundColor('#29364A')
        .scale({ x: this.expanded ? 1 : this.sourceWidth / Math.max(1, this.canvasWidth),
          y: this.expanded ? 1 : this.sourceHeight / Math.max(1, this.canvasHeight) })
        .translate({ x: this.expanded ? 0 : this.sourceX + this.sourceWidth / 2 - this.canvasWidth / 2,
          y: this.expanded ? 0 : this.sourceY + this.sourceHeight / 2 - this.canvasHeight / 2 })
        .opacity(this.faded ? 0 : 1)
        Row({ space: 5 }) {
          Column().width(8).height(8).borderRadius(4).backgroundColor('#FF3845')
          Text(`${this.info.totalViewerCount}`).fontSize(14).fontColor(Color.White)
        }.position({ x: this.sourceX + 8, y: this.sourceY + 8 }).opacity(this.expanded ? 0 : 1)
        Column({ space: 6 }) {
          Text(this.info.liveName || $r('app.string.app_untitled')).fontSize(16).fontWeight(600)
            .fontColor(Color.White).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
          Row({ space: 4 }) {
            Image(this.info.liveOwner.avatarURL).width(20).height(20).borderRadius(10).objectFit(ImageFit.Cover)
            Text(this.info.liveOwner.userName || $r('app.string.app_unknown_host')).fontSize(12)
              .fontColor('#B3FFFFFF').maxLines(1).layoutWeight(1)
          }
        }.width(Math.max(0, this.sourceWidth - 16))
          .position({ x: this.sourceX + 8, y: this.sourceY + this.sourceHeight - 55 })
          .opacity(this.expanded ? 0 : 1)
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      .onAreaChange((old: Area, area: Area) => this.start())
  }
}
