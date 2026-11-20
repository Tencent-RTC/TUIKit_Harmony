@Component
export struct RoomMicLevelView {
  @Prop level: number = 0

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width(6.25)
        .height(10.625 * Math.min(100, Math.max(0, this.level)) / 100)
        .backgroundColor($r('app.color.roomkit_success'))
        .animation({ duration: 120, curve: Curve.Linear })
    }
    .width(20)
    .height(20)
    .padding({ top: 2.5, bottom: 7.125 })
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}
