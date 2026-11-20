export function homeSurface(tab: number, profileStyle: number = 0): ResourceColor {
  if (tab === 0) { return $r('app.color.app_room_canvas') }
  if (tab === 1) { return $r('app.color.app_live_background') }
  if (tab === 3 || (tab === 4 && profileStyle === 1)) { return Color.White }
  if (tab === 4 && profileStyle === 2) { return $r('app.color.app_grouped_background') }
  return $r('app.color.app_background')
}

@Component
export struct HomeTabBar {
  @Prop selected: number = 1
  @Prop unreadCount: number = 0
  @Prop profileStyle: number = 0
  onSelect: (index: number) => void = () => {}
  private titles: Resource[] = [$r('app.string.app_meeting'), $r('app.string.app_live'), $r('app.string.app_call'),
    $r('app.string.app_messages'), $r('app.string.app_profile')]

  build() {
    Row() {
      ForEach(this.titles, (title: Resource, index: number) => {
        Stack({ alignContent: Alignment.Center }) {
          Text(title).fontSize(index === this.selected ? 17 : 16)
            .fontWeight(index === this.selected ? 600 : 500)
            .fontColor(this.selected === 1 ?
              (index === this.selected ? Color.White : $r('app.color.app_live_secondary')) :
              (index === this.selected ? $r('app.color.app_text') : $r('app.color.app_secondary')))
            .maxLines(1).minFontSize(12).maxFontSize(index === this.selected ? 17 : 16)
          if (index === 3 && this.unreadCount > 0) {
            Text(this.unreadCount > 99 ? '99+' : `${this.unreadCount}`).fontSize(10).fontColor(Color.White)
              .height(16).constraintSize({ minWidth: 20 }).padding({ left: 3, right: 3 })
              .backgroundColor($r('app.color.app_danger')).borderRadius(8).translate({ x: 23, y: -12 })
              .hitTestBehavior(HitTestMode.None)
          }
        }.layoutWeight(1).height(56).onClick(() => this.onSelect(index))
      })
    }.width('100%').height(56)
      .backgroundColor(homeSurface(this.selected, this.profileStyle))
  }
}
