import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveHomeListStore, LiveHomeListState } from './LiveHomeListStore'
import { LiveHomeListView } from './LiveHomeListView'
import { LiveHomePreviewView } from './LiveHomePreviewView'
import { LiveHomeHeaderView } from './LiveHomeHeaderView'

@Component
export struct LiveHomeView {
  @Prop @Watch('activityChanged') active: boolean = false
  onEnterPlayerPage: (liveID: string) => void = () => {}
  onStart: () => void = () => {}
  onBackReady: (handler: (() => boolean) | undefined) => void = () => {}
  @StorageProp('app.active') @Watch('activityChanged') private appActive: boolean = true
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0
  private store: LiveHomeListStore = new LiveHomeListStore()
  @State private state: LiveHomeListState = new LiveHomeListState()
  @State private preview: boolean = false
  @State private previewVisited: boolean = false
  @State private previewID: string = ''
  @State private canvasHeight: number = 1
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    this.onBackReady(() => {
      if (this.preview) { this.preview = false; return true }
      return false
    })
    this.store.onChanged = (state: LiveHomeListState) => this.state = state
    if (this.state.items.length > 0) { this.previewID = this.state.items[0].liveID }
    this.activityChanged()
  }

  aboutToDisappear(): void {
    this.alive = false
    this.onBackReady(undefined)
    this.store.setActive(false)
    this.store.onChanged = undefined
  }

  private activityChanged(): void {
    if (!this.alive) { return }
    this.store.setActive(this.active && this.appActive)
    if (this.active && this.appActive && !this.state.loaded && !this.state.loading) { this.store.refresh() }
  }

  private enterPlayerPage(liveID: string): void {
    if (!this.alive || !this.active) { return }
    this.onEnterPlayerPage(liveID)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        LiveHomeListView({ store: this.store, state: this.state,
          onSelect: (info: LiveInfo) => this.enterPlayerPage(info.liveID),
          onFirstVisibleID: (liveID: string) => this.previewID = liveID }).layoutWeight(1)
      }.width('100%').height('100%').padding({ top: this.safeTop + 56, bottom: 56 + this.safeBottom })
        .visibility(this.preview ? Visibility.Hidden : Visibility.Visible)
      if (this.previewVisited) {
        LiveHomePreviewView({ store: this.store, state: this.state, active: this.active && this.preview,
          canvasHeight: this.canvasHeight, bottomInset: 56 + this.safeBottom, initialLiveID: this.previewID,
          onEnterPlayerPage: (liveID: string) => this.enterPlayerPage(liveID) })
          .visibility(this.preview ? Visibility.Visible : Visibility.Hidden)
      }
      LiveHomeHeaderView({ preview: this.preview, onMode: (preview: boolean) => {
        this.previewVisited = this.previewVisited || preview
        if (preview && this.previewID.length === 0 && this.state.items.length > 0) {
          this.previewID = this.state.items[0].liveID
        }
        this.preview = preview
      }, onStart: () => { if (this.alive) { this.onStart() } } }).margin({ top: this.safeTop })
    }.width('100%').height('100%').backgroundColor($r('app.color.app_live_background'))
      .onAreaChange((old: Area, area: Area) => this.canvasHeight = area.height as number)
  }
}
