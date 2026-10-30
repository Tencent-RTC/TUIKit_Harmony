import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveListView } from 'tuilivekit'
import { LiveSelectListStore, State as ListState } from './livelist/LiveSelectListStore'

@Component
export struct PlayerViewController {
  liveID: string = ''
  @State private liveList: LiveInfo[] = []
  private readonly listStore: LiveSelectListStore = new LiveSelectListStore()

  aboutToAppear(): void {
    this.listStore.onStateChanged = (state: ListState) => this.liveList = state.liveList
    this.listStore.refresh()
  }

  build() {
    LiveListView({ liveID: this.liveID, liveList: this.liveList, onLoadMore: () => this.listStore.loadMore() })
  }
}
