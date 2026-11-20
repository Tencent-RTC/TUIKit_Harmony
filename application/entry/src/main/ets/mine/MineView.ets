import { MineTableViewCell } from './MineTableViewCell'
import { ProfileImage } from './ProfileImage'

@Component
export struct MineView {
  @Prop nickname: string = ''
  @Prop userID: string = ''
  @Prop avatarURL: string = ''
  onSettings: () => void = () => {}
  onLogs: () => void = () => {}
  onLogout: () => void = () => {}
  @State private containerWidth: number = 0
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0

  build() {
    Scroll() {
      Column() {
        Stack({ alignContent: Alignment.TopStart }) {
          Image($r('app.media.mine_bg')).width('100%').height('100%').objectFit(ImageFit.Cover)
          Column() {
            Text($r('app.string.app_personal')).fontSize(16).fontWeight(600).fontColor(Color.Black)
              .height(44).width('100%').textAlign(TextAlign.Center).margin({ top: this.safeTop })
            Blank()
            ProfileImage({ url: this.avatarURL, diameter: 72 })
          }.width('100%').height('100%')
        }.width('100%').height(this.containerWidth * 112 / 375 + 44 + this.safeTop)
        Text(this.nickname || this.userID).fontSize(18).fontWeight(600).fontColor('#262B32')
          .width('100%').padding({ left: 20, right: 20 }).textAlign(TextAlign.Center).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 12 })
        Text(`ID:${this.userID}`).fontSize(12).fontColor('#626E84').margin({ top: 2 })
        Column() {
          Column() {
            MineTableViewCell({ title: $r('app.string.app_settings'), icon: $r('app.media.mine_settings'),
              onSelect: this.onSettings })
            MineTableViewCell({ title: $r('app.string.app_logs'), icon: $r('app.media.mine_log'), onSelect: this.onLogs })
          }.width('100%').height(126).padding({ top: 8, bottom: 2 }).backgroundColor(Color.White).borderRadius(10)
            .margin({ top: 20 })
          Button($r('app.string.app_logout')).width('100%').height(52).fontSize(16).fontWeight(600)
            .fontColor($r('app.color.app_danger')).backgroundColor(Color.White).borderRadius(10)
            .margin({ top: 12, bottom: 24 }).onClick(() => {
              this.getUIContext().showAlertDialog({ message: $r('app.string.app_logout_confirm'),
                buttons: [{ value: $r('app.string.app_cancel'), action: () => {} },
                  { value: $r('app.string.app_confirm'), action: () => this.onLogout() }] })
            })
        }.width('100%').padding({ left: 20, right: 20 })
      }.width('100%')
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
      .onAreaChange((old: Area, area: Area) => this.containerWidth = area.width as number)
  }
}
