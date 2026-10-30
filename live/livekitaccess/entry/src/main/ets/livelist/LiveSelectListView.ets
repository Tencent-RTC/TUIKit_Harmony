import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveListPalette } from './LiveListSupport'
import { LiveSelectListItemView } from './LiveSelectListItemView'
import { LiveSelectListStore, State as ListState } from './LiveSelectListStore'

@Component
export struct LiveSelectListView {
  @Prop @Watch('reload') reloadToken: number = 0
  onSelect?: (liveInfo: LiveInfo) => void
  @State private liveList: LiveInfo[] = []
  @State private isRefreshing: boolean = false
  @State private statusText: string = ''
  private readonly store: LiveSelectListStore = new LiveSelectListStore()

  aboutToAppear(): void {
    this.store.onStateChanged = (state: ListState) => {
      if (!state.isLoading) {
        this.liveList = state.liveList
        this.isRefreshing = false
      }
      this.statusText = state.errorMessage ?? (state.isLoading ? '加载中…' : '暂无直播')
    }
  }

  reload(): void {
    this.store.refresh()
  }

  build() {
    Stack() {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Grid() {
          ForEach(this.liveList, (liveInfo: LiveInfo) => {
            GridItem() {
              LiveSelectListItemView({ liveInfo: liveInfo })
                .onClick(() => this.onSelect?.(liveInfo))
            }
          }, (liveInfo: LiveInfo) => liveInfo.liveID)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(12)
        .padding(12)
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .onScrollIndex((start: number, end: number) => {
          if (end >= this.liveList.length - 2) {
            this.store.loadMore()
          }
        })
      }
      .onRefreshing(() => this.store.refresh())
      if (this.liveList.length === 0) {
        Text(this.statusText)
          .fontColor(LiveListPalette.secondaryText)
          .textAlign(TextAlign.Center)
          .padding({ left: 24, right: 24 })
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(LiveListPalette.background)
  }
}
