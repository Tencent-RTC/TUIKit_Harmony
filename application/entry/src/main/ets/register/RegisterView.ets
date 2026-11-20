import { AppPageHeader } from '../common/AppPageHeader'

@Component
export struct RegisterView {
  @Prop loading: boolean = false
  onBack: () => void = () => {}
  onRegister: (nickname: string) => void = () => {}
  @State private nickname: string = ''

  build() {
    Column() {
      AppPageHeader({ title: $r('app.string.app_register'), onBack: this.onBack })
      Scroll() {
        Column({ space: 0 }) {
          Image('https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png')
            .width(100).height(100).borderRadius(50).objectFit(ImageFit.Cover).margin({ top: 26, bottom: 40 })
          TextInput({ text: this.nickname, placeholder: $r('app.string.app_nickname') })
            .height(57).fontSize(16).backgroundColor(Color.Transparent).maxLength(20)
            .onChange((value: string) => this.nickname = value)
          Divider().color('#EEEEEE')
          Text($r('app.string.app_nickname_hint')).fontSize(16).fontColor($r('app.color.app_secondary'))
            .width('100%').margin({ top: 10 })
          Button($r('app.string.app_register')).width('100%').height(52).borderRadius(26).fontSize(18)
            .backgroundColor($r('app.color.app_primary')).margin({ top: 40, bottom: 32 })
            .enabled(!this.loading && this.nickname.trim().length > 0).onClick(() => this.onRegister(this.nickname))
        }.width('100%').padding({ left: 40, right: 40 })
      }.width('100%').layoutWeight(1)
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
