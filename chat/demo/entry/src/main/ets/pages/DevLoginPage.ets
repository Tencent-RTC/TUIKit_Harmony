import { LoginStore } from '@tencentcloud/atomicxcore';
import Prompt from '@system.prompt';
import { genTestUserSig, SDKAPPID } from '../signature/GenerateTestUserSig';
import router from '@ohos.router';
import { MMKV } from '@tencent/mmkv';
import { ImageSizeUtil, ThemeState, Log, Toast, ContextProvider } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import DemoConstants from '../utils/DemoConstants';
import { TIMPushInterfaces } from '../push/TIMPushInterfaces';
import { common } from '@kit.AbilityKit';

class DevLoginCompletionHandler {
  private page: DevLoginPage;
  private userID: string = '';
  private userSig: string = '';

  constructor(page: DevLoginPage, userID: string, userSig: string) {
    this.page = page;
    this.userID = userID;
    this.userSig = userSig;
  }

  onSuccess(): void {
    Log.i("DevLoginPage", "login success");
    this.page.onLoginSuccess(this.userID, this.userSig);
  }

  onFailure(code: number, desc: string): void {
    this.page.onLoginFailed(code, desc);
  }
}

@Entry
@Component
struct DevLoginPage {
  @State userID?: string = undefined;
  @State inLogin: boolean = false;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private mmkv?: MMKV;

  aboutToAppear() {
    this.mmkv = MMKV.defaultMMKV();
    let userID = this.mmkv.decodeString(DemoConstants.LOGIN_USER_ID);
    if (userID && userID.length > 0) {
      this.userID = userID;
    }
  }

  build() {
    Column() {

      Image($r("app.media.demo_ic_logo"))
        .width("60%")
        .interpolation(ImageInterpolation.High)
        .objectFit(ImageFit.Contain)

      Row({ space: 10 }) {
        Text($r("app.string.demo_dev_login_user_name"))
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontSize($r("app.float.demo_dev_login_user_name_font_size"))

        TextInput({ placeholder: this.userID ?? $r("app.string.demo_dev_login_user_name") })
          .layoutWeight(1)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontSize($r("app.float.demo_dev_login_user_name_font_size"))
          .borderRadius(4)
          .onChange((str: string) => {
            this.userID = str;
          })
      }
      .width('100%')
      .margin({ top: 100 })

      Button($r("app.string.demo_login_button_name"), { stateEffect: true, type: ButtonType.Normal })
        .fontSize($r("app.float.demo_dev_login_user_name_font_size"))
        .fontColor(Color.White)
        .width('100%')
        .borderRadius(6)
        .padding(12)
        .enabled(!this.inLogin && (this.userID?.length ?? 0) > 0)
        .stateStyles({
          normal: {
            .opacity(1)
          },
          disabled: {
            .opacity(0.6)
          }
        })
        .margin({ top: 30 })
        .onClick(() => {
          this.login();
        })

    }
    .padding(16)
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  login(): void {
    if (this.userID && this.userID.length > 0) {
      this.inLogin = true;
      const userSig = genTestUserSig(this.userID);
      const userID = this.userID;
      this.mmkv?.encodeString(DemoConstants.LOGIN_USER_ID, userID);
      this.mmkv?.encodeString(DemoConstants.LOGIN_USER_SIG, userSig);
      this.mmkv?.encodeBool(DemoConstants.AUTO_LOGIN, true);
      const handler = new DevLoginCompletionHandler(this, userID, userSig);
      LoginStore.shared().login(SDKAPPID, userID, userSig, getContext())
        .then(() => {
          handler.onSuccess();
        })
        .catch((reason: Object) => {
          let code = 0;
          let desc = String(reason);
          if (reason instanceof Error) {
            desc = reason.message;
          }
          handler.onFailure(code, desc);
        });
    }
  }

  onLoginSuccess(userID: string, userSig: string): void {
    this.inLogin = false;
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID || '';
    Toast.success($r('app.string.login_success_message', loginUserID), this.getUIContext());
    this.registerPush();
    router.replaceUrl({ url: "pages/HomePage" });
  }

  private registerPush(): void {
    try {
      const appContext = ContextProvider.getAppContext();
      if (appContext && (appContext as common.UIAbilityContext).resourceManager) {
        TIMPushInterfaces.registerPush(appContext);
      }
    } catch (reason) {
      Log.i("DevLoginPage", "register push failed, " + reason);
    }
  }

  onLoginFailed(code: number, desc: string): void {
    this.inLogin = false;
    Log.i("DevLoginPage", "login failed, " + code + ", " + desc);
  }
}
