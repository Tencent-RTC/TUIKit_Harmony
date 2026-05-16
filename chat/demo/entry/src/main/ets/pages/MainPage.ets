/**
 * 主页面示例：侧栏 + 主内容（路由名 MainPage 对应本文件）。
 *
 * struct 名 SideBarOverlayClickClose 仅为示例命名，与路由 pages/MainPage 无关；
 * 路由在 main_pages.json 里登记的是文件路径。
 *
 * SideBarContainer：鸿蒙侧栏容器；第一个子组件是侧栏内容，第二个是主内容区域。
 * Overlay 模式：侧栏浮在主内容之上。
 */

import { WindowImmersiveHelper } from '../utils/WindowImmersiveHelper';
import { DebugInfoPanel } from '../widget/DebugInfoPanel';

@Entry
@Component
struct SideBarOverlayClickClose {
  /** 控制侧栏展开/收起；变化会触发 build 重绘，带动画切换。 */
  @State showSideBar: boolean = false;

  /**
   * 状态栏占位高度（单位 vp）。
   * 窗口虽然是沉浸式（内容可画到屏幕边缘），但通过 padding-top 把 SideBarContainer 整体下移，
   * 避免标题栏钻进状态栏下面。
   */
  @State statusBarInsetVp: number = 0;

  /** 进入页面：异步读取窗口并设置沉浸式 + 顶部留白高度。 */
  aboutToAppear(): void {
    void this.applyWindowAndInset();
  }

  /** 离开页面：恢复默认系统栏，避免影响后续打开的页面（如设置页）。 */
  aboutToDisappear(): void {
    void WindowImmersiveHelper.restoreDefaultSystemBars(getContext(this));
  }

  /**
   * 分两步设置窗口：
   * 1）enableImmersiveStatusBar —— 与 LoginPage 同类沉浸式；
   * 2）getStatusBarInsetVp —— 读出系统状态栏区域高度，转成 vp 写入状态，
   *    供外层 Column 做 padding-top。
   */
  private async applyWindowAndInset(): Promise<void> {
    await WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
    const inset = await WindowImmersiveHelper.getStatusBarInsetVp(getContext(this));
    this.statusBarInsetVp = inset;
  }

  build() {
    Column() {
      SideBarContainer(SideBarContainerType.Overlay) {

        // ---------- 子组件 1：侧栏面板 ----------
        Column() {
          Text('侧边栏菜单').fontSize(20).fontWeight(FontWeight.Bold).margin(20)
          Text('功能 1').fontSize(16).margin(10)
          Text('功能 2').fontSize(16).margin(10)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 10, color: '#20000000', offsetX: 5 })

        // ---------- 子组件 2：主区域（顶栏 + 正文 + 可选遮罩） ----------
        Stack() {
          Column() {
            Row() {
              Image($r('app.media.app_icon'))
                .width(24)
                .height(24)
                .margin(16)
                .onClick(() => {
                  // animateTo：在 250ms 内平滑切换 showSideBar，触发侧栏动画
                  animateTo({ duration: 250 }, () => {
                    this.showSideBar = !this.showSideBar;
                  })
                })
              Text('首页').fontSize(18).fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .height(56)
            .backgroundColor('#F8F9FA')

            DebugInfoPanel()
          }
          .width('100%')
          .height('100%')

          // 侧栏打开时盖一层半透明蒙版，点击后收起侧栏（用户体验）
          if (this.showSideBar) {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0,0,0,0.15)')
              .animation({ duration: 250 })
              .onClick(() => {
                animateTo({ duration: 250 }, () => {
                  this.showSideBar = false;
                })
              })
          }
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.TopStart)
      }
      .showSideBar(this.showSideBar) // 双向绑定侧栏显隐
      .sideBarWidth(260) // 侧栏宽度 vp
      .showControlButton(false) // 不显示系统默认「拖动条」按钮
      .onChange((value: boolean) => {
        // 手势或其它操作改变侧栏状态时同步到状态变量
        this.showSideBar = value;
      })
      .layoutWeight(1) // 在 Column 内占满除 padding 以外的剩余高度
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.statusBarInsetVp })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
