import { LiveInfo } from '@tencentcloud/atomicxcore'
import { PagerView } from './viewpager/PagerView'

@Component
export struct LiveListView {
  liveID: string = ''
  @Prop liveList: LiveInfo[] = []
  onLoadMore?: () => void

  build() {
    PagerView({ initialLiveID: this.liveID, liveList: this.liveList, onLoadMore: () => this.onLoadMore?.() })
  }
}
