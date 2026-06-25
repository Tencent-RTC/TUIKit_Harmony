import { router } from '@kit.ArkUI';
import { inputMethod } from '@kit.IMEKit';
import { TUICallKit } from '@tencentcloud/tuicallkit';
import { UserStore } from '../common/UserStore';
import { SettingsConfig } from '../common/SettingsConfig';
import { genTestUserSig, SDKAPPID } from '../debug/GenerateTestUserSig';

@Entry
@Component
struct Index {
  @State autoLoginState: boolean = false;
  @State userId: string = '';
  @State isLogging: boolean = false;
  private callKit: TUICallKit | null = null;

  aboutToAppear(): void {
    this.callKit = TUICallKit.createInstance(getContext(this));
    this.loadUserStore();
  }

  build() {
    Stack() {
      Row() {
        Image($r('app.media.tencent_cloud'))
          .width(80)
          .height(80)
          .objectFit(ImageFit.Contain)

        Text($r('app.string.app_title'))
          .fontSize(32)
          .fontWeight(FontWeight.Regular)
          .fontColor('#333333')
          .margin({ left: 10 })
      }
      .width('100%')
      .height(100)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: 100 })

      Column() {
        Row() {
          Text($r('app.string.login_userid_label'))
            .fontSize(20)
            .fontColor('#000000')
            .margin({ left: 20 })

          TextInput({ placeholder: $r('app.string.login_userid_placeholder'), text: this.userId })
            .layoutWeight(1)
            .fontSize(20)
            .fontColor('#333333')
            .placeholderColor('#BBBBBB')
            .placeholderFont({ size: 20 })
            .backgroundColor(Color.Transparent)
            .margin({ left: 20 })
            .padding({ right: 20 })
            .inputFilter('[a-zA-Z0-9_]')
            .onChange((value: string) => {
              this.userId = value;
            })
        }
        .width('100%')
        .height(50)
        .backgroundColor(Color.White)
        .borderRadius(10)
        .border({ width: 1, color: '#808080' })
        .alignItems(VerticalAlign.Center)

        Button($r('app.string.login_button'))
          .width('100%')
          .height(50)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#006EFF')
          .borderRadius(10)
          .margin({ top: 40 })
          .enabled(this.userId.trim().length > 0 && !this.isLogging)
          .opacity(this.userId.trim().length > 0 && !this.isLogging ? 1.0 : 0.5)
          .onClick(() => {
            this.handleLogin();
          })

        Column() {
          Row() {
            Text($r('app.string.login_auto_login'))
              .fontSize(17)
              .fontColor('#000000')
            Toggle({ type: ToggleType.Switch, isOn: this.autoLoginState })
              .width(51)
              .height(31)
              .selectedColor('#006EFF')
              .margin({ left: 20, right: 10 })
              .onChange(async (isOn: boolean) => {
                this.autoLoginState = isOn;
                await UserStore.instance.setAutoLogin(isOn);
              })
          }
          .height(44)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.End)
        .margin({ top: 20 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .offset({ y: 60 })

      if (this.isLogging) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#006EFF')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#4D000000')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.Block)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .alignContent(Alignment.Center)
    .onClick(() => {
      if (!this.isLogging) {
        inputMethod.getController().stopInputSession();
      }
    })
  }

  private loadUserStore(): void {
    try {
      const store = UserStore.instance;
      this.autoLoginState = store.autoLogin;
      if (store.userId.length > 0) {
        this.userId = store.userId;
        if (this.autoLoginState) {
          this.handleLogin();
        }
      }
    } catch (err) {
      console.error(`[Login] loadUserStore error: ${JSON.stringify(err)}`);
    }
  }

  private async handleLogin(): Promise<void> {
    const trimmedUserId = this.userId.trim();
    if (trimmedUserId.length === 0 || this.isLogging) {
      return;
    }
    this.userId = trimmedUserId;
    this.isLogging = true;

    try {
      const userSig = genTestUserSig(trimmedUserId);
      console.info(`[Login] userId=${trimmedUserId}, sdkAppId=${SDKAPPID}, userSig=${userSig.substring(0, 20)}...`);

      await UserStore.instance.login(SDKAPPID, trimmedUserId, userSig);
      console.info('[Login] login success');

      SettingsConfig.shared().userId = trimmedUserId;
      this.applyDemoConfigToSDK();

      if (UserStore.instance.hasNickname) {
        router.replaceUrl({ url: 'pages/MainPage' });
      } else {
        router.pushUrl({ url: 'pages/RegisterPage' });
      }
    } catch (err) {
      console.error(`[Login] Error: ${JSON.stringify(err)}`);
    } finally {
      this.isLogging = false;
    }
  }

  /**
   * Push the demo's `SettingsConfig` toggles into the SDK so that the
   * settings UI matches what the SDK actually applies. Mirrors iOS
   * AppDelegate.configIfLoggedIn — without this, the SDK keeps its own
   * defaults which disagree with what the demo's settings page shows.
   */
  private applyDemoConfigToSDK(): void {
    const cfg = SettingsConfig.shared();
    try {
      const sdk = this.callKit;
      if (!sdk) {
        return;
      }
      sdk.enableMuteMode(cfg.mute);
      // sdk.enableFloatWindow(cfg.floatWindow);
      sdk.enableIncomingBanner(cfg.enableIncomingBanner);
      // sdk.enableVirtualBackground(cfg.enableVirtualBackground);
      if (cfg.ringUrl.length > 0) {
        sdk.setCallingBell(cfg.ringUrl);
      }
    } catch (e) {
      console.warn(`[Login] applyDemoConfigToSDK failed: ${JSON.stringify(e)}`);
    }
  }
}
