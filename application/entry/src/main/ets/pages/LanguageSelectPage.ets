import { i18n } from '@kit.LocalizationKit';

@Component
export struct LanguageSelectDestination {
  navStack: NavPathStack = new NavPathStack();
  @State selectedLanguage: string = 'zh';

  aboutToAppear(): void {
    try {
      const appLanguage = i18n.System.getAppPreferredLanguage();
      this.selectedLanguage = appLanguage.startsWith('zh') ? 'zh' : 'en';
    } catch (err) {
      try {
        const systemLanguage = i18n.System.getSystemLanguage();
        this.selectedLanguage = systemLanguage.startsWith('zh') ? 'zh' : 'en';
      } catch (e) {
        this.selectedLanguage = 'zh';
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.mine_goback'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.navStack.pop();
            })

          Text($r('app.string.language_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262B32')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Row().width(24).height(24)
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Column() {
          Row() {
            Text($r('app.string.language_zh'))
              .fontSize(16)
              .fontColor('#262B32')
              .margin({ left: 16 })

            Blank()

            if (this.selectedLanguage === 'zh') {
              Image($r('app.media.icon_selected'))
                .width(20)
                .height(20)
                .margin({ right: 16 })
            }
          }
          .width('100%')
          .height(56)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.switchLanguage('zh');
          })

          Divider().color('#EEEEEE').height(0.5).margin({ left: 16 })

          Row() {
            Text($r('app.string.language_en'))
              .fontSize(16)
              .fontColor('#262B32')
              .margin({ left: 16 })

            Blank()

            if (this.selectedLanguage === 'en') {
              Image($r('app.media.icon_selected'))
                .width(20)
                .height(20)
                .margin({ right: 16 })
            }
          }
          .width('100%')
          .height(56)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.switchLanguage('en');
          })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(10)
        .margin({ top: 12, left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EBEDF5')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }

  private switchLanguage(lang: string): void {
    if (this.selectedLanguage === lang) {
      return;
    }
    this.selectedLanguage = lang;
    try {
      const locale = lang === 'zh' ? 'zh-CN' : 'en-US';
      i18n.System.setAppPreferredLanguage(locale);
    } catch (err) {
    }
  }
}
