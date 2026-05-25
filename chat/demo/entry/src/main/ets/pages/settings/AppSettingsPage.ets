/**
 * 设置页（对齐 Android `SettingsActivity` + `settings.xml`）。
 */
import router from '@ohos.router';
import BuildProfile from 'BuildProfile';
import { getUserInfo } from '../../api/UserApi';
import { LoginUserInfo } from '../../bean/LoginUserInfo';
import { AppSettings } from '../../config/AppSettings';
import { HMFlutterManager } from '../../manager/HMFlutterManager';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';
import { SettingsMenuRow } from './SettingsMenuRow';

const PAGE_BG = '#F5F5F7';

@Entry
@Component
struct AppSettingsPage {
  @State statusBarInsetVp: number = 0;
  @State navigationBarInsetVp: number = 0;
  @State nickname: string = '';
  @State avatarUrl: string = '';
  @State showDevelopMenu: boolean = false;
  /** 清理缓存右侧文案（UI 占位，与 Android 动态计算一致的位置） */
  @State cacheSizeText: string = '—';

  aboutToAppear(): void {
    void this.applyImmersiveLayout();
    this.refreshUserInfo();
    this.showDevelopMenu = !AppSettingsPage.isReleaseBuild();
  }

  onPageShow(): void {
    void this.applyImmersiveLayout();
    this.refreshUserInfo();
    void this.loadUserProfileFromServer();
  }

  private refreshUserInfo(): void {
    const user = LoginUserInfo.getInstance();
    this.nickname = user.getNickname();
    this.avatarUrl = user.getAvatarUrl();
  }

  /** 对齐 Android `onResume` → `viewModel.loadUserInfo()` */
  private async loadUserProfileFromServer(): Promise<void> {
    if (!LoginUserInfo.getInstance().isLogin()) {
      return;
    }
    try {
      const userBean = await getUserInfo();
      LoginUserInfo.getInstance().updateFromUserBean(userBean);
      this.refreshUserInfo();
    } catch (err) {
      console.error(`AppSettingsPage loadUserProfile failed: ${JSON.stringify(err)}`);
    }
  }
  /** 沉浸式 + 读取系统栏 inset（SDK12 用 padding，勿用 safeAreaPadding 布尔写法） */
  private async applyImmersiveLayout(): Promise<void> {
    const ctx = getContext(this);
    await WindowImmersiveHelper.enableImmersiveStatusBar(ctx);
    this.statusBarInsetVp = await WindowImmersiveHelper.getStatusBarInsetVp(ctx);
    this.navigationBarInsetVp = await WindowImmersiveHelper.getNavigationBarInsetVp(ctx);
  }
  /**
   * 用户信息（头像/昵称），对齐 `menu_user_header` → `FLUTTER_ROUTER_ACCOUNT_MANAGEMENT`。
   */
  private async openAccountManagementPage(): Promise<void> {
    // await WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
    HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_ACCOUNT_MANAGEMENT);
  }

  /**
   * 修改手机号，对齐 `menu_edit_phone` → `appPushNetworkConfig` + `FLUTTER_ROUTER_EDITPHONE`。
   */
  private async openEditPhonePage(): Promise<void> {
    // await WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
    HMFlutterManager.appPushNetworkConfig();
    HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_EDITPHONE);
  }

  private static isReleaseBuild(): boolean {
    try {
      const profileMap = BuildProfile as Object as Record<string, Object>;
      const env = profileMap['ENV_TYPE'];
      return typeof env === 'string' && env === AppSettings.ENV_TYPE_RELEASE;
    } catch (_) {
      return false;
    }
  }

  build() {
    Column() {
      this.TitleBarBuilder()
      this.SettingsCardBuilder()
      this.ExitButtonBuilder()
      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({left: 15, right: 15, top: this.statusBarInsetVp})
    .backgroundColor(PAGE_BG)
  }

  @Builder
  TitleBarBuilder() {
    Row() {
      Image($r('app.media.back_icon'))
        .width(24)
        .height(24)
        .onClick(() => {
          router.back();
        })

      Text('设置')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#000000')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 24 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SettingsCardBuilder() {
    Column() {
      this.UserHeaderBuilder()
      this.MenuListBuilder()
    }
    .width('100%')
    .margin({ left: 15, right: 15, top: 0 })
    .borderRadius(20)
    .border({ width: 1, color: '#FFFFFF' })
    .clip(true)
    .linearGradient({
      angle: 10,
      colors: [['#FFFFFF', 0.0], ['#ECECF2', 1.0]],
    })
  }

  @Builder
  UserHeaderBuilder() {
    Row() {
      Image(this.avatarUrl.length > 0 ? this.avatarUrl : $r('app.media.app_icon'))
        .width(50)
        .height(50)
        .borderRadius(25)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#E8E8EC')

      Text(this.nickname.length > 0 ? this.nickname : ' ')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#000000')
        .margin({ left: 10 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text('›')
        .fontSize(20)
        .fontColor('#8a8a8a')
        .margin({ top: -1 })
    }
    .width('100%')
    .padding({ left: 20, right: 12, top: 20, bottom: 20 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      void this.openAccountManagementPage();
    })
  }

  @Builder
  MenuListBuilder() {
    Column() {
      SettingsMenuRow({
        title: '修改手机号',
        onTap: () => {
          void this.openEditPhonePage();
        },
      })
      this.MenuDividerBuilder()
      SettingsMenuRow({ title: '账号关联' })
      this.MenuDividerBuilder()
      SettingsMenuRow({
        title: '注销账号',
        onTap: () => {
          router.pushUrl({ url: 'pages/settings/AccountCancellationPage' }).catch((err: Error) => {
            console.error(`open AccountCancellationPage failed: ${JSON.stringify(err)}`);
          });
        },
      })
      if (this.showDevelopMenu) {
        this.MenuDividerBuilder()
        SettingsMenuRow({
          title: '环境配置',
          rightText: AppSettings.getInstance().getEnvDisplayName(),
        })
      }
      this.MenuDividerBuilder()
      SettingsMenuRow({
        title: '清理缓存',
        rightText: this.cacheSizeText,
        showArrow: false,
      })
      this.MenuDividerBuilder()
      SettingsMenuRow({
        title: '关于我们',
        isLast: true,
        onTap: () => {
          router.pushUrl({ url: 'pages/settings/AboutPage' }).catch((err: Error) => {
            console.error(`open AboutPage failed: ${JSON.stringify(err)}`);
          });
        },
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ bottomLeft: 20, bottomRight: 20 })
  }

  @Builder
  MenuDividerBuilder() {
    Divider()
      .strokeWidth(0.5)
      .color('#F0F0F2')
      .margin({ left: 20 })
  }

  @Builder
  ExitButtonBuilder() {
    Text('退出')
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.hs_color_black'))
      .textAlign(TextAlign.Center)
      .backgroundColor($r('app.color.hs_color_brand'))
      .borderRadius(24)
      .margin({ left: 20, right: 20, top: 20 })
  }
}
