@Component
export struct ProfileUpdateInfoView {
  @Prop initialName: string = ''
  @Prop saving: boolean = false
  onSave: (name: string) => void = () => {}
  @State private value: string = ''

  aboutToAppear(): void { this.value = this.initialName }

  build() {
    Column() {
      Text($r('app.string.app_nickname')).fontSize(16).fontColor(Color.Black).height(60)
      Divider().color('#EEEEEE')
      TextArea({ text: this.value, placeholder: $r('app.string.app_nickname') })
        .height(40).fontSize(16).backgroundColor('#F5F5F5').borderRadius(4)
        .padding({ left: 8, right: 8, top: 6, bottom: 6 }).margin({ top: 17 })
        .enabled(!this.saving).onChange((name: string) => this.value = name)
      Text($r('app.string.app_edit_alias_hint')).fontSize(12).fontColor($r('app.color.app_secondary'))
        .width('100%').margin({ top: 8 })
      Button($r('app.string.app_save')).width('100%').height(44).fontSize(16).borderRadius(8)
        .backgroundColor($r('app.color.app_primary')).margin({ top: 5 })
        .enabled(!this.saving && this.value.trim().length > 0).onClick(() => this.onSave(this.value))
    }.width('100%').height(237).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
    // The native sheet owns keyboard avoidance; this editor does not apply a second keyboard offset.
  }
}
