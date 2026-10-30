import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveListImageLoader, LiveListPalette } from './LiveListSupport'

@Component
export struct LiveSelectListItemView {
  @Prop liveInfo: LiveInfo = new LiveInfo()

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(this.liveInfo.coverURL.length === 0 ? LiveListPalette.defaultCoverURL : this.liveInfo.coverURL)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['rgba(0, 0, 0, 0)', 0], ['rgba(0, 0, 0, 0)', 0.55], ['rgba(0, 0, 0, 0.4)', 1]],
        })
        .hitTestBehavior(HitTestMode.None)
      Row({ space: 5 }) {
        Column().width(8).height(8).borderRadius(4).backgroundColor('rgba(255, 56, 69, 1)')
        Text(`${this.liveInfo.totalViewerCount}`).fontSize(14).fontColor(Color.White)
      }
      .position({ x: 8, y: 8 })
      Column({ space: 6 }) {
        Text(this.liveInfo.liveName.length === 0 ? this.liveInfo.liveID : this.liveInfo.liveName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 4 }) {
          Image(LiveListImageLoader.source(this.liveInfo.liveOwner.avatarURL))
            .width(20)
            .height(20)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
          Text(this.liveInfo.liveOwner.userName.length === 0 ? this.liveInfo.liveOwner.userID :
            this.liveInfo.liveOwner.userName)
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.70)')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 8, right: 8 })
      .position({ left: 0, bottom: 8 })
    }
    .width('100%')
    .aspectRatio(1 / 1.35)
    .borderRadius(8)
    .backgroundColor(Color.Black)
    .clip(true)
  }
}
