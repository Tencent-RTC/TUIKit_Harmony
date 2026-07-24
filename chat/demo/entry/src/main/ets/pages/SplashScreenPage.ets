import router from '@ohos.router';
import hilog from '@ohos.hilog';
import { genTestUserSig, SDKAPPID } from '../signature/GenerateTestUserSig';
import Prompt from '@system.prompt';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { ImageSizeUtil, ThemeState, Log, Toast, TextUtils, ContextProvider } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { MMKV } from '@tencent/mmkv';
import DemoConstants from '../utils/DemoConstants';
import { LoginStore, UserProfile } from '@tencentcloud/atomicxcore';
import { AppBuilderConfig, AppBuilderHelper } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { TIMPushInterfaces } from '../push/TIMPushInterfaces';

class SplashLoginCompletionHandler {
  private userID: string = '';
  private userSig: string = '';

  constructor(userID: string, userSig: string) {
    this.userID = userID;
    this.userSig = userSig;
  }

  onSuccess(): void {
    const appContext = ContextProvider.getAppContext();
    if (appContext && (appContext as common.UIAbilityContext).resourceManager) {
      TIMPushInterfaces.registerPush(appContext);
    }

    router.replaceUrl({ url: "pages/HomePage" });
  }

  onFailure(code: number, desc: string): void {
    Log.e("SplashScreenPage", "auto login failed, " + code + ", " + desc);
    router.replaceUrl({ url: "pages/LoginPage" });
  }
}

@Entry
@Component
struct SplashScreenPage {
  aboutToAppear() {
    let mmkv = MMKV.defaultMMKV();
    let autoLogin = mmkv.decodeBool(DemoConstants.AUTO_LOGIN, false);
    if (autoLogin) {
      let userID = mmkv.decodeString(DemoConstants.LOGIN_USER_ID);
      let userSig = mmkv.decodeString(DemoConstants.LOGIN_USER_SIG);
      const handler = new SplashLoginCompletionHandler(userID!!, userSig!!);
      LoginStore.shared().login(SDKAPPID, userID!!, userSig!!, getContext())
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
    } else {
      router.replaceUrl({ url: "pages/LoginPage" })
    }
  }

  build() {
    Column() {
      Image($r("app.media.demo_ic_logo"))
        .width($r("app.float.demo_splash_icon_width"))
        .width($r("app.float.demo_splash_icon_height"))
        .interpolation(ImageInterpolation.High)
        .objectFit(ImageFit.Contain)

      Text($r('app.string.demo_title'))
        .fontColor(Color.Black)
        .fontSize($r("app.float.demo_splash_title_font_size"))
        .fontWeight(FontWeight.Bold)
        .margin({ top: $r("app.float.demo_splash_title_margin_top") })
    }
    .alignItems(HorizontalAlign.Center)
    .align(Alignment.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}
