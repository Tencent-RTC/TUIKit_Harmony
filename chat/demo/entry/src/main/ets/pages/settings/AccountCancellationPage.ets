/**
 * 注销账号页（对齐 Android `AccountCancellationActivity` + `account_cancellation.xml`）。
 */
import router from '@ohos.router';
import { cancelAccount } from '../../api/UserApi';
import { LoginUserInfo } from '../../bean/LoginUserInfo';
import { HMFlutterManager } from '../../manager/HMFlutterManager';
import { WindowImmersiveHelper } from '../../utils/WindowImmersiveHelper';
import { XToastUtils } from '../../utils/XToastUtils';

/** 页面背景色，对齐 Android `#F9F9F9` */
const PAGE_BG = '#F9F9F9';
/** 警告条背景色 */
const WARNING_BG = '#FFF0ED';
/** 警告文字色 */
const WARNING_TEXT_COLOR = '#F1343A';
/** 协议卡片圆角背景色（对齐 `dialog_privacy_bg_corners` 白底） */
const CARD_BG = '#FFFFFF';
/** 运营商认证条款 H5 地址 */
const OPERATOR_TERMS_URL =
  'https://static.histar.com/static/histar-wechat-mp/html/agreements/operator-terms.html';
/** 注销成功后延迟跳转登录页（毫秒），对齐 Android Handler 1s */
const EXIT_DELAY_MS = 1000;

@Entry
@Component
struct AccountCancellationPage {
  @State statusBarInsetVp: number = 0;
  /** 是否已勾选「已阅读并同意《运营商认证服务条款》」 */
  @State agreementChecked: boolean = false;
  /** 注销接口请求中，防止重复提交 */
  @State isSubmitting: boolean = false;

  aboutToAppear(): void {
    void this.applyImmersiveLayout();
  }

  onPageShow(): void {
    void this.applyImmersiveLayout();
  }

  /** 沉浸式 + 读取系统栏 inset */
  private async applyImmersiveLayout(): Promise<void> {
    const ctx = getContext(this);
    await WindowImmersiveHelper.enableImmersiveStatusBar(ctx);
    this.statusBarInsetVp = await WindowImmersiveHelper.getStatusBarInsetVp(ctx);
  }

  /**
   * 点击底部「确定」：未勾选协议时 Toast 提示；已勾选则弹出二次确认框。
   * 对齐 Android `tv_button_text` 点击 → `cbAgreement.isChecked()` 分支。
   */
  private onConfirmButtonClick(): void {
    if (!this.agreementChecked) {
      XToastUtils.toast($r('app.string.account_agreement_required'), this.getUIContext());
      return;
    }
    this.showCancellationConfirmDialog();
  }

  /**
   * 二次确认弹窗（对齐 Android `ConfirmDialog` + `islogoff` / `logoff_tip`）。
   */
  private showCancellationConfirmDialog(): void {
    AlertDialog.show({
      title: $r('app.string.account_logoff_title'),
      message: $r('app.string.account_logoff_message'),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: $r('app.string.cancel_button'),
        action: () => {
        },
      },
      secondaryButton: {
        value: $r('app.string.confirm'),
        fontColor: '#006EFF',
        action: () => {
          void this.performAccountCancellation();
        },
      },
    });
  }

  /**
   * 调用注销接口；成功后清空本地登录态并延迟跳转登录页。
   * 对齐 Android `UserApi.cancelAccount()` → Toast → `exitApp()`。
   */
  private async performAccountCancellation(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    try {
      await cancelAccount();
      LoginUserInfo.getInstance().cleanUserInfo();
      XToastUtils.toast($r('app.string.account_cancel_success'), this.getUIContext());
      setTimeout(() => {
        void this.exitToLoginPage();
      }, EXIT_DELAY_MS);
    } catch (err) {
      console.error(`AccountCancellationPage cancelAccount failed: ${JSON.stringify(err)}`);
    } finally {
      this.isSubmitting = false;
    }
  }

  /** 清空路由栈并进入 Histar 登录页（对齐 Android `mainApp.exitApp()` 回到未登录态） */
  private async exitToLoginPage(): Promise<void> {
    try {
      router.clear();
      await router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      console.error(`AccountCancellationPage exitToLoginPage failed: ${JSON.stringify(err)}`);
    }
  }

  /** 打开运营商认证服务条款 H5（对齐 Android `FlutterManager.openFlutter("/web/url")`） */
  private openOperatorTermsWeb(): void {
    const args: Record<string, Object> = {
      'url': OPERATOR_TERMS_URL,
      'title': '运营商认证服务条款',
    };
    HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_WEB_URL, args);
  }

  build() {
    Column() {
      Column() {
        this.TitleBarBuilder()
      }
      .padding({ top: this.statusBarInsetVp })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          this.WarningBarBuilder()
          this.ProtocolCardBuilder()
          this.AgreementRowBuilder()
          this.ConfirmButtonBuilder()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
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

      Text($r('app.string.account_cancel_title'))
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

  /** 顶部红色警告条（对齐 `ll_warning`） */
  @Builder
  WarningBarBuilder() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(20)
          .height(20)
          .fill(WARNING_TEXT_COLOR)
        Text('!')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(20)
      .height(20)

      Text($r('app.string.account_cancellation_warning'))
        .fontSize(14)
        .fontColor(WARNING_TEXT_COLOR)
        .layoutWeight(1)
        .margin({ left: 8 })
    }
    .width('100%')
    .height(48)
    .padding(12)
    .backgroundColor(WARNING_BG)
    .alignItems(VerticalAlign.Center)
  }

  /** 协议说明白色卡片（对齐 `protocol_card`） */
  @Builder
  ProtocolCardBuilder() {
    Column() {
      Text('协议说明')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#131212')
        .margin({ bottom: 10 })

      Text('注销后，您的账户信息将被清除，且部分权益将无法恢复，请您谨慎操作。')
        .fontSize(14)
        .fontColor($r('app.color.hs_color_text_secondary'))
        .margin({ bottom: 20 })

      Text('注销后将发生：')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.hs_color_text_secondary'))
        .margin({ bottom: 10 })

      Text($r('app.string.account_cancellation_content'))
        .fontSize(14)
        .fontColor($r('app.color.hs_color_text_secondary'))
        .lineHeight(22)

      Text('温馨提示：')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.hs_color_text_secondary'))
        .margin({ top: 10, bottom: 10 })

      Text($r('app.string.account_cancellation_warm_tip'))
        .fontSize(14)
        .fontColor($r('app.color.hs_color_text_secondary'))
        .lineHeight(22)
    }
    .width('100%')
    .margin(10)
    .padding(15)
    .backgroundColor(CARD_BG)
    .borderRadius(12)
  }

  /** 协议勾选 + 可点击条款链接（对齐 `cb_agreement` + `tv_agreement` Spannable） */
  @Builder
  AgreementRowBuilder() {
    Row() {
      Image(this.agreementChecked ? $r('app.media.login_checkbox_checked') :
        $r('app.media.login_checkbox_unchecked'))
        .width(20)
        .height(20)
        .onClick(() => {
          this.agreementChecked = !this.agreementChecked;
        })

      Text() {
        Span('已阅读并同意')
          .fontSize(12)
          .fontColor($r('app.color.hs_color_text_secondary'))
        Span($r('app.string.login_operator_terms'))
          .fontSize(12)
          .fontColor($r('app.color.hs_color_brand_link'))
          .onClick(() => {
            this.openOperatorTermsWeb();
          })
      }
      .margin({ left: 5 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 4, bottom: 4 })
  }

  /** 底部确定按钮（对齐 `tv_button_text` 品牌色圆角按钮） */
  @Builder
  ConfirmButtonBuilder() {
    Text($r('app.string.confirm'))
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.hs_color_black'))
      .textAlign(TextAlign.Center)
      .backgroundColor($r('app.color.hs_color_brand'))
      .borderRadius(24)
      .margin({ left: 20, right: 20, top: 20, bottom: 20 })
      .opacity(this.isSubmitting ? 0.6 : 1)
      .onClick(() => {
        this.onConfirmButtonClick();
      })
  }
}
