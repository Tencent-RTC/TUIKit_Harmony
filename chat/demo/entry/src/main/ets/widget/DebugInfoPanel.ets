import { LoginUserInfo } from '../bean/LoginUserInfo';
import { AppSettings } from '../config/AppSettings';

const TAG = 'DebugInfoPanel';

/**
 * 调试信息面板（仅本地排查用）。
 *
 * 集中展示：
 * - {@link LoginUserInfo}（登录态：token / refreshToken / userId / nickname 等）
 * - {@link AppSettings}（环境配置：envType / baseUrl / h5Url / imSdkAppId / pushAppkey / agreePrivacy）
 *
 * 数据来源全部走单例 + MMKV，「刷新显示」会重新读取一次单例并可同步打印到控制台。
 *
 * 用法（在父组件 build 内）：
 * ```typescript
 * DebugInfoPanel()
 * // 或定制：
 * DebugInfoPanel({ title: '[Debug] 状态快照', logToConsoleOnInit: false })
 * ```
 *
 * 注意：组件内部 Column 已使用 `layoutWeight(1)`，需要放在 *已有* 高度约束（Column / Flex 等）
 * 的父容器中使用，避免高度坍缩。
 */
@Component
export struct DebugInfoPanel {
  /** 面板顶部标题，可被父组件覆盖 */
  title: string = '[调试] LoginUserInfo & AppSettings';
  /** 是否展示「刷新显示」按钮，默认开 */
  showRefreshButton: boolean = true;
  /** 进入页面时是否同步打印一次到控制台（HiLog），默认开 */
  logToConsoleOnInit: boolean = true;

  /** 当前展示的 dump 文本（合并后的多行字符串） */
  @State debugText: string = '';

  aboutToAppear(): void {
    this.refresh(this.logToConsoleOnInit);
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#131212')
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      if (this.showRefreshButton) {
        Button('刷新显示（重新读单例）')
          .fontSize(13)
          .height(36)
          .margin({ left: 12, right: 12, bottom: 8 })
          .onClick(() => {
            this.refresh(true);
          })
      }

      Scroll() {
        Text(this.debugText.length > 0
          ? this.debugText
          : '（暂无数据：请先完成 Flutter 登录或检查 MMKV）')
          .fontSize(11)
          .fontColor('#333333')
          .fontFamily('monospace')
          .lineHeight(16)
          .width('100%')
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .backgroundColor('#F5F6F8')
      .borderRadius(8)
      .margin({ left: 12, right: 12, bottom: 12 })
    }
    .layoutWeight(1)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /** 重新读取两个单例的 dump 并刷新界面；可选同步打印控制台。 */
  private refresh(logToConsole: boolean): void {
    const loginDump = LoginUserInfo.getInstance().debugDumpForTest();
    const settingsDump = AppSettings.getInstance().debugDump();
    const merged = `${loginDump}\n\n${settingsDump}`;
    this.debugText = merged;
    if (logToConsole) {
      console.info(`[${TAG}]\n${merged}`);
    }
  }
}

export default DebugInfoPanel;
