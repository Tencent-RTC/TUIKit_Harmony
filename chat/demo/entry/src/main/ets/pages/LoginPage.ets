import Prompt from '@system.prompt'
import bundleManager from '@ohos.bundle.bundleManager'
import HttpManager from '../network/HttpManager'
import { ImageSizeUtil, ThemeState, Log, Toast, TextUtils } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { MMKV } from '@tencent/mmkv';
import router from '@ohos.router';
import web_webview from '@ohos.web.webview'
import DemoConstants from '../utils/DemoConstants';
import { LoginStore } from '@tencentcloud/atomicxcore';

class LoginCompletionHandler {
  private page: LoginPage;
  private sdkAppId: number = 0;
  private userId: string = '';
  private userSig: string = '';

  constructor(page: LoginPage, sdkAppId: number, userId: string, userSig: string) {
    this.page = page;
    this.sdkAppId = sdkAppId;
    this.userId = userId;
    this.userSig = userSig;
  }

  onSuccess(): void {
    Log.i("LoginPage", "login success");
    this.page.onLoginSuccess(this.sdkAppId, this.userId, this.userSig);
  }

  onFailure(code: number, desc: string): void {
    this.page.onLoginFailed(code, desc);
  }
}

@Observed
class ImageVerificationJsBridge {
  ticket?: string = undefined;
  captchaAppID?: string = undefined;
  sessionID?: string = undefined;
  randStr?: string = undefined;
  phoneNumber?: string = undefined;
  verifyCode?: string = undefined;
  showWeb: boolean = false;

  verifySuccess(ticket: string, randStr: string): void {
    this.ticket = ticket;
    this.randStr = randStr;

    HttpManager.getSms(this.captchaAppID, this.ticket, this.randStr, this.phoneNumber)
      .then((sessionResponse) => {
        this.sessionID = sessionResponse?.data.data.sessionId;
      })
      .catch((reason: Object) => {
        Log.e("LoginPage", "failed, " + reason);
      });
    this.showWeb = false;
  }

  verifyError(errorCode: number, errorMsg: string): void {
    this.showWeb = false;
  }

  getLanguage(): string {
    return "en";
  }

  getCaptchaAppID(): string | undefined {
    return this.captchaAppID;
  }
}

@Entry
@Component
struct LoginPage {
  @State showDebugLogin: boolean = false;
  @State inLogin: boolean = false;
  @State imageVerificationJsBridge: ImageVerificationJsBridge = new ImageVerificationJsBridge();
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private controller: web_webview.WebviewController = new web_webview.WebviewController();

  aboutToAppear() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {
      let buildType = bundleInfo.appInfo.appProvisionType;
      if (buildType === "debug") {
        this.showDebugLogin = true;
      }
    }).catch((reason: Object) => {
      Log.e("LoginPage", "get buildType failed, " + reason);
    })
  }

  build() {
    Column() {
      Column({ space: 10 }) {

        TextInput({ placeholder: this.imageVerificationJsBridge.phoneNumber?.toString() ?? "PhoneNumber" })
          .type(InputType.PhoneNumber)
          .borderRadius(4)
          .onChange((str) => {
            this.imageVerificationJsBridge.phoneNumber = str;
          });

        Button("Get VerifyCode")
          .fontColor(Color.White)
          .padding(8)
          .type(ButtonType.Normal)
          .borderRadius(6)
          .stateStyles({
            normal: {.opacity(1)
            },
            disabled: {.opacity(0.6)
            }
          })
          .enabled((!this.inLogin) && !TextUtils.isEmpty(this.imageVerificationJsBridge.phoneNumber))
          .onClick(() => {
            HttpManager.getCaptchaAppID()
              .then((captchaAppID) => {
                this.imageVerificationJsBridge.captchaAppID = captchaAppID?.toString();
                this.imageVerificationJsBridge.showWeb = true;
              })
              .catch((reason: Object) => {
                Log.e("LoginPAge", "get verify code failed, " + reason);
              })
          })

        TextInput({ placeholder: "VerifyCode" })
          .type(InputType.Number)
          .borderRadius(4)
          .onChange((str) => {
            this.imageVerificationJsBridge.verifyCode = str;
          });

        Button($r("app.string.demo_login_button_name"), { stateEffect: true, type: ButtonType.Normal })
          .fontSize($r("app.float.demo_dev_login_user_name_font_size"))
          .fontColor(Color.White)
          .width('100%')
          .borderRadius(6)
          .stateStyles({
            normal: {.opacity(1)
            },
            disabled: {.opacity(0.6)
            }
          })
          .padding(12)
          .enabled((!this.inLogin) && !TextUtils.isEmpty(this.imageVerificationJsBridge.phoneNumber) &&
            !TextUtils.isEmpty(this.imageVerificationJsBridge.verifyCode))
          .margin({ top: 30 })
          .onClick(() => {
            this.login();
          })

        if (this.showDebugLogin) {
          Button("开发者登录", { stateEffect: true, type: ButtonType.Normal })
            .width('90%')
            .padding(6)
            .borderRadius(6)
            .fontColor(Color.White)
            .onClick(() => {
              router.replaceUrl({ url: "pages/DevLoginPage" });
            })
        }
      }

      Column() {
        if (this.imageVerificationJsBridge.showWeb) {
          Web({ src: $rawfile("verification.html"), controller: this.controller })
            .javaScriptAccess(true)
            .javaScriptProxy({
              object: this.imageVerificationJsBridge,
              name: "imageVerificationJsBridge",
              methodList: ["verifySuccess", "verifyError", "getCaptchaAppID", "getLanguage"],
              controller: this.controller
            })
        }
      }
    }.width('100%')
    .height('100%')
  }

  login(): void {
    if (this.imageVerificationJsBridge.phoneNumber && this.imageVerificationJsBridge.verifyCode &&
    this.imageVerificationJsBridge.sessionID) {
      this.inLogin = true;
      HttpManager.login(this.imageVerificationJsBridge.phoneNumber, this.imageVerificationJsBridge.verifyCode,
        this.imageVerificationJsBridge.sessionID)
        .then((loginInfo) => {
          const mmkv = MMKV.defaultMMKV();
          const sdkAppId: number = loginInfo.data.data.sdkAppId;
          const userId: string = loginInfo.data.data.userId;
          const userSig: string = loginInfo.data.data.userSig;
          mmkv.encodeString(DemoConstants.LOGIN_USER_ID, userId);
          mmkv.encodeString(DemoConstants.LOGIN_USER_SIG, userSig);
          mmkv.encodeBool(DemoConstants.AUTO_LOGIN, true);
          const handler = new LoginCompletionHandler(this, sdkAppId, userId, userSig);
          LoginStore.shared().login(sdkAppId, userId, userSig, getContext())
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
        })
        .catch((reason: Object) => {
          this.inLogin = false;
          Log.i("LoginPage", "login failed, " + reason);
        });
    }
  }

  onLoginSuccess(sdkAppId: number, userId: string, userSig: string): void {
    this.inLogin = false;
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID || '';
    Toast.success($r('app.string.login_success_message', loginUserID), this.getUIContext());

    router.replaceUrl({ url: "pages/HomePage" });
  }

  onLoginFailed(code: number, desc: string): void {
    this.inLogin = false;
    Log.i("LoginPage", "login failed, " + code + ", " + desc);
  }
}
