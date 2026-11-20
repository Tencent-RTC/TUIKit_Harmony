@Component
export struct LoginView {
  @Prop initialUserID: string = ''
  @Prop loading: boolean = false
  @Prop automatic: boolean = false
  onLogin: (userID: string) => void = () => {}
  onAutomatic: (automatic: boolean) => void = () => {}
  @State private userID: string = ''

  aboutToAppear(): void { this.userID = this.initialUserID }

  build() {
    Scroll() {
      Column() {
        Row({ space: 10 }) {
          Image($r('app.media.tencent_cloud')).width(80).height(80).objectFit(ImageFit.Contain)
          Text($r('app.string.app_brand')).fontSize(32).fontColor($r('app.color.app_text')).layoutWeight(1)
        }.width('100%').padding({ left: 20, right: 20 }).margin({ top: 100, bottom: 100 })
        Row({ space: 20 }) {
          Text('UserId').fontSize(20).fontColor($r('app.color.app_text'))
          TextInput({ text: this.userID, placeholder: 'userId' }).layoutWeight(1).height(56)
            .backgroundColor(Color.Transparent).fontSize(20).enabled(!this.loading)
            .onChange((value: string) => this.userID = value)
        }.padding({ left: 20, right: 12 }).border({ width: 1, color: '#808080' }).borderRadius(10)
        Button($r('app.string.app_login')).width('100%').height(52).borderRadius(10).fontSize(20)
          .backgroundColor($r('app.color.app_primary')).margin({ top: 40 }).enabled(!this.loading)
          .onClick(() => this.onLogin(this.userID))
        Row({ space: 20 }) {
          Text($r('app.string.app_test_env')).fontSize(16).fontColor($r('app.color.app_text'))
          Toggle({ type: ToggleType.Switch, isOn: false }).enabled(false)
        }.width('100%').justifyContent(FlexAlign.End).margin({ top: 20 })
        Row({ space: 20 }) {
          Text($r('app.string.app_auto_login')).fontSize(16).fontColor($r('app.color.app_text'))
          Toggle({ type: ToggleType.Switch, isOn: this.automatic })
            .onChange((value: boolean) => this.onAutomatic(value))
        }.width('100%').justifyContent(FlexAlign.End).margin({ top: 10, bottom: 32 })
      }.width('100%').padding({ left: 20, right: 20 })
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
