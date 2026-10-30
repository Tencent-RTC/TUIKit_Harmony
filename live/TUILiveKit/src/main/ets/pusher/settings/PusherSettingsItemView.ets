import { LiveKitResources } from '../../common/LiveKitResources'
import { LiveText } from '../../common/theme/LiveText'
import { LiveTheme, rgba, white } from '../../common/theme/LiveTheme'

export enum Style {
  prepare,
  panel,
  soundOption,
}

export class PusherSettingsSelectionStyle {
  static readonly selectedTop: string = LiveTheme.Color.brand(0.42)
  static readonly selectedBottom: string = rgba(0, 0.32, 0.85, 0.26)
  static readonly idleBackground: string = white(0.045)
  static readonly idleBorder: string = white(0.14)
}

@Component
export struct PusherSettingsItemView {
  @Prop title: string = ''
  @Prop assetName: string = ''
  @Prop isSelected: boolean = false
  iconWidth: number = 22
  iconHeight: number = 22
  showsIconBackground: boolean = true
  itemStyle: Style = Style.panel
  onTap?: () => void

  private isPrepare(): boolean {
    return this.itemStyle === Style.prepare
  }

  private isSoundOption(): boolean {
    return this.itemStyle === Style.soundOption
  }

  private iconBackground(): ResourceColor {
    if (this.isPrepare()) {
      return rgba(0.08, 0.08, 0.09, 0.5)
    }
    if (this.isSoundOption()) {
      return this.isSelected ? 'rgba(0,0,0,0)' : PusherSettingsSelectionStyle.idleBackground
    }
    return this.showsIconBackground ? white(0.08) : 'rgba(0,0,0,0)'
  }

  build() {
    Column() {
      Stack() {
        Image(LiveKitResources.image(this.assetName))
          .width(this.isSoundOption() ? 25 : this.isPrepare() ? 24 : this.iconWidth)
          .height(this.isSoundOption() ? 25 : this.isPrepare() ? 24 : this.iconHeight)
          .objectFit(ImageFit.Contain)
      }
      .width(this.isPrepare() || this.isSoundOption() ? 48 : 44)
      .height(this.isPrepare() || this.isSoundOption() ? 48 : 44)
      .margin({ top: this.isPrepare() || this.isSoundOption() ? 0 : 4 })
      .borderRadius(this.isSoundOption() ? 14 : this.isPrepare() ? 24 : 22)
      .borderWidth(this.isPrepare() || this.isSoundOption() ? 1 : 0)
      .borderColor(this.isSoundOption() ? (this.isSelected ? LiveTheme.Color.brandBlue : PusherSettingsSelectionStyle.idleBorder) :
        white(0.1))
      .backgroundColor(this.iconBackground())
      .linearGradient(this.isSoundOption() && this.isSelected ? {
        angle: 180, colors: [[PusherSettingsSelectionStyle.selectedTop, 0], [PusherSettingsSelectionStyle.selectedBottom, 1]]
      } : { colors: [] })
      Text(this.title)
        .attributeModifier(new LiveText(LiveTheme.TextRole.control,
          this.isPrepare() || (this.isSoundOption() && this.isSelected) ? LiveTheme.TextTone.primary : LiveTheme.TextTone.secondary,
          TextAlign.Center, this.isPrepare() || (this.isSoundOption() && this.isSelected)))
        .maxLines(this.itemStyle === Style.panel ? 2 : 1)
        .minFontSize(8.25)
        .maxFontSize(11)
        .width('100%')
        .height(this.isPrepare() ? 16 : this.isSoundOption() ? 14 : 28)
        .margin({ top: this.isSoundOption() ? 2 : this.isPrepare() ? 7 : 8 })
    }
    .width(this.isPrepare() ? 68 : '100%')
    .height(this.isPrepare() ? 71 : this.isSoundOption() ? 64 : undefined)
    .onClick(() => this.onTap?.())
  }
}
