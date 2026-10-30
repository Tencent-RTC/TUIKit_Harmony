import { LiveToast } from 'tuilivekit'

const userIDMaxLength: number = 20
const accentColor: string = 'rgba(51, 112, 255, 1)'

@Component
export struct LoginViewController {
  @Prop initialUserID: string = ''
  @Prop isLoading: boolean = false
  onLogin?: (userID: string) => void
  @State private userID: string = ''
  @StorageProp('tuilivekit.safeArea.top') safeTop: number = 0

  aboutToAppear(): void {
    this.userID = this.initialUserID
  }

  private login(): void {
    const userID = this.userID.trim()
    if (userID.length === 0) {
      LiveToast.show(getContext().resourceManager.getStringByNameSync('livekit_access_user_id_required'))
      return
    }
    this.onLogin?.(userID)
  }

  @Builder
  decoration(color: string, size: number, x: number | string, y: number) {
    Column().width(size).height(size).borderRadius(16).backgroundColor(color).position({ x: x, y: y })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.decoration('#FFFFFF', 120, -30, 20)
      this.decoration('rgba(245, 249, 254, 1)', 140, 80, -40)
      Column().width(90).height(90).borderRadius(16).backgroundColor(Color.White).position({ right: 20, top: 60 })
      Column().width(80).height(80).borderRadius(16).backgroundColor('rgba(245, 249, 254, 1)')
        .position({ right: -60, top: 140 })
      Column() {
        Row({ space: 10 }) {
          Image($r('app.media.app_ic_cloud_brand')).width(44).height(44).objectFit(ImageFit.Contain)
          Text($r('app.string.livekit_access_brand')).fontSize(24).fontWeight(FontWeight.Bold).fontColor('rgba(26, 26, 26, 1)')
        }
        .margin({ top: 100 })
        Row({ space: 12 }) {
          Image($r('app.media.app_ic_phone')).width(20).height(20).objectFit(ImageFit.Contain)
          TextInput({ text: $$this.userID, placeholder: $r('app.string.livekit_access_user_id_placeholder') })
            .fontSize(16)
            .fontColor('rgba(26, 26, 26, 1)')
            .backgroundColor(Color.Transparent)
            .padding(0)
            .layoutWeight(1)
            .maxLength(userIDMaxLength)
            .inputFilter('[a-zA-Z0-9]')
            .enterKeyType(EnterKeyType.Done)
            .cancelButton({ style: CancelButtonStyle.INPUT })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .borderRadius(8)
        .borderWidth(1)
        .borderColor(accentColor)
        .backgroundColor(Color.White)
        .margin({ top: 40 })
        Button($r('app.string.livekit_access_login'))
          .width('100%')
          .height(56)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor(accentColor)
          .borderRadius(28)
          .enabled(!this.isLoading)
          .margin({ top: 24 })
          .onClick(() => this.login())
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(234, 241, 251, 1)')
    .padding({ top: this.safeTop })
  }
}
