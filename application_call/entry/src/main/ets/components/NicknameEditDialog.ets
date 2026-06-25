@CustomDialog
export struct NicknameEditDialog {
  controller: CustomDialogController;
  currentNickname: string = '';
  onConfirm: (newName: string) => void = () => {};
  @State inputValue: string = '';

  aboutToAppear(): void {
    this.inputValue = this.currentNickname;
  }

  get isConfirmEnabled(): boolean {
    return this.inputValue.trim().length > 0;
  }

  build() {
    Column() {
      Column() {
        Row() {
          Text($r('app.string.nickname_edit_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262B32')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ left: 40 })

          Text('✕')
            .fontSize(20)
            .fontColor('#888888')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.controller.close();
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 8 })
        .alignItems(VerticalAlign.Center)

        Divider().color('#EEEEEE').height(0.5)

        TextInput({ placeholder: $r('app.string.register_nickname_placeholder'), text: this.inputValue })
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#BBBBBB')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .height(40)
          .margin({ top: 20, left: 16, right: 16 })
          .maxLength(20)
          .onChange((value: string) => {
            this.inputValue = value;
          })

        Text($r('app.string.nickname_edit_hint'))
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 8, left: 16 })
          .alignSelf(ItemAlign.Start)

        Button($r('app.string.nickname_edit_ok'))
          .width('calc(100% - 32vp)')
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor(this.isConfirmEnabled ? '#1C66E5' : '#CCCCCC')
          .borderRadius(8)
          .margin({ top: 20, bottom: 20 })
          .enabled(this.isConfirmEnabled)
          .onClick(() => {
            this.onConfirm(this.inputValue.trim());
            this.controller.close();
          })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 12, topRight: 12 })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }
}
