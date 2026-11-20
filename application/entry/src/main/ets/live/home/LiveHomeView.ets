import { LiveInfo } from '@tencentcloud/atomicxcore'
import { LiveHomeListStore, LiveHomeListState } from './LiveHomeListStore'
import { LiveHomeListView } from './LiveHomeListView'
import { LiveHomePreviewView } from './LiveHomePreviewView'
import { LiveHomeHeaderView } from './LiveHomeHeaderView'
import { LiveHomeRoomTransition } from './LiveHomeRoomTransition'

@Component
export struct LiveHomeView {
  @Prop @Watch('activityChanged') active: boolean = false
  onFullscreen: (fullscreen: boolean) => void = () => {}
  onJoining: (joining: boolean) => void = () => {}
  onStart: () => void = () => {}
  onBackReady: (handler: (() => boolean) | undefined) => void = () => {}
  @State private backToken: number = 0
  @StorageProp('app.active') @Watch('activityChanged') private appActive: boolean = true
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0
  private store: LiveHomeListStore = new LiveHomeListStore()
  private directStore: LiveHomeListStore = new LiveHomeListStore()
  @State private state: LiveHomeListState = new LiveHomeListState()
  @State private directState: LiveHomeListState = new LiveHomeListState()
  @State private preview: boolean = false
  @State private previewVisited: boolean = false
  @State private roomPresented: boolean = false
  @State private joining: boolean = false
  @State private directID: string = ''
  @State private canvasHeight: number = 1
  @State private canvasWidth: number = 1
  @State private sourceX: number = 0
  @State private sourceY: number = 0
  @State private sourceWidth: number = 1
  @State private sourceHeight: number = 1
  @State private transitionCover: string = ''
  @State private transitionInfo: LiveInfo = new LiveInfo()
  @State private transitioning: boolean = false
  @State private playerVisible: boolean = true
  @State private closing: boolean = false
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    this.onBackReady(() => {
      if (this.directID.length > 0) { this.closeDirect(); return true }
      if (this.joining) { return true }
      if (this.roomPresented) { this.backToken++; return true }
      return false
    })
    this.store.onChanged = (state: LiveHomeListState) => this.state = state
    this.activityChanged()
  }

  aboutToDisappear(): void {
    this.alive = false
    this.onBackReady(undefined)
    this.store.setActive(false)
    this.store.onChanged = undefined
    this.directStore.setActive(false)
    this.directStore.onChanged = undefined
  }

  private activityChanged(): void {
    if (!this.alive) { return }
    this.store.setActive(this.active && this.appActive && this.directID.length === 0)
    this.directStore.setActive(this.active && this.appActive && this.directID.length > 0)
    if (this.active && this.appActive && !this.state.loaded && !this.state.loading && this.directID.length === 0) {
      this.store.refresh()
    }
  }

  private setJoining(value: boolean): void {
    if (!this.alive) { return }
    this.joining = value
    this.onJoining(value)
  }

  private open(info: LiveInfo, area: Area): void {
    if (!this.alive || this.joining || this.directID.length > 0 || !this.active) { return }
    this.directStore = this.store.independentCopy()
    this.directState = this.directStore.state
    this.directStore.onChanged = (state: LiveHomeListState) => this.directState = state
    this.sourceX = area.globalPosition.x as number
    this.sourceY = area.globalPosition.y as number
    this.sourceWidth = area.width as number
    this.sourceHeight = area.height as number
    this.transitionCover = info.coverURL
    this.transitionInfo = info
    this.transitioning = this.sourceWidth > 0 && this.sourceHeight > 0
    this.playerVisible = !this.transitioning
    this.closing = false
    this.directID = info.liveID
    this.onFullscreen(true)
    this.activityChanged()
  }

  private closeDirect(): void {
    if (!this.alive || this.closing) { return }
    this.closing = true
    this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut, onFinish: () => {
      if (!this.alive) { return }
      this.directStore.setActive(false)
      this.directStore.onChanged = undefined
      this.directID = ''
      this.closing = false
      this.transitioning = false
      this.onFullscreen(false)
      this.activityChanged()
    } }, () => this.playerVisible = false)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        LiveHomeListView({ store: this.store, state: this.state,
          onSelect: (info: LiveInfo, area: Area) => this.open(info, area) }).enabled(!this.joining).layoutWeight(1)
      }.width('100%').height('100%').padding({ top: this.safeTop + 56, bottom: 56 + this.safeBottom })
        .visibility(this.preview ? Visibility.Hidden : Visibility.Visible)
      if (this.previewVisited) {
        LiveHomePreviewView({ store: this.store, state: this.state, active: this.active && this.preview && this.directID.length === 0,
          canvasHeight: this.canvasHeight, backToken: this.backToken, bottomInset: 56 + this.safeBottom,
          onRoomChanged: (fullscreen: boolean) => {
            this.roomPresented = fullscreen
            this.onFullscreen(fullscreen)
          }, onJoining: (joining: boolean) => this.setJoining(joining),
          onClose: () => { this.roomPresented = false; this.onFullscreen(false) } })
          .visibility(this.preview ? Visibility.Visible : Visibility.Hidden)
      }
      if (!this.roomPresented && this.directID.length === 0) {
        LiveHomeHeaderView({ preview: this.preview, onMode: (preview: boolean) => {
          if (!this.joining) {
            this.previewVisited = this.previewVisited || preview
            this.preview = preview
          }
        }, onStart: () => { if (this.alive && !this.joining) { this.onStart() } } }).margin({ top: this.safeTop })
          .enabled(!this.joining)
      }
      if (this.directID.length > 0) {
        LiveHomePreviewView({ store: this.directStore, state: this.directState, active: this.active && !this.closing,
          canvasHeight: this.canvasHeight, initialLiveID: this.directID, direct: true,
          onJoining: (joining: boolean) => this.setJoining(joining), onClose: () => this.closeDirect() })
          .opacity(this.playerVisible ? 1 : 0).backgroundColor(Color.Black)
        if (this.transitioning && !this.closing) {
          LiveHomeRoomTransition({ coverURL: this.transitionCover, info: this.transitionInfo, canvasWidth: this.canvasWidth,
            canvasHeight: this.canvasHeight, sourceX: this.sourceX, sourceY: this.sourceY,
            sourceWidth: this.sourceWidth, sourceHeight: this.sourceHeight,
            onReady: () => this.playerVisible = true, onFinish: () => this.transitioning = false })
        }
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.app_live_background'))
      .onAreaChange((old: Area, area: Area) => {
        this.canvasHeight = area.height as number
        this.canvasWidth = area.width as number
      })
  }
}
