import { promptAction } from '@kit.ArkUI'

@Component
export struct BroadcastTypeBarView {
  @State private segmentGap: number = 8
  private labels: Resource[] = [$r('app.string.app_video_type'), $r('app.string.app_voice_type'),
    $r('app.string.app_game_type')]

  build() {
    Row({ space: this.segmentGap }) {
      ForEach(this.labels, (label: Resource, index: number) => {
        Column() {
          Text(label).fontSize(18).fontWeight(index === 0 ? 600 : 500)
            .fontColor(index === 0 ? Color.White : '#8B90A0').maxLines(1).minFontSize(14).maxFontSize(18)
            .height(40).width('100%').textAlign(TextAlign.Center)
          if (index === 0) {
            Column().width(24).height(3).borderRadius(1.5)
              .linearGradient({ angle: 90, colors: [['#338CFF', 0], ['#59E0FF', 1]] })
          }
        }.height(48).layoutWeight(1).onClick(() => {
          if (index !== 0) { promptAction.showToast({ message: $r('app.string.app_placeholder') }) }
        })
      })
    }.width('100%').constraintSize({ maxWidth: 232 }).height(48)
      .onAreaChange((old: Area, area: Area) => {
        const gap = (area.width as number) >= 232 ? 20 : 8
        if (this.segmentGap !== gap) { this.segmentGap = gap }
      })
  }
}
