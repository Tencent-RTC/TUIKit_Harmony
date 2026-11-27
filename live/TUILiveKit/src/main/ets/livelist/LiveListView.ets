import { LiveInfo } from '@tencentcloud/atomicxcore'
import { PagerView } from './viewpager/PagerView'

@Component
export struct LiveListView {
  liveID: string = ''
  autoEnterRoom: boolean = false
  floatingRestoreID: string = ''
  @Prop isPageActive: boolean = true
  canEnterFloating?: () => boolean
  @Prop liveList: LiveInfo[] = []
  onLoadMore?: () => void
  onClose?: () => void

  build() {
    PagerView({ initialLiveID: this.liveID, autoEnterRoom: this.autoEnterRoom, floatingRestoreID: this.floatingRestoreID,
      isPageActive: this.isPageActive, canEnterFloating: () => this.canEnterFloating?.() ?? true,
      liveList: this.liveList, onLoadMore: () => this.onLoadMore?.(), onClose: () => this.onClose?.() })
  }
}
