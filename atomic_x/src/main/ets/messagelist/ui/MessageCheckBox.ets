import { ThemeState } from '../../basecomponent/Index';

/**
 * MessageCheckBox component for multi-select mode
 * Displays a circular checkbox with selected/unselected/disabled states
 */
@Component
export struct MessageCheckBox {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @Prop isSelected: boolean = false;
  @Prop isEnabled: boolean = true;
  onTap?: () => void;

  private readonly SIZE: number = 20;
  private readonly BORDER_WIDTH: number = 1.5;
  private readonly CHECK_SIZE: number = 12;

  build() {
    Stack() {
      if (this.isSelected) {
        // Selected state: blue filled circle with white checkmark
        Circle()
          .width(this.SIZE)
          .height(this.SIZE)
          .fill(this.isEnabled ? 
            this.themeState.colors.buttonColorPrimaryDefault : 
            this.themeState.colors.textColorDisable)
        
        // Use text checkmark instead of image
        Text('✓')
          .fontSize(this.CHECK_SIZE)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      } else {
        // Unselected state: empty circle with border
        Circle()
          .width(this.SIZE)
          .height(this.SIZE)
          .fill(Color.Transparent)
          .stroke(this.isEnabled ? 
            this.themeState.colors.strokeColorPrimary : 
            this.themeState.colors.textColorDisable)
          .strokeWidth(this.BORDER_WIDTH)
      }
    }
    .width(this.SIZE)
    .height(this.SIZE)
    .onClick(() => {
      if (this.isEnabled && this.onTap) {
        this.onTap();
      }
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }
}
