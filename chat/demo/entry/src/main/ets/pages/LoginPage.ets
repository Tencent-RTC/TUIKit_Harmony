/**
 * 登录页（视频背景 + 底部手机号登录区）。
 *
 * 术语速览：
 * - @Entry：声明「页面入口」，可被路由打开。
 * - @Component：声明自定义 UI 组件（这里是整个页面 struct）。
 * - @State：需要刷新界面时改变的变量要加 @State， ArkUI 才会重新执行 build()。
 * - build()：描述界面长什么样，返回一棵组件树。
 * - @Builder：把一块 UI 抽成方法，方便复用（类似小组件函数）。
 * - getContext(this)：拿到当前页面所属的 Ability 上下文，用来操作窗口等系统能力。
 * - getUIContext()：拿到 UI 上下文，部分组件（如自定义 Toast）需要它来弹窗。
 */

import router from '@ohos.router';
import { XToastUtils } from '../utils/XToastUtils';
import { HMFlutterManager, HMFlutterListenerRemover } from '../manager/HMFlutterManager';
import { LoginUserInfo } from '../bean/LoginUserInfo';
import { getUserInfo } from '../api/UserApi';
import { WindowImmersiveHelper } from '../utils/WindowImmersiveHelper';

@Entry
@Component
struct LoginPage {
  /** 用户协议勾选框是否勾选；变化时会触发界面刷新（因为带了 @State）。 */
  @State agreementChecked: boolean = false;

  /**
   * Video 组件必须绑定的控制器：用来暂停、恢复播放等。
   * 这里是页面级私有变量，不参与界面绑定，故不加 @State。
   */
  private videoController: VideoController = new VideoController();

  /**
   * Flutter 登录成功事件的「取消订阅函数」。
   * HMFlutterManager 返回的是 () => void，调用一次就会移除监听，避免页面销毁后仍收到回调。
   */
  private loginSuccessRemover: HMFlutterListenerRemover | null = null;

  /**
   * 页面即将显示时调用（生命周期）。
   * 这里开启沉浸式状态栏（视频可延伸到状态栏区域）。
   * void xxx(...)：表示「故意不等待」异步结果，避免生命周期方法签名变成 async。
   */
  aboutToAppear(): void {
    void WindowImmersiveHelper.enableImmersiveStatusBar(getContext(this));
  }

  /**
   * 页面即将消失时调用（例如路由跳转离开本页）。
   * 暂停视频、关掉 Toast、恢复普通状态栏、移除 Flutter 监听。
   */
  aboutToDisappear(): void {
    this.videoController.pause();
    XToastUtils.close();
    void WindowImmersiveHelper.restoreDefaultSystemBars(getContext(this));
    if (this.loginSuccessRemover !== null) {
      this.loginSuccessRemover();
      this.loginSuccessRemover = null;
    }
  }

  /**
   * 描述整页 UI。
   * Stack：层叠布局，先写的在下层、后写的在上层。
   * alignContent: Bottom：子组件默认对齐到底部（底部面板叠在视频上）。
   */
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 全屏循环背景视频（底层）
      Video({
        src: $rawfile('welcome.mp4'), // rawfile 目录下的 mp4
        controller: this.videoController
      })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover) // 铺满裁剪，类似 CSS object-fit: cover
        .autoPlay(true)
        .loop(true)
        .controls(false) // 不显示原生播放控件
        .muted(true) // 静音，便于自动播放策略通过
        // 触摸事件穿透给上层：否则视频会挡住底部按钮的点击
        .hitTestBehavior(HitTestMode.None)

      // 底部白色登录区（上层）
      this.buildBottomPanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    // 允许布局延伸到系统安全区（状态栏、刘海等），配合沉浸式使用
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /**
   * 底部登录面板：主按钮、三方入口（示例）、协议行。
   * constraintSize(minHeight:'34%')：高度至少占屏幕 34%，与设计稿底部留白一致。
   */
  @Builder
  buildBottomPanel() {
    Column() {
      Button($r('app.string.login_phone_button'), { type: ButtonType.Normal, stateEffect: true })
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hs_color_black'))
        .backgroundColor($r('app.color.hs_color_brand'))
        .borderRadius(24)
        .onClick(() => {
          this.onPhoneLoginClick();
        })

      Row({ space: 40 }) {
        this.buildSocialButton($r('app.media.login_icon_wechat'))
        this.buildSocialButton($r('app.media.login_icon_alipay'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 28 })

      this.buildAgreementRow()
    }
    .width('100%')
    .constraintSize({ minHeight: '34%' })
    .padding({
      left: 16,
      right: 16,
      top: 28,
      bottom: 24
    })
    .backgroundColor($r('app.color.hs_color_white'))
  }

  /** 单个圆形图标按钮（微信 / 支付宝）；点击弹出提示 Toast。 */
  @Builder
  buildSocialButton(icon: Resource) {
    Row() {
      Image(icon)
        .width(40)
        .height(40)
        .objectFit(ImageFit.Contain)
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .borderColor($r('app.color.hs_color_border_gray'))
    .backgroundColor($r('app.color.hs_color_white'))
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      XToastUtils.toast($r('app.string.login_third_party_coming_soon'), this.getUIContext());
    })
  }

  /**
   * 协议勾选 + 富文本说明。
   * Text() { Span... }：一段文字里多种颜色/样式用 Span 拼接。
   * layoutWeight(1)：在 Row 里占满剩余横向空间。
   */
  @Builder
  buildAgreementRow() {
    Row() {
      Image(this.agreementChecked ? $r('app.media.login_checkbox_checked') :
        $r('app.media.login_checkbox_unchecked'))
        .width(16)
        .height(16)
        .margin({ top: 2 })
        .onClick(() => {
          this.agreementChecked = !this.agreementChecked;
        })

      Text() {
        Span($r('app.string.login_agreement_prefix'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_text_secondary'))
        Span($r('app.string.login_user_agreement'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_brand_link'))
          .onClick(() => {
            this.openAgreementWeb(
              'https://static.histar.com/static/histar-wechat-mp/html/agreements/service.html',
              '用户服务协议'
            );
          })
        Span($r('app.string.login_agreement_and'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_text_secondary'))
        Span($r('app.string.login_privacy_policy'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_brand_link'))
          .onClick(() => {
            this.openAgreementWeb(
              'https://static.histar.com/static/histar-wechat-mp/html/agreements/privacy.html',
              '隐私协议'
            );
          })
        Span($r('app.string.login_agreement_and'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_text_secondary'))
        Span($r('app.string.login_operator_terms'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_brand_link'))
          .onClick(() => {
            this.openAgreementWeb(
              'https://static.histar.com/static/histar-wechat-mp/html/agreements/operator-terms.html',
              '运营商认证服务条款'
            );
          })
      }
      .lineHeight(16)
      .layoutWeight(1)
      .margin({ left: 8 })
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
    .margin({ top: 20 })
  }

  /** 打开协议 H5 页（对齐 Android LoginActivity.setupAgreementText → FlutterManager.openFlutter("/web/url")）。 */
  private openAgreementWeb(url: string, title: string): void {
    const args: Record<string, Object> = {
      'url': url,
      'title': title,
    };
    HMFlutterManager.openFlutter('/web/url', args);
  }

  /**
   * 点击「手机号登录/注册」：
   * 1）校验协议；
   * 2）向 Flutter 推送环境与网络配置（与 SettingsPage 测试逻辑一致）；
   * 3）监听 Flutter 登录成功事件；
   * 4）打开 Flutter 短信登录页。
   */
  private onPhoneLoginClick(): void {
    if (!this.agreementChecked) {
      XToastUtils.toast($r('app.string.login_agreement_required'), this.getUIContext());
      return;
    }

    HMFlutterManager.appPushEnvironment();
    HMFlutterManager.appPushNetworkConfig();

    // 防止重复注册监听：先拆掉旧的再注册新的
    if (this.loginSuccessRemover !== null) {
      this.loginSuccessRemover();
      this.loginSuccessRemover = null;
    }
    this.loginSuccessRemover = HMFlutterManager.addFlutterEventListener(
      HMFlutterManager.FLUTTER_EVENT_LOGINSUCCESS,
      (_key: string, args: Record<string, Object>) => {
        // void：表示「发起异步流程但不在这里 await」，避免回调必须是 async
        void this.handleFlutterLoginSuccess(args);
      }
    );

    HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_SMSLOGIN);
  }

  /**
   * Flutter 侧登录成功后的处理（异步）。
   * - 写入 LoginUserInfo（token 等，落盘到 MMKV，下次冷启动自动恢复）；
   * - 再推一次 app_pushLoginInfo 给 Flutter；
   * - 移除监听；
   * - 先恢复普通状态栏（避免下一页继承沉浸式窗口），再 replaceUrl 进 MainPage。
   *
   * router.replaceUrl：用新页面替换当前路由栈（通常不再返回登录页）。
   */
  private handleFlutterLoginSuccess(args: Record<string, Object>): void {
    console.info(`LoginPage flutter_pushLoginSuccess args=${JSON.stringify(args)}`);
    LoginUserInfo.getInstance().updateFromLoginSuccess(args);
    getUserInfo()
      .then((userBean) => {
        console.info('LoginPage getUserInfo: ' + JSON.stringify(userBean));
        LoginUserInfo.getInstance().updateFromUserBean(userBean);
      })
      .catch((err: Object) => {
        console.error(`LoginPage getUserInfo failed: ${JSON.stringify(err)}`);
      })
      .finally(() => {
        void this.finishLoginAfterProfile();
      });
  }

  /** 拉取资料（成功或失败）后：通知 Flutter、收尾监听并进入主页。 */
  private async finishLoginAfterProfile(): Promise<void> {
    HMFlutterManager.appPushLoginInfo();

    if (this.loginSuccessRemover !== null) {
      this.loginSuccessRemover();
      this.loginSuccessRemover = null;
    }

    await WindowImmersiveHelper.restoreDefaultSystemBars(getContext(this));
    try {
      await router.replaceUrl({ url: 'pages/main/MainPage' });
    } catch (err) {
      console.error(`LoginPage replaceUrl MainPage failed: ${JSON.stringify(err)}`);
    }
  }
}
