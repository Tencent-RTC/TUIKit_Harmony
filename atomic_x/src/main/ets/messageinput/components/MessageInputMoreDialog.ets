import { ThemeState } from '../../basecomponent/Index';
export interface MenuItem {
  id: string;
  text: string | Resource;
  icon: Resource;
  action: () => void;
}
@CustomDialog
export struct MessageInputMoreDialog {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller?: CustomDialogController;
  menuItems: MenuItem[] = []; 
  onCancel?: () => void; 

  
  aboutToAppear() {
    
    if (this.menuItems.length === 0) {
      this.menuItems = [];
    }
  }

  
  @Builder
  MenuItemBuilder(item: MenuItem, index: number, isFirst: boolean = false, isLast: boolean = false) {
    Column() {
      Row() {
        
        Image(item.icon)
          .width(24)
          .height(24)
          .fillColor(this.themeState.colors.textColorSecondary)

        
        Text(item.text)
          .fontSize(17)
          .fontColor(this.themeState.colors.textColorLink)
          .fontWeight(FontWeight.Regular)
          .margin({ left: 12 })
      }
      .height(52)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        item.action();
        this.controller?.close();
      })
    }
  }

  build() {
    Column() {
      
      Column() {
        ForEach(this.menuItems, (item: MenuItem, index: number) => {
          this.MenuItemBuilder(
            item,
            index,
            index === 0,
            index === this.menuItems.length - 1
          )
        })
      }
      .backgroundColor(this.themeState.colors.strokeColorPrimary)
      .borderRadius(14)
      .width('100%')
      .margin({ bottom: 8 })
      .backdropBlur(10) 

      
      Button($r('app.string.cancel'))
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .fontColor(this.themeState.colors.textColorLink)
        .width('100%')
        .height(56)
        .borderRadius(14)
        .margin({ bottom: 12 })
        .onClick(() => {
          if (this.onCancel) {
            this.onCancel();
          }
          this.controller?.close();
        })
    }
    .padding({ left: 16, right: 16, bottom: 8 })
    .backgroundColor(Color.Transparent)
    .width('100%')
  }
} 