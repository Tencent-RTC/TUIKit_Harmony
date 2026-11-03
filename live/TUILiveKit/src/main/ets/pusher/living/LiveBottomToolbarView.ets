import { MeasureUtils, UIContext } from '@kit.ArkUI'
import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { black, LiveTheme } from '../../common/theme/LiveTheme'

@Component
export struct LiveBottomToolbarView {
  @Prop isCoGuestStageActive: boolean = false
  @Prop hasCoGuestUnread: boolean = false
  onPK?: () => void
  onCoGuest?: () => void
  onFlipCamera?: () => void
  onShowBackgroundMusic?: () => void
  onMore?: () => void
  onLikeAnimationOrigin?: (origin: Position) => void
  @State private containerWidth: number = 0
  private titles: string[] = []
  private preferredWidths: number[] = []

  aboutToAppear(): void {
    this.titles = [
      'tuilivekit.pusher.living.pk', 'tuilivekit.pusher.living.coguest', 'tuilivekit.pusher.flip_camera',
      'tuilivekit.pusher.living.music', 'tuilivekit.common.more',
    ].map((key: string) => LiveKitResources.localizedString(key))
    const uiContext: UIContext = this.getUIContext()
    const measurement: MeasureUtils = uiContext.getMeasureUtils()
    this.preferredWidths = this.titles.map((title: string) => Math.max(34,
      Math.ceil(uiContext.px2vp(measurement.measureText({ textContent: title, fontSize: 11, fontWeight: 400 })))))
  }

  private actionWidth(index: number): number {
    const extra = this.preferredWidths.reduce((sum: number, width: number) => sum + width - 34, 0)
    const ratio = extra > 0 ? Math.max(0, Math.min(1, (this.containerWidth - 80 - 5 * 34) / extra)) : 1
    return 34 + ((this.preferredWidths[index] ?? 34) - 34) * ratio
  }

  @Builder
  livingActionControl(index: number, assetName: string, iconWidth: number, iconHeight: number, iconTop: number,
    action: () => void) {
    Stack({ alignContent: Alignment.Top }) {
      Image(LiveKitResources.image(assetName))
        .width(iconWidth)
        .height(iconHeight)
        .objectFit(ImageFit.Contain)
        .position({ x: (this.actionWidth(index) - iconWidth) / 2, y: iconTop })
      Text(this.titles[index] ?? '')
        .attributeModifier(new LiveText(LiveTheme.TextRole.control, LiveTheme.TextTone.secondary, TextAlign.Center))
        .textShadow({ radius: 2, color: black(0.35), offsetY: 1 })
        .maxLines(1)
        .minFontSize(8.25)
        .maxFontSize(11)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .height(16)
        .margin({ top: 30 })
    }
    .width(this.actionWidth(index))
    .height(46)
    .clip(false)
    .accessibilityText(this.titles[index] ?? '')
    .onClick(action)
  }

  build() {
    Row() {
      this.livingActionControl(0, 'livekit_living_pk', 46, 38, -6, () => this.onPK?.())
      Blank().width(14)
      this.livingActionControl(1,
        this.hasCoGuestUnread ? 'livekit_living_coguest_unread' : 'livekit_living_coguest', 46, 38, -6,
        () => this.onCoGuest?.())
      Blank().constraintSize({ minWidth: 12 })
      this.livingActionControl(2, 'livekit_living_setting_flip', 22, 22, 2.5, () => this.onFlipCamera?.())
      Blank().width(12)
      this.livingActionControl(3, 'livekit_living_setting_music', 22, 22, 2.5, () => this.onShowBackgroundMusic?.())
      Blank().width(12)
      Stack() {
        this.livingActionControl(4, 'livekit_living_more', 27, 27, 0, () => this.onMore?.())
      }
      .width(this.actionWidth(4))
      .height(46)
      .onAreaChange((_: Area, area: Area) => this.onLikeAnimationOrigin?.({
        x: (area.globalPosition.x as number) + (area.width as number) / 2,
        y: (area.globalPosition.y as number) - 10,
      }))
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 18, right: 12, top: 16 })
    .backgroundColor(this.isCoGuestStageActive ? Color.Transparent : LiveTheme.Color.controlBase)
    .onAreaChange((_: Area, area: Area) => {
      const width = area.width as number
      if (width !== this.containerWidth) {
        this.containerWidth = width
      }
    })
  }
}
