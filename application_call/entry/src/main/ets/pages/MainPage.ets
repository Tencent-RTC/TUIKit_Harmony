import { i18n } from '@kit.LocalizationKit';
import { MainMenuCard } from '../components/MainMenuCard';
import { Constants } from '../common/Constants';
import { MineDestination } from './MinePage';
import { SettingsDestination } from './SettingsPage';
import { AvatarSelectorDestination } from './AvatarSelectorPage';
import { LanguageSelectDestination } from './LanguageSelectPage';
import { CallDestination } from './call/CallPage';
import { JoinGroupCallDestination } from './call/JoinGroupCallPage';
import { CallSettingsDestination } from './call/CallSettingsPage';
import { SettingDetailDestination } from './call/SettingDetailPage';
import { SettingDetailParam, CallTestRouter } from '../common/CallTestRouter';

@Entry
@Component
struct MainPage {
  @StorageProp(Constants.KEY_AVATAR_URL) avatarUrl: string = Constants.DEFAULT_AVATAR_URL;
  @State private logoResource: Resource = $r('app.media.logo_en');
  private navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.updateLogo();
  }

  onPageShow(): void {
    this.updateLogo();
  }

  build() {
    Navigation(this.navStack) {
      Column() {
        Row() {
          Image(this.logoResource)
            .height(32)
            .objectFit(ImageFit.Contain)

          Blank()

          Image(this.avatarUrl)
            .alt($r('app.media.default_avatar'))
            .width(32)
            .height(32)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
            .onClick(() => {
              this.navStack.pushPath({ name: 'Mine' });
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Column() {
          Row({ space: 12 }) {
            MainMenuCard({
              icon: $r('app.media.main_call'),
              title: $r('app.string.main_call_title'),
              desc: $r('app.string.main_call_desc')
            })
              .layoutWeight(1)
              .onClick(() => {
                this.navStack.pushPath({ name: CallTestRouter.CALL });
              })

            Column()
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 12 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EBEDF5')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .navDestination(this.routerMap)
    .hideTitleBar(true)
    .hideToolBar(true)
    .width('100%')
    .height('100%')
  }

  @Builder
  routerMap(name: string, param: Object) {
    if (name === 'Mine') {
      MineDestination({ navStack: this.navStack })
    } else if (name === 'Settings') {
      SettingsDestination({ navStack: this.navStack })
    } else if (name === 'AvatarSelector') {
      AvatarSelectorDestination({ navStack: this.navStack })
    } else if (name === 'LanguageSelect') {
      LanguageSelectDestination({ navStack: this.navStack })
    } else if (name === CallTestRouter.CALL) {
      CallDestination({ navStack: this.navStack })
    } else if (name === CallTestRouter.JOIN_GROUP) {
      JoinGroupCallDestination({ navStack: this.navStack })
    } else if (name === CallTestRouter.SETTINGS) {
      CallSettingsDestination({ navStack: this.navStack })
    } else if (name === CallTestRouter.SETTING_DETAIL) {
      SettingDetailDestination({ navStack: this.navStack, param: param as SettingDetailParam })
    }
  }

  private updateLogo(): void {
    try {
      const lang = i18n.System.getAppPreferredLanguage();
      this.logoResource = lang.startsWith('zh') ? $r('app.media.logo_zh') : $r('app.media.logo_en');
    } catch (err) {
      try {
        const systemLang = i18n.System.getSystemLanguage();
        this.logoResource = systemLang.startsWith('zh') ? $r('app.media.logo_zh') : $r('app.media.logo_en');
      } catch (e) {
        this.logoResource = $r('app.media.logo_en');
      }
    }
  }
}
