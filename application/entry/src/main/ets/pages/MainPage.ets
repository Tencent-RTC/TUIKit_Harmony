import { i18n } from '@kit.LocalizationKit';
import { EnterRoomParams } from '@tencentcloud/tuiroomkit';
import { MainMenuCard } from '../components/MainMenuCard';
import { Constants } from '../common/Constants';
import { MineDestination } from './MinePage';
import { SettingsDestination } from './SettingsPage';
import { AvatarSelectorDestination } from './AvatarSelectorPage';
import { LanguageSelectDestination } from './LanguageSelectPage';
import { RoomHomeDestination, CreateRoomDestination, JoinRoomDestination, RoomMainDestination } from './room/RoomPages';

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
              icon: $r('app.media.main_room'),
              title: $r('app.string.main_room_title'),
              desc: $r('app.string.main_room_desc')
            })
              .layoutWeight(1)
              .onClick(() => {
                this.navStack.pushPath({ name: 'RoomHome' });
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
    } else if (name === 'RoomHome') {
      RoomHomeDestination({ navStack: this.navStack })
    } else if (name === 'CreateRoom') {
      CreateRoomDestination({ navStack: this.navStack })
    } else if (name === 'JoinRoom') {
      JoinRoomDestination({ navStack: this.navStack })
    } else if (name === 'RoomMain') {
      RoomMainDestination({ navStack: this.navStack, params: param as EnterRoomParams })
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
