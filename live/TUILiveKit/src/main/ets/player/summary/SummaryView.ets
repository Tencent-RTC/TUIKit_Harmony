import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveKitResources } from '../../common/LiveKitResources'
import { black, white } from '../../common/theme/LiveTheme'

@Component
export struct SummaryView {
  @Prop liveInfo: LiveInfo
  @Prop reason: string = ''

  private backgroundURL(): string {
    return this.liveInfo.backgroundURL.length > 0 ? this.liveInfo.backgroundURL
      : this.liveInfo.coverURL.length > 0 ? this.liveInfo.coverURL : LiveKitResources.defaultBackgroundURL
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Image(this.backgroundURL())
        .alt(LiveKitResources.image('livekit_livelist_default_cover'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .backgroundColor(black(0.6))
        .blur(80)
      Text(this.reason.length > 0 ? this.reason : LiveKitResources.localizedString('tuilivekit.player.live_ended'))
        .fontSize(27)
        .fontWeight(600)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .width('100%')
        .height(34)
        .position({ x: 0, y: 114 })
      Stack() {
        Image(this.liveInfo.liveOwner.avatarURL)
          .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
          .width(80)
          .height(80)
          .borderRadius(40)
          .objectFit(ImageFit.Cover)
      }
      .width(86)
      .height(86)
      .borderRadius(43)
      .backgroundColor(Color.White)
      .margin({ top: 211 })
      Text(this.liveInfo.liveOwner.userName.length === 0 ? this.liveInfo.liveOwner.userID : this.liveInfo.liveOwner.userName)
        .fontSize(20)
        .fontWeight(600)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .height(28)
        .padding({ left: 24, right: 24 })
        .position({ x: 0, y: 314 })
      Text(LiveKitResources.localizedString('tuilivekit.player.summary.next_live_hint'))
        .fontSize(14)
        .fontColor(white(0.6))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .width('100%')
        .height(21)
        .position({ x: 0, y: 349 })
      Column({ space: 5 }) {
        Image(LiveKitResources.image('livekit_summary_swipe_arrow'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .fillColor(white(0.72))
        Text(LiveKitResources.localizedString('tuilivekit.player.summary.swipe_more'))
          .fontSize(12)
          .fontColor(white(0.66))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .height(18)
      }
      .width('100%')
      .position({ left: 0, bottom: 58 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
