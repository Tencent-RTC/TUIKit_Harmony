import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveHomeListState, LiveHomeListStore } from './LiveHomeListStore'
import { LiveHomeItemView } from './LiveHomeItemView'

@Component
export struct LiveHomeListView {
  store: LiveHomeListStore = new LiveHomeListStore()
  @Prop @Watch('stateChanged') state: LiveHomeListState = new LiveHomeListState()
  onSelect: (info: LiveInfo) => void = () => {}
  onFirstVisibleID: (liveID: string) => void = () => {}
  @State private containerWidth: number = 0
  @State private firstVisibleIndex: number = 0

  aboutToAppear(): void { this.emitFirstVisibleID() }

  private stateChanged(): void { this.emitFirstVisibleID() }

  private firstVisibleID(): string {
    const info = this.state.items[this.firstVisibleIndex]
    return info?.liveID ?? ''
  }

  private emitFirstVisibleID(): void { this.onFirstVisibleID(this.firstVisibleID()) }

  build() {
    Stack() {
      Refresh({ refreshing: this.state.loading && this.state.loaded && this.state.refreshing }) {
        Grid() {
          LazyForEach(this.store.source, (info: LiveInfo) => {
            GridItem() {
              LiveHomeItemView({ info: info, onSelect: this.onSelect })
            }.height(Math.max(0, (this.containerWidth - 34) / 2) * 1.35)
          }, (info: LiveInfo) => info.liveID)
          if (this.state.items.length > 0) {
            GridItem() {
              if (this.state.loading && !this.state.refreshing) {
                LoadingProgress().width(24).height(24).color(Color.White)
              } else if (this.state.error.length > 0) {
                Button($r('app.string.app_retry')).height(44).backgroundColor('#20232C')
                  .onClick(() => this.store.retry())
              }
            }.columnStart(0).columnEnd(1).height(52)
          }
        }.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(12).padding(12)
          .width('100%').height('100%').edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .onScrollIndex((start: number, end: number) => {
            this.firstVisibleIndex = start
            this.emitFirstVisibleID()
            if (end >= this.state.items.length - 2) { this.store.loadMore() }
          })
      }.onRefreshing(() => this.store.refresh())
      if (this.state.items.length === 0) {
        Column({ space: 12 }) {
          if (this.state.loading) {
            LoadingProgress().width(28).height(28).color(Color.White)
          } else {
            Text(this.state.error || $r('app.string.app_empty')).fontSize(15).fontColor('#B3FFFFFF')
              .maxLines(3).textAlign(TextAlign.Center)
            Button(this.state.error.length > 0 ? $r('app.string.app_retry') : $r('app.string.app_refresh'))
              .height(44).backgroundColor('#20232C').onClick(() => this.store.retry())
          }
        }.padding(24).backgroundColor(this.state.items.length > 0 ? '#CC101116' : Color.Transparent)
          .borderRadius(12)
      }

    }.width('100%').height('100%').backgroundColor('#0F121A')
      .onAreaChange((old: Area, area: Area) => this.containerWidth = area.width as number)
  }
}
