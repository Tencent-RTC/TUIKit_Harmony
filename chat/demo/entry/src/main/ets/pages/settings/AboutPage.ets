/**
 * 关于我们（对齐 Android `AboutActivity` + `about.xml`）。
 */
import router from '@ohos.router';
import { HMFlutterManager } from '../../manager/HMFlutterManager';
import { SystemManager } from '../../manager/SystemManager';
import { AppVersionUtil } from '../../manager/AppVersionUtil';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';
import { SettingsMenuRow } from './SettingsMenuRow';

const PAGE_BG = '#F9F9F9';
const PRIVACY_URL = 'https://static.histar.com/static/histar-wechat-mp/html/agreements/privacy.html';
const SERVICE_URL = 'https://static.histar.com/static/histar-wechat-mp/html/agreements/service.html';

@Entry
@Component
struct AboutPage {
  @State statusBarInsetVp: number = 0;
  @State navigationBarInsetVp: number = 0;
  @State localVersionText: string = '';
  @State hasNewVersion: boolean = false;
  private versionListenerRemover: (() => void) | null = null;

  aboutToAppear(): void {
    void this.applyImmersiveLayout();
    void this.loadLocalVersionText();
    this.versionListenerRemover = SystemManager.getInstance().addVersionListener(
      (_latest, hasNew: boolean) => {
        this.hasNewVersion = hasNew;
      }
    );
  }

  onPageShow(): void {
    void this.applyImmersiveLayout();
    void SystemManager.getInstance().refreshLatestVersion();
  }

  /** 沉浸式 + 读取系统栏 inset（SDK12 用 padding，勿用 safeAreaPadding 布尔写法） */
  private async applyImmersiveLayout(): Promise<void> {
    const ctx = getContext(this);
    await WindowImmersiveHelper.enableImmersiveStatusBar(ctx);
    this.statusBarInsetVp = await WindowImmersiveHelper.getStatusBarInsetVp(ctx);
    this.navigationBarInsetVp = await WindowImmersiveHelper.getNavigationBarInsetVp(ctx);
  }

  aboutToDisappear(): void {
    if (this.versionListenerRemover !== null) {
      this.versionListenerRemover();
      this.versionListenerRemover = null;
    }
  }

  private async loadLocalVersionText(): Promise<void> {
    const local = await AppVersionUtil.getLocalVersion();
    this.localVersionText = AppVersionUtil.formatDisplayName(local.versionName);
  }

  private openVersionInfoPage(): void {
    router.pushUrl({ url: 'pages/settings/VersionInfoPage' }).catch((err: Error) => {
      console.error(`open VersionInfoPage failed: ${JSON.stringify(err)}`);
    });
  }

  /** 打开 Flutter 前切沉浸式，避免非沉浸式 + Flutter SafeArea 造成顶部双留白 */
  private async openFlutterRoute(route: string, args?: Record<string, Object>): Promise<void> {
    // await WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
    HMFlutterManager.openFlutter(route, args);
  }

  private openWebPage(url: string, title: string): void {
    const args: Record<string, Object> = {
      'url': url,
      'title': title,
    };
    void this.openFlutterRoute(HMFlutterManager.FLUTTER_ROUTER_WEB_URL, args);
  }

  private openReportPage(): void {
    void this.openFlutterRoute(HMFlutterManager.FLUTTER_ROUTER_REPORT);
  }

  build() {
    Column() {
      this.TitleBarBuilder()
      this.MenuCardBuilder()
      Blank()
        .layoutWeight(1)
      Text('© 2025 HiStar. All rights reserved.')
        .fontSize(12)
        .fontColor('#131212')
        .margin({ top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .padding({top: this.statusBarInsetVp})
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

      Text('关于我们')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#000000')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 24 })
    }
    .width('100%')
    .height(65)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    // .backgroundColor('#FFFFFF')
  }

  @Builder
  MenuCardBuilder() {
    Column() {
      SettingsMenuRow({
        title: '版本信息',
        rightText: this.localVersionText,
        showNewBadge: this.hasNewVersion,
        isFirst: true,
        onTap: () => {
          this.openVersionInfoPage();
        },
      })
      this.MenuDividerBuilder()
      SettingsMenuRow({
        title: '隐私协议',
        onTap: () => {
          this.openWebPage(PRIVACY_URL, '隐私协议');
        },
      })
      this.MenuDividerBuilder()
      SettingsMenuRow({
        title: '用户协议',
        onTap: () => {
          this.openWebPage(SERVICE_URL, '用户服务协议');
        },
      })
      this.MenuDividerBuilder()
      SettingsMenuRow({
        title: '投诉建议',
        isLast: true,
        onTap: () => {
          this.openReportPage();
        },
      })
    }
    .width('100%')
    .padding(20)
  }

  @Builder
  MenuDividerBuilder() {
    Divider()
      .strokeWidth(0.5)
      .color('#F0F0F2')
      .margin({ left: 20 })
  }
}
