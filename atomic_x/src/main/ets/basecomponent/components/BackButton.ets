import { ThemeState } from '../theme/ThemeState';
import { LanguageState } from '../language/LanguageState';

@Component
export struct BackButton {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  onBack?: () => void;
  leadingInset: number = 16;
  buttonHeight: number = 48;

  build() {
    Row() {
      Row() {
        Image($rawfile('basecomponent/common_back_icon.svg'))
          .scale({
            x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
            y: 1
          })
          .width(16)
          .height(16)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
      .height(this.buttonHeight)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 4, right: 4 })
      .onClick(() => {
        this.onBack?.();
      })
    }
    .height(this.buttonHeight)
    .padding({ left: this.leadingInset })
    .alignItems(VerticalAlign.Center)
  }
}
