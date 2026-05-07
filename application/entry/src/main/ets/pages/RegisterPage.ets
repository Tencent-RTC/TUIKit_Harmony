import { router } from '@kit.ArkUI';
import { inputMethod } from '@kit.IMEKit';
import { UserStore } from '../common/UserStore';
import { Constants } from '../common/Constants';

@Entry
@Component
struct RegisterPage {
  @State nickname: string = '';
  @StorageProp(Constants.KEY_AVATAR_URL) avatarUrl: string = Constants.DEFAULT_AVATAR_URL;
  @State isRegistering: boolean = false;
  @State isButtonEnabled: boolean = false;

  private updateButtonState(): void {
    this.isButtonEnabled = this.nickname.trim().length > 0 && !this.isRegistering;
  }

  async handleRegister(): Promise<void> {
    if (!this.isButtonEnabled) {
      return;
    }
    this.isRegistering = true;
    this.updateButtonState();

    try {
      const store = UserStore.instance;
      await store.setSelfInfo(this.nickname.trim(), this.avatarUrl);
      router.replaceUrl({ url: 'pages/MainPage' });
    } catch (err) {
      console.error(`[Register] Error: ${JSON.stringify(err)}`);
    } finally {
      this.isRegistering = false;
      this.updateButtonState();
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor('#000000')
          .onClick(() => {
            router.back();
          })

        Text($r('app.string.register_button'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(24).height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Image(this.avatarUrl)
        .width(100)
        .height(100)
        .borderRadius(50)
        .objectFit(ImageFit.Cover)
        .margin({ top: 20 })

      Column() {
        TextInput({
          placeholder: $r('app.string.register_nickname_placeholder')
        })
          .type(InputType.Normal)
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#BBBBBB')
          .caretColor('#006EFF')
          .backgroundColor(Color.Transparent)
          .maxLength(20)
          .padding({ left: 0, right: 0, bottom: 8 })
          .onChange((value: string) => {
            this.nickname = value;
            this.updateButtonState();
          })

        Divider()
          .color('#EEEEEE')
          .height(1)

        Text($r('app.string.register_nickname_hint'))
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 8 })
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding({ left: 40, right: 40 })
      .margin({ top: 40 })
      .alignItems(HorizontalAlign.Start)

      Button($r('app.string.register_button'))
        .width('80%')
        .height(52)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(this.isButtonEnabled ? '#006EFF' : '#CCCCCC')
        .borderRadius(26)
        .margin({ top: 40, left: 20, right: 20 })
        .enabled(this.isButtonEnabled)
        .onClick(() => {
          this.handleRegister();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .onClick(() => {
      inputMethod.getController().stopInputSession();
    })
  }
}
