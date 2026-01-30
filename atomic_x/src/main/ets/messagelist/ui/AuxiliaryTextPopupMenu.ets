import { ThemeState } from '../../basecomponent/Index';

/**
 * Menu Item Configuration
 */
export interface AuxiliaryTextMenuItemConfig {
  text: Resource;
  icon: Resource;
  onClick: () => void;
}

/**
 * Auxiliary Text Popup Menu Component
 * A reusable floating menu component for auxiliary text (ASR, translation, etc.)
 * Designed to be used with bindPopup() for showing menu options like hide, forward, copy
 */
@Component
export struct AuxiliaryTextPopupMenu {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private menuItems: AuxiliaryTextMenuItemConfig[] = [];

  build() {
    Row() {
      ForEach(this.menuItems, (item: AuxiliaryTextMenuItemConfig, index: number) => {
        this.MenuItem(item)
      }, (item: AuxiliaryTextMenuItemConfig, index: number) => `${index}`)
    }
    .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .borderRadius(8)
    .shadow({
      radius: 8,
      color: this.themeState.colors.shadowColor,
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * Menu Item Builder
   */
  @Builder
  MenuItem(config: AuxiliaryTextMenuItemConfig) {
    Column() {
      Image(config.icon)
        .width(20)
        .height(20)
        .fillColor(this.themeState.colors.textColorLink)

      Text(config.text)
        .fontSize(10)
        .fontColor(this.themeState.colors.textColorPrimary)
        .margin({ top: 4 })
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(6)
    .onClick(() => {
      config.onClick();
    })
  }
}


