import { LiveKitResources } from '../../../common/LiveKitResources'
import { LiveText } from '../../../common/theme/LiveText'
import { LiveTheme, LiveVideoOverlayStyle } from '../../../common/theme/LiveTheme'
import { User } from './PusherAudienceStore'

@Component
export struct LiveAudiencePresenceView {
  @Prop audience: User[] = []
  @Prop count: number = -1
  onTap?: () => void

  private avatarURLs(): string[] {
    return this.count > 0 ? this.audience.slice(0, 3).map((user: User) => user.avatarURL) : []
  }

  private static formattedCount(count: number): string {
    const safeCount = Math.max(0, count)
    if (safeCount < 10000) {
      return `${safeCount}`
    }
    return LiveKitResources.localizedFormat('tuilivekit.pusher.living.audience_count_compact',
      Math.min(10, Math.floor(safeCount / 10000)))
  }

  build() {
    Row({ space: this.avatarURLs().length === 0 ? 0 : 4 }) {
      Row({ space: 2 }) {
        ForEach(this.avatarURLs(), (avatarURL: string) => {
          Image(avatarURL)
            .alt(LiveKitResources.image('livekit_livelist_default_avatar'))
            .width(26)
            .height(26)
            .borderRadius(13)
            .objectFit(ImageFit.Cover)
            .margin({ left: 3, right: 3 })
        }, (avatarURL: string, index: number) => `${index}_${avatarURL}`)
      }
      .height(26)
      .visibility(this.avatarURLs().length === 0 ? Visibility.None : Visibility.Visible)

      Text(LiveAudiencePresenceView.formattedCount(this.count))
        .attributeModifier(new LiveText(LiveTheme.TextRole.caption, LiveTheme.TextTone.primary, TextAlign.Center))
        .maxLines(1)
        .height(26)
        .constraintSize({ minWidth: 26 })
        .padding({ left: 7, right: 7 })
        .borderRadius(13)
        .backgroundColor(LiveVideoOverlayStyle.capsuleBackground)
    }
    .height(26)
    .visibility(this.count < 0 ? Visibility.Hidden : Visibility.Visible)
    .accessibilityText(LiveKitResources.localizedString('tuilivekit.player.online_audience'))
    .accessibilityDescription(`${this.count}`)
    .onClick(() => this.onTap?.())
  }
}
