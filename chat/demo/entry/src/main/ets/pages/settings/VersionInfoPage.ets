/**
 * 版本信息页（对齐 Android `VersionInfoActivity` 展示逻辑，不实现升级下载）。
 */
import router from '@ohos.router';
import BuildProfile from 'BuildProfile';
import { AppSettings } from '../../config/AppSettings';
import { SystemManager } from '../../manager/SystemManager';
import { AppVersionUtil } from '../../manager/AppVersionUtil';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';

const PAGE_BG = '#FFFFFF';

@Entry
@Component
struct VersionInfoPage {
  @State versionDetailText: string = '';
  @State updateHintText: string = '';
  @State updateHintColor: string = '#8a8a8a';

  aboutToAppear(): void {
    void this.loadVersionDisplay();
  }

  onPageShow(): void {
    void WindowImmersiveHelper.applyAboutPageSystemBars(getContext(this));
  }

  private static readBuildEnvType(): string {
    try {
      const profileMap = BuildProfile as Object as Record<string, Object>;
      const env = profileMap['ENV_TYPE'];
      if (typeof env === 'string' && env.length > 0) {
        return env;
      }
    } catch (_) {
    }
    return AppSettings.getInstance().getEnvType();
  }

  private async loadVersionDisplay(): Promise<void> {
    const local = await AppVersionUtil.getLocalVersion();
    const envType = VersionInfoPage.readBuildEnvType();
    this.versionDetailText = AppVersionUtil.formatDetailText(
      local.versionName,
      local.versionCode,
      envType,
    );

    const hasNew = SystemManager.getInstance().getHasNewVersion();
    const latest = SystemManager.getInstance().getLatestVersion();
    if (hasNew && latest !== null) {
      const serverName = AppVersionUtil.formatDisplayName(latest.versionName);
      this.updateHintText = `发现新版本 ${serverName}`;
      this.updateHintColor = '#43C78F';
    } else {
      this.updateHintText = '您使用的已是最新版本';
      this.updateHintColor = '#8a8a8a';
    }

    if (latest === null) {
      void SystemManager.getInstance().refreshLatestVersion().then(() => {
        this.applyUpdateHintFromManager();
      });
    }
  }

  private applyUpdateHintFromManager(): void {
    const hasNew = SystemManager.getInstance().getHasNewVersion();
    const latest = SystemManager.getInstance().getLatestVersion();
    if (hasNew && latest !== null) {
      const serverName = AppVersionUtil.formatDisplayName(latest.versionName);
      this.updateHintText = `发现新版本 ${serverName}`;
      this.updateHintColor = '#43C78F';
    } else {
      this.updateHintText = '您使用的已是最新版本';
      this.updateHintColor = '#8a8a8a';
    }
  }

  build() {
    Column() {
      this.TitleBarBuilder()

      Column() {
        Image($r('app.media.app_icon'))
          .width(100)
          .height(100)
          .margin({ top: 40 })
          .borderRadius(20)

        Text(this.versionDetailText)
          .fontSize(16)
          .fontColor('#131212')
          .margin({ top: 10 })

        Text(this.updateHintText)
          .fontSize(14)
          .fontColor(this.updateHintColor)
          .margin({ top: 10 })
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Text('© 2025 HiStar. All rights reserved.')
        .fontSize(12)
        .fontColor('#131212')
        .margin({ top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
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

      Text('版本信息')
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
    .backgroundColor('#FFFFFF')
  }
}
