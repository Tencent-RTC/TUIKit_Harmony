/**
 * 主页面：侧栏 + 主内容（路由 pages/MainPage）。
 *
 * 侧栏布局对齐 Android `main_activty.xml`；
 * 已接入 Flutter 跳转：优惠券、订单、行程、收藏、常用旅客（见 {@link DrawerFlutterMenu}）。
 * 设置、消息中心已接入；头像等待后续补齐。
 */

import router from '@ohos.router';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';
import { DebugInfoPanel } from '../../widget/DebugInfoPanel';
import { HMFlutterManager } from '../../manager/HMFlutterManager';
import { LoginUserInfo } from '../../bean/LoginUserInfo';

/** 侧栏内已对接 Flutter 的菜单项（与 Android MainActivity.onMenuClick 分支一一对应） */
enum DrawerFlutterMenu {
  COUPON,
  ORDER,
  ITINERARY,
  FAVORITE,
  TRAVELER,
}

@Entry
@Component
struct MainPage {
  @State showSideBar: boolean = false;
  @State statusBarInsetVp: number = 0;
  @State navigationBarInsetVp: number = 0;
  @State nickname: string = '';
  @State avatarUrl: string = '';

  /** 页面被 Flutter 等盖住前侧栏是否展开，用于 onPageShow 恢复 */
  private sideBarOpenBeforeHide: boolean = false;

  aboutToAppear(): void {
    void this.applyImmersiveLayout();
    this.refreshUserInfo();
  }

  onPageShow(): void {
    void this.applyImmersiveLayout();
    this.refreshUserInfo();
    // 从 Flutter 等页面返回：若跳转前侧栏是展开的，则恢复
    if (this.sideBarOpenBeforeHide) {
      this.showSideBar = true;
      this.sideBarOpenBeforeHide = false;
    }
  }

  private refreshUserInfo(): void {
    const user = LoginUserInfo.getInstance();
    this.nickname = user.getNickname();
    this.avatarUrl = user.getAvatarUrl();
  }

  /** 沉浸式 + 读取系统栏 inset（SDK12 用 padding，勿用 safeAreaPadding 布尔写法） */
  private async applyImmersiveLayout(): Promise<void> {
    const ctx = getContext(this);
    await WindowImmersiveHelper.enableImmersiveStatusBar(ctx);
    this.statusBarInsetVp = await WindowImmersiveHelper.getStatusBarInsetVp(ctx);
    this.navigationBarInsetVp = await WindowImmersiveHelper.getNavigationBarInsetVp(ctx);
  }

  /** 收起侧栏（点击蒙层等场景） */
  private closeSideBar(): void {
    if (!this.showSideBar) {
      return;
    }
    animateTo({ duration: 250 }, () => {
      this.showSideBar = false;
    });
  }

  private toggleSideBar(): void {
    animateTo({ duration: 250 }, () => {
      this.showSideBar = !this.showSideBar;
    });
  }

  /**
   * 打开侧栏内 Flutter 页面。
   * 路由常量与跳转方式对齐 Android `FlutterManager.openFlutter` + `MainActivity.onMenuClick`。
   */
  private openSettingsPage(): void {
    // this.closeSideBar();
    router.pushUrl({ url: 'pages/settings/AppSettingsPage' }).catch((err: Error) => {
      console.error(`open AppSettingsPage failed: ${JSON.stringify(err)}`);
    });
  }

  /**
   * 侧栏「消息」入口 → 消息中心页。
   * 对齐 Android 从主页进入 `MessageCenterActivity`。
   */
  private openMessageCenterPage(): void {
    router.pushUrl({ url: 'pages/message/MessageCenterPage' }).catch((err: Error) => {
      console.error(`open MessageCenterPage failed: ${JSON.stringify(err)}`);
    });
  }

  private async openDrawerFlutterMenu(menu: DrawerFlutterMenu): Promise<void> {
    // 跳转前记录侧栏展开状态，不在此处收起，返回后由 onPageShow 恢复
    this.sideBarOpenBeforeHide = this.showSideBar;
    await WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
    switch (menu) {
      case DrawerFlutterMenu.COUPON:
        HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_COUPON);
        break;
      case DrawerFlutterMenu.ORDER:
        HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_ORDER);
        break;
      case DrawerFlutterMenu.ITINERARY:
        HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_ITINERARY);
        break;
      case DrawerFlutterMenu.FAVORITE:
        HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_FAVORITE);
        break;
      case DrawerFlutterMenu.TRAVELER:
        HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_TRAVELER);
        break;
    }
  }

  build() {
    Column() {
      SideBarContainer(SideBarContainerType.Overlay) {
        this.DrawerPanelBuilder()
        this.MainContentBuilder()
      }
      .showSideBar(this.showSideBar)
      .sideBarWidth('80%')
      .showControlButton(false)
      .onChange((value: boolean) => {
        this.showSideBar = value;
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({
      top: 0,//this.statusBarInsetVp,
      bottom: this.navigationBarInsetVp,
    })
  }

  /** 侧栏整体：背景 #F3F3F6 + 顶栏用户信息 + 四宫格菜单（毛玻璃卡片） */
  @Builder
  DrawerPanelBuilder() {
    Column() {
      this.DrawerHeaderBuilder()
      this.DrawerMenuGridBuilder()
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.statusBarInsetVp,
    })
    .backgroundColor('#E8E8EC')
  }

  /** 顶栏：头像、昵称/设置文案、优惠券、消息 */
  @Builder
  DrawerHeaderBuilder() {
    Row() {
      Image(this.avatarUrl.length > 0 ? this.avatarUrl : $r('app.media.app_icon'))
        .width(44)
        .height(44)
        .borderRadius(22)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#E8E8EC')

      Column() {
        Text(this.nickname.length > 0 ? this.nickname : ' ')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text('设置')
            .fontSize(12)
            .fontColor('#8D8E99')
          Text('›')
            .fontSize(14)
            .fontColor('#8D8E99')
            .margin({ left: 2, top: 1 })
        }
        .margin({ top: 4 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.openSettingsPage();
        })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      .justifyContent(FlexAlign.Center)

      Column() {
        Image($r('app.media.left_icon_coupon'))
          .width(24)
          .height(24)
        Text('优惠券')
          .fontSize(12)
          .fontColor('#555175')
          .margin({ top: -2 })
      }
      .margin({ right: 14 })
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        void this.openDrawerFlutterMenu(DrawerFlutterMenu.COUPON);
      })

      Column() {
        Image($r('app.media.remind'))
          .width(24)
          .height(24)
        Text('消息')
          .fontSize(12)
          .fontColor('#555175')
      }
      .width(36)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.openMessageCenterPage();
      })
    }
    .width('100%')
    .padding(10)
    .margin({ bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 四宫格：订单 | 行程 | 收藏 | 常用旅客
   * 背景对齐 Android `@drawable/bg_glass`（半透明白 + 白描边 + 圆角）
   */
  @Builder
  DrawerMenuGridBuilder() {
    Row() {
      this.DrawerMenuGridItemBuilder('订单', $r('app.media.icon_order'), DrawerFlutterMenu.ORDER)
      this.DrawerGradientDividerBuilder()
      this.DrawerMenuGridItemBuilder('行程', $r('app.media.icon_trip'), DrawerFlutterMenu.ITINERARY)
      this.DrawerGradientDividerBuilder()
      this.DrawerMenuGridItemBuilder('收藏', $r('app.media.icon_collect'), DrawerFlutterMenu.FAVORITE)
      this.DrawerGradientDividerBuilder()
      this.DrawerMenuGridItemBuilder('常用旅客', $r('app.media.left_icon_user'), DrawerFlutterMenu.TRAVELER)
    }
    // .width('100%')
    .margin({ left: 10, right: 10, top: 10 })
    .padding({ top: 6, bottom: 6 })
    .borderRadius(10)
    .backgroundColor('#99FFFFFF')
    .border({ width: 1, color: '#FFFFFF' })
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  DrawerMenuGridItemBuilder(label: string, icon: Resource, menu: DrawerFlutterMenu) {
    Column() {
      Image(icon)
        .width(26)
        .height(26)
      Text(label)
        .fontSize(12)
        .fontColor('#69667B')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .onClick(() => {
      void this.openDrawerFlutterMenu(menu);
    })
  }

  /** 竖向渐变分割线，对齐 Android `bg_gradient_border.xml` */
  @Builder
  DrawerGradientDividerBuilder() {
    Column()
      .width(1)
      .height(30)
      .linearGradient({
        angle: 180,
        colors: [['#FBFBFC', 0.0], ['#D0CEDF', 0.476], ['#FBFAFD', 1.0]]
      })
  }

  @Builder
  MainContentBuilder() {
    Stack() {
      Column() {
        Row() {
          Image($r('app.media.ic_menu'))
            .width(24)
            .height(24)
            .margin(16)
            .onClick(() => {
              this.toggleSideBar();
            })
          Text('首页')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .height(56)
        .backgroundColor('#E8E8EC')

        DebugInfoPanel()
      }
      .width('100%')
      .height('100%')

      if (this.showSideBar) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.15)')
          .animation({ duration: 250 })
          .onClick(() => {
            this.closeSideBar();
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      top: this.statusBarInsetVp
    })
    .backgroundColor('#E8E8EC')
    .alignContent(Alignment.TopStart)
  }
}
