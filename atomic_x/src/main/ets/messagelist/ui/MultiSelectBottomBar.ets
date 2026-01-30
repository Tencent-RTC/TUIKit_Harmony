import { ThemeState } from '../../basecomponent/Index';

/**
 * MultiSelectBottomBar component for multi-select mode
 * Displays forward, delete buttons on the left, selected count in center, and cancel button on the right
 */
@Component
export struct MultiSelectBottomBar {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @Prop selectedCount: number = 0;
  onCancel?: () => void;
  onDelete?: () => void;
  onForward?: () => void;

  private readonly BAR_HEIGHT: number = 56;
  private readonly ICON_SIZE: number = 16;
  private readonly HORIZONTAL_PADDING: number = 16;
  private readonly BUTTON_SPACING: number = 24;

  build() {
    Row() {
      // Left side: Forward and Delete buttons
      Row() {
        // Forward button
        Column() {
          Image($rawfile('messagelist/icon_extion_forward.svg'))
            .width(this.ICON_SIZE)
            .height(this.ICON_SIZE)
            .fillColor(this.selectedCount > 0 ? 
              this.themeState.colors.textColorLink : 
              this.themeState.colors.textColorDisable)
        }
        .onClick(() => {
          if (this.selectedCount > 0 && this.onForward) {
            this.onForward();
          }
        })
        .enabled(this.selectedCount > 0)

        // Delete button
        Column() {
          Image($rawfile('messagelist/icon_extion_delete.svg'))
            .width(this.ICON_SIZE)
            .height(this.ICON_SIZE)
            .fillColor(this.selectedCount > 0 ? 
              this.themeState.colors.textColorLink : 
              this.themeState.colors.textColorDisable)
        }
        .margin({ left: this.BUTTON_SPACING })
        .onClick(() => {
          if (this.selectedCount > 0 && this.onDelete) {
            this.onDelete();
          }
        })
        .enabled(this.selectedCount > 0)
      }
      .padding({ left: this.HORIZONTAL_PADDING })

      // Center: Selected count
      Text() {
        Span(`${this.selectedCount} `)
        Span($r('app.string.multiselect_selected'))
      }
      .fontSize(14)
      .fontColor(this.themeState.colors.textColorPrimary)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)

      // Right side: Cancel button
      Text($r('app.string.cancel'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorLink)
        .padding({ right: this.HORIZONTAL_PADDING })
        .onClick(() => {
          if (this.onCancel) {
            this.onCancel();
          }
        })
    }
    .width('100%')
    .height(this.BAR_HEIGHT)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .alignItems(VerticalAlign.Center)
  }
}
