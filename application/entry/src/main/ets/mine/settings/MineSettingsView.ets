import { AppPageHeader } from '../../common/AppPageHeader'
import { ProfileImage } from '../ProfileImage'

@Component
export struct MineSettingsView {
  @Prop nickname: string = ''
  @Prop avatarURL: string = ''
  onBack: () => void = () => {}
  onAvatar: () => void = () => {}
  onNickname: () => void = () => {}

  build() {
    Column() {
      AppPageHeader({ title: $r('app.string.app_settings'), onBack: this.onBack })
      Scroll() {
        Column() {
          Row({ space: 10 }) {
            Text($r('app.string.app_avatar')).fontSize(16).fontColor('#333333').layoutWeight(1)
            ProfileImage({ url: this.avatarURL, diameter: 36 })
            Image($r('app.media.mine_detail')).width(18).height(18).objectFit(ImageFit.Contain)
          }.width('100%').height(56).padding({ left: 20, right: 20 }).onClick(() => this.onAvatar())
          Divider().color('#EEEEEE').margin({ left: 20, right: 20 })
          Row({ space: 10 }) {
            Text($r('app.string.app_nickname')).fontSize(16).fontColor('#333333').layoutWeight(1)
            Text(this.nickname).fontSize(15).fontColor('#333333').maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).constraintSize({ maxWidth: 120 })
            Image($r('app.media.mine_detail')).width(18).height(18).objectFit(ImageFit.Contain)
          }.width('100%').height(56).padding({ left: 20, right: 20 }).onClick(() => this.onNickname())
          Divider().color('#EEEEEE').margin({ left: 20, right: 20 })
        }.width('100%').margin({ top: 20 })
      }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
