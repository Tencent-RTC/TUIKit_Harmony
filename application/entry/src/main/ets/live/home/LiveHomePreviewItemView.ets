import { PlayerStatus, PlayerView, PlayerViewController } from 'tuilivekit'
import { LiveHomePlaybackSession } from './LiveHomePreviewView'

@Component
export struct LiveHomePreviewItemView {
  @ObjectLink session: LiveHomePlaybackSession
  @Prop canvasHeight: number = 1
  @Prop viewportHeight: number = 1
  @Prop showPreview: boolean = true
  @Prop coverUntilJoined: boolean = false
  onEnter: (session: LiveHomePlaybackSession) => void = () => {}
  onMounted: (session: LiveHomePlaybackSession) => void = () => {}
  onUnmounted: (session: LiveHomePlaybackSession) => void = () => {}
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0

  aboutToAppear(): void { this.onMounted(this.session) }
  aboutToDisappear(): void { this.onUnmounted(this.session) }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.session.controller !== undefined) {
        ForEach([this.session.controller], (controller: PlayerViewController) => {
          PlayerView({ controller: controller }).width('100%').height(this.canvasHeight)
        }, (controller: PlayerViewController) => `${this.session.identity}:${this.session.renderKey}`)
      }
      if (this.session.status === PlayerStatus.idle ||
        (this.coverUntilJoined && this.session.status !== PlayerStatus.inRoom &&
        this.session.status !== PlayerStatus.coGuest && this.session.status !== PlayerStatus.end)) {
        Image(this.session.info.coverURL).width('100%').height(this.canvasHeight).objectFit(ImageFit.Cover)
          .hitTestBehavior(HitTestMode.None)
      }
      if (this.showPreview && this.session.status !== PlayerStatus.end) {
        Stack({ alignContent: Alignment.TopStart }) {
          Column().width('100%').height(Math.max(120, this.safeTop + 73))
            .position({ x: 0, y: 0 })
            .linearGradient({ direction: GradientDirection.Bottom, colors: [['#73000000', 0], ['#61000000', 0.32],
              ['#3B000000', 0.72], ['#00000000', 1]] }).hitTestBehavior(HitTestMode.None)
          Column().width('100%').height(Math.min(242, this.viewportHeight))
            .position({ x: 0, y: Math.max(0, this.viewportHeight - 242) })
            .linearGradient({ direction: GradientDirection.Bottom, colors: [['#00000000', 0], ['#24000000', 0.16],
              ['#38000000', 0.44], ['#4F000000', 0.77], ['#70000000', 1]] }).hitTestBehavior(HitTestMode.None)
          Column() {
            Button($r('app.string.app_join')).height(46).width(226).constraintSize({ maxWidth: '100%' })
              .fontSize(17).fontWeight(600).fontColor(Color.White).backgroundColor('#24FFFFFF')
              .borderRadius(23).border({ width: 1, color: '#4DFFFFFF' }).alignSelf(ItemAlign.Center)
              .enabled(!this.session.joining).margin({ bottom: 27 }).onClick(() => this.onEnter(this.session))
            Text($r('app.string.app_live_now')).fontSize(12).fontColor(Color.White).height(24)
              .padding({ left: 8, right: 8 }).backgroundColor('#E83B67').borderRadius(6).margin({ bottom: 11 })
            Text(this.session.info.liveOwner.userName || $r('app.string.app_unknown_host'))
              .fontSize(20).fontWeight(600).fontColor(Color.White).height(30).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ bottom: 7 })
            Text(this.session.info.liveName || $r('app.string.app_untitled')).fontSize(16).fontWeight(600)
              .fontColor(Color.White).height(24).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ bottom: 10 })
            Text(getContext(this).resourceManager.getStringSync($r('app.string.app_views').id,
              `${this.session.info.totalViewerCount}`)).fontSize(13).fontColor(Color.White).height(22)
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 20, right: 20, bottom: 19 })
            .position({ x: 0, y: this.viewportHeight - 220 })
        }.width('100%').height(this.viewportHeight)
          .onClick(() => this.onEnter(this.session))
      }
    }.width('100%').height(this.viewportHeight).clip(true).backgroundColor('#29364A')
  }
}
