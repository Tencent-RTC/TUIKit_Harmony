import { window } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';

/**
 * 窗口沉浸式 / 标准页系统栏样式统一管理。
 *
 * 约定：仅在各页 `onPageShow` 中切换窗口模式；不在 `aboutToDisappear` 里恢复，
 * 避免打开 Flutter 叠层或路由返回时出现「系统栏 + SafeArea + 手动 padding」三重顶距。
 */
export class WindowImmersiveHelper {
  /** 全屏布局 + 透明状态栏（MainPage / LoginPage / Flutter 容器） */
  static async enableImmersiveStatusBar(context: Context): Promise<void> {
    try {
      const win = await window.getLastWindow(context);
      await win.setWindowLayoutFullScreen(true);
      await win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#FF131212',
        navigationBarColor: '#00000000',
        navigationBarContentColor: '#FF131212',
      });
    } catch (_) {
    }
  }

  /**
   * 标准非沉浸式页：由系统负责顶栏避让，页面不要再叠加 statusBarInset 类 padding。
   * @param statusBarColor 含 alpha 的 #AARRGGBB
   * @param navigationBarColor 含 alpha 的 #AARRGGBB
   */
  static async applyStandardPageSystemBars(
    context: Context,
    statusBarColor: string,
    navigationBarColor: string,
  ): Promise<void> {
    try {
      const win = await window.getLastWindow(context);
      await win.setWindowLayoutFullScreen(false);
      await win.setWindowSystemBarProperties({
        statusBarColor: statusBarColor,
        statusBarContentColor: '#FF000000',
        navigationBarColor: navigationBarColor,
        navigationBarContentColor: '#FF000000',
      });
    } catch (_) {
    }
  }

  /** 设置页系统栏（#F5F5F7） */
  static async applySettingsPageSystemBars(context: Context): Promise<void> {
    await WindowImmersiveHelper.applyStandardPageSystemBars(context, '#FFF5F5F7', '#FFF5F5F7');
  }

  /** 关于页 / 版本信息页系统栏 */
  static async applyAboutPageSystemBars(context: Context): Promise<void> {
    await WindowImmersiveHelper.applyStandardPageSystemBars(context, '#FFFFFFFF', '#FFF9F9F9');
  }

  /** 非全屏 + 不透明白底系统栏（登录页离开等场景仍可使用） */
  static async restoreDefaultSystemBars(context: Context): Promise<void> {
    await WindowImmersiveHelper.applyStandardPageSystemBars(context, '#FFFFFFFF', '#FFFFFFFF');
  }

  /** 沉浸式全屏下，顶部状态栏占位高度（vp），用于 MainPage 等手动 padding */
  static async getStatusBarInsetVp(context: Context): Promise<number> {
    try {
      const win = await window.getLastWindow(context);
      const topArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      return px2vp(topArea.topRect.height);
    } catch (_) {
      return 0;
    }
  }

  /** 沉浸式全屏下，底部导航条占位高度（vp） */
  static async getNavigationBarInsetVp(context: Context): Promise<number> {
    try {
      const win = await window.getLastWindow(context);
      const bottomArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      return px2vp(bottomArea.bottomRect.height);
    } catch (_) {
      return 0;
    }
  }
}

export default WindowImmersiveHelper;
