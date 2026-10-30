import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { black, LiveTheme } from '../../common/theme/LiveTheme'

@Component
export struct LiveBottomToolbarView {
  @Prop isCoGuestStageActive: boolean = false
  @Prop hasCoGuestUnread: boolean = false
  onCoGuest?: () => void
  onMore?: () => void
  onLikeAnimationOrigin?: (origin: Position) => void

  @Builder
  livingActionControl(title: string, assetName: string, iconWidth: number, iconHeight: number, iconTop: number,
    action: () => void) {
    Stack({ alignContent: Alignment.Top }) {
      Image(LiveKitResources.image(assetName))
        .width(iconWidth)
        .height(iconHeight)
        .objectFit(ImageFit.Contain)
        .margin({ top: iconTop })
      Text(title)
        .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.secondary, TextAlign.Center))
        .textShadow({ radius: 2, color: black(0.35), offsetY: 1 })
        .height(16)
        .margin({ top: 30 })
    }
    .constraintSize({ minWidth: 34 })
    .height(46)
    .onClick(action)
  }

  build() {
    Row() {
      this.livingActionControl(LiveKitResources.localizedString('tuilivekit.pusher.living.coguest'),
        this.hasCoGuestUnread ? 'livekit_living_coguest_unread' : 'livekit_living_coguest', 46, 38, -6,
        () => this.onCoGuest?.())
      Blank()
      Stack() {
        this.livingActionControl(LiveKitResources.localizedString('tuilivekit.common.more'), 'livekit_living_more', 27, 27, 0,
          () => this.onMore?.())
      }
      .onAreaChange((_: Area, area: Area) => this.onLikeAnimationOrigin?.({
        x: (area.globalPosition.x as number) + (area.width as number) / 2,
        y: (area.globalPosition.y as number) - 10,
      }))
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 12, right: 12, top: 16 })
    .backgroundColor(this.isCoGuestStageActive ? Color.Transparent : LiveTheme.Color.controlBase)
  }
}
