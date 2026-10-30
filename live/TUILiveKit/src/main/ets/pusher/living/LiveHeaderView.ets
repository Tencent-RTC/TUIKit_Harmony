import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { LiveHeaderStyle, LiveTheme, LiveVideoOverlayStyle, rgba, white } from '../../common/theme/LiveTheme'
import { LiveAudiencePresenceView } from './audience/LiveAudiencePresenceView'
import { User } from './audience/PusherAudienceStore'
import { formatPusherDuration } from './status/PusherLiveStatusView'

class NetworkStatusPresentation {
  titleKey: string = 'tuilivekit.pusher.status.title'
  iconName?: string
  chevronName: string = 'livekit_living_status_chevron'
  tintColor: string = '#FFFFFF'
  minimumWidth: number = 68
  iconWidth: number = 13
  labelLeading: number = 8.8
  chevronTrailing: number = 9.7
  chevronWidth: number = 3.5

  constructor(quality: number) {
    if (quality === 3) {
      this.titleKey = 'tuilivekit.pusher.living.network_poor'
      this.iconName = 'livekit_living_network_poor'
      this.chevronName = 'livekit_living_network_poor_chevron'
      this.tintColor = rgba(1, 0.816, 0.541)
      this.minimumWidth = 82
      this.labelLeading = 25
      this.chevronTrailing = 10.1
      this.chevronWidth = 3.89
    } else if (quality === 4 || quality === 5 || quality === 6) {
      const isDisconnected = quality === 6
      this.titleKey = isDisconnected ? 'tuilivekit.pusher.living.network_disconnected' :
        'tuilivekit.pusher.living.network_very_poor'
      this.iconName = isDisconnected ? 'livekit_living_network_disconnected' : 'livekit_living_network_very_poor'
      this.chevronName = isDisconnected ? 'livekit_living_network_disconnected_chevron' :
        'livekit_living_network_very_poor_chevron'
      this.tintColor = isDisconnected ? rgba(1, 0.412, 0.471) : rgba(1, 0.573, 0.490)
      this.minimumWidth = 94
      this.iconWidth = 17
      this.labelLeading = 29
      this.chevronTrailing = 8.08
      this.chevronWidth = 3.92
    }
  }
}

@Component
export struct LiveHeaderView {
  @Prop hostName: string = ''
  @Prop avatarURL: string = ''
  @Prop audience: User[] = []
  @Prop audienceCount: number = -1
  @Prop likeCount: number = 0
  @Prop elapsedSeconds: number = 0
  @Prop networkQuality: number = 0
  onClose?: () => void
  onAudience?: () => void
  onStatus?: () => void
  @State private availableWidth: number = 0
  @State private audienceWidth: number = 0

  private presentation(): NetworkStatusPresentation {
    return new NetworkStatusPresentation(this.networkQuality)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.avatarURL)
          .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
          .width(32)
          .height(32)
          .borderRadius(LiveHeaderStyle.avatarRadius)
          .objectFit(ImageFit.Cover)
          .position({ x: 2, y: 2 })
        Column() {
          Text(this.hostName.length === 0 ? LiveKitResources.localizedString('tuilivekit.common.host') : this.hostName)
            .attributeModifier(new LiveText(LiveTheme.TextRole.caption))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .height(15)
          Text(LiveKitResources.localizedFormat('tuilivekit.pusher.living.like_count', this.likeCount))
            .fontSize(8)
            .fontColor(white(0.68))
            .maxLines(1)
            .width('100%')
            .height(11)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 40, right: 46 })
        .margin({ top: 5 })

        Image(LiveKitResources.image('livekit_living_fan'))
          .width(42)
          .height(28)
          .objectFit(ImageFit.Contain)
          .position({ right: 2, top: 4 })
      }
      .width(this.availableWidth > 0 ? Math.max(0, Math.min(165, this.availableWidth - this.audienceWidth - 4)) : 165)
      .height(36)
      .borderRadius(LiveHeaderStyle.capsuleRadius)
      .borderWidth(1)
      .borderColor(LiveHeaderStyle.border)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [[LiveVideoOverlayStyle.capsuleBackground, 0], [LiveHeaderStyle.middle, 0.52],
          [LiveHeaderStyle.purple, 0.82], [LiveHeaderStyle.rose, 1]],
      })
      .clip(true)

      Row({ space: 4 }) {
        LiveAudiencePresenceView({
          audience: this.audience,
          count: this.audienceCount,
          onTap: () => this.onAudience?.(),
        })
        Stack() {
          Image(LiveKitResources.image('livekit_living_close'))
            .width(15)
            .height(15)
            .objectFit(ImageFit.Contain)
        }
        .width(26)
        .height(26)
        .borderRadius(13)
        .borderWidth(1)
        .borderColor(white(0.08))
        .backgroundColor(LiveVideoOverlayStyle.capsuleBackground)
        .onClick(() => this.onClose?.())
      }
      .position({ right: 0, top: 5 })
      .onAreaChange((_: Area, area: Area) => this.audienceWidth = area.width as number)

      Row() {
        if (this.presentation().iconName !== undefined) {
          Image(LiveKitResources.image(this.presentation().iconName ?? ''))
            .width(this.presentation().iconWidth)
            .height(13)
            .objectFit(ImageFit.Contain)
            .position({ x: 7, y: 3 })
        }
        Text(LiveKitResources.localizedString(this.presentation().titleKey))
          .attributeModifier(new LiveText(LiveTheme.TextRole.metadata, LiveTheme.TextTone.primary, TextAlign.End))
          .fontColor(this.presentation().tintColor)
          .maxLines(1)
          .height(12)
          .margin({ left: this.presentation().labelLeading, right: 3 })
        Image(LiveKitResources.image(this.presentation().chevronName))
          .width(this.presentation().chevronWidth)
          .height(6.2)
          .objectFit(ImageFit.Contain)
          .margin({ right: this.presentation().chevronTrailing })
      }
      .height(19)
      .constraintSize({ minWidth: this.presentation().minimumWidth })
      .justifyContent(FlexAlign.End)
      .borderRadius({ topLeft: 9.5, bottomLeft: 9.5 })
      .backgroundColor(LiveVideoOverlayStyle.capsuleBackground)
      .position({ right: -12, top: 42 })
      .accessibilityText(LiveKitResources.localizedString(this.presentation().titleKey))
      .accessibilityDescription(formatPusherDuration(this.elapsedSeconds))
      .onClick(() => this.onStatus?.())
    }
    .width('100%')
    .height(61)
    .onAreaChange((_: Area, area: Area) => this.availableWidth = area.width as number)
  }
}
