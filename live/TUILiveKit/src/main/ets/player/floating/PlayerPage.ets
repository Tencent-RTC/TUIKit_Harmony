import { ApplicationStateChangeCallback, common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LiveInfo, LiveListStore, LoginStore } from '@tencentcloud/atomicxcore'
import { LiveKitErrorText } from '../../common/LiveKitErrorText'
import { LiveScreenAwake } from '../../common/LiveKitResources'
import { LiveKitLog } from '../../common/log/LiveKitLog'
import { LiveTheme } from '../../common/theme/LiveTheme'
import { LiveToast } from '../../common/theme/LiveToastView'
import { LiveListView } from '../../livelist/LiveListView'
import { FloatingPlayerManager, PlayerPageRoute } from './FloatingPlayerManager'

@Component
export struct PlayerPage {
  @Prop @Watch('onRouteChanged') route: PlayerPageRoute = new PlayerPageRoute()
  onLoginRequired?: () => void
  @State private liveList: LiveInfo[] = []
  @State private isContentEnabled: boolean = false
  private readonly screenOwner: string = util.generateRandomUUID(true)
  private readonly store: LiveListStore = LiveListStore.shared()
  private isMounted: boolean = false
  @State private isVisible: boolean = false
  private isAppActive: boolean = true
  private isLoading: boolean = false
  private hasFirstData: boolean = false
  private loadMorePending: boolean = false
  private requestID: number = 0
  private userID: string = ''
  private loginHandled: boolean = false
  private applicationCallback?: ApplicationStateChangeCallback
  private toast?: LiveToast
  private activeRouteID: string = ''
  private activeRestoreID: string = ''

  private onRouteChanged(): void {
    if (!this.isMounted || this.activeRouteID === this.route.pageID) return
    FloatingPlayerManager.releaseUnclaimed(this.activeRestoreID)
    this.initializeRoute()
    this.fetchData(true)
    if (this.isVisible) this.onShown()
  }

  private initializeRoute(): void {
    this.requestID++
    this.isLoading = false
    this.hasFirstData = false
    this.loadMorePending = false
    this.loginHandled = false
    this.toast?.dismiss()
    this.toast = undefined
    this.activeRouteID = this.route.pageID
    this.activeRestoreID = this.route.restoreID
    this.liveList = []
    this.userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    this.isContentEnabled = this.userID.length > 0 && this.route.liveID.length > 0
    if (this.isContentEnabled) this.mergeData(this.store.liveState.liveList.getAllData())
  }

  aboutToAppear(): void {
    this.isMounted = true
    this.initializeRoute()
    const callback: ApplicationStateChangeCallback = {
      onApplicationForeground: () => {
        this.getUIContext().runScopedTask(() => {
          this.isAppActive = true
          if (this.isVisible) this.ensureLoggedIn()
          this.updateScreenAwake()
        })
      },
      onApplicationBackground: () => {
        this.isAppActive = false
        this.updateScreenAwake()
      },
    }
    this.applicationCallback = callback
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    context.getApplicationContext().on('applicationStateChange', callback)
    this.fetchData(true)
  }

  aboutToDisappear(): void {
    this.isMounted = false
    this.isVisible = false
    this.requestID++
    this.loadMorePending = false
    this.updateScreenAwake()
    if (this.applicationCallback !== undefined) {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      context.getApplicationContext().off('applicationStateChange', this.applicationCallback)
      this.applicationCallback = undefined
    }
    this.toast?.dismiss()
    this.toast = undefined
    FloatingPlayerManager.releaseUnclaimed(this.route.restoreID)
  }

  private ensureLoggedIn(): boolean {
    if (!this.isMounted || this.loginHandled) return false
    const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (userID.length > 0 && userID === this.userID) return true
    this.loginHandled = true
    this.isContentEnabled = false
    this.requestID++
    FloatingPlayerManager.releaseUnclaimed(this.route.restoreID)
    FloatingPlayerManager.closePlayerPage(this.route)
    this.onLoginRequired?.()
    return false
  }

  private onShown(): void {
    this.isVisible = true
    if (this.ensureLoggedIn() && this.route.liveID.length === 0) {
      this.isContentEnabled = false
      FloatingPlayerManager.closePlayerPage(this.route)
    }
    this.updateScreenAwake()
  }

  private updateScreenAwake(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    LiveScreenAwake.setEnabled(this.screenOwner,
      this.isMounted && this.isVisible && this.isAppActive && this.isContentEnabled, context)
  }

  private fetchData(refresh: boolean = false): void {
    if (!this.isContentEnabled || !this.ensureLoggedIn()) return
    if (this.isLoading) {
      if (!refresh) this.loadMorePending = true
      return
    }
    const firstPage = refresh || !this.hasFirstData
    const cursor = firstPage ? '' : this.store.liveState.liveListCursor
    if (!firstPage && cursor.length === 0) return
    const oldSize = this.liveList.length
    const request = ++this.requestID
    const uiContext = this.getUIContext()
    this.isLoading = true
    this.store.fetchLiveList(cursor, 6).then(() => {
      uiContext.runScopedTask(() => {
        if (!this.isMounted || request !== this.requestID) return
        this.isLoading = false
        if (!this.ensureLoggedIn()) return
        this.hasFirstData = true
        this.mergeData(this.store.liveState.liveList.getAllData())
        const nextCursor = this.store.liveState.liveListCursor
        const cursorAdvanced = nextCursor.length > 0 && nextCursor !== cursor
        const duplicatePage = !firstPage && this.liveList.length === oldSize
        if (cursorAdvanced && (this.loadMorePending || duplicatePage)) {
          this.loadMorePending = false
          this.fetchData()
        } else {
          this.loadMorePending = false
        }
      })
    }).catch((error: Error) => {
      uiContext.runScopedTask(() => {
        if (!this.isMounted || request !== this.requestID) return
        this.isLoading = false
        this.loadMorePending = false
        if (!this.ensureLoggedIn()) return
        LiveKitLog.error(`[PlayerPage] fetchLiveList: ${LiveKitErrorText.message(error)}`)
        if (this.isVisible) {
          this.toast?.dismiss()
          this.toast = LiveToast.show(LiveKitErrorText.message(error))
        }
      })
    })
  }

  private mergeData(list: LiveInfo[]): void {
    const merged = this.liveList.slice()
    list.forEach((info: LiveInfo) => {
      if (info.liveID.length === 0) return
      const index = merged.findIndex((item: LiveInfo) => item.liveID === info.liveID)
      if (index < 0) merged.push(info)
      else merged[index] = info
    })
    this.liveList = merged
  }

  build() {
    NavDestination() {
      if (this.isContentEnabled) {
        ForEach([this.route], (route: PlayerPageRoute) => {
          LiveListView({
            liveID: route.liveID,
            autoEnterRoom: route.autoEnterRoom,
            floatingRestoreID: route.restoreID,
            isPageActive: this.isVisible,
            canEnterFloating: () => this.isVisible && FloatingPlayerManager.isPageCurrent(route),
            liveList: this.liveList,
            onLoadMore: () => this.fetchData(),
            onClose: () => FloatingPlayerManager.closePlayerPage(route),
          })
        }, (route: PlayerPageRoute) => route.pageID)
      }
    }
    .hideTitleBar(true)
    .backgroundColor(LiveTheme.Color.canvasBackground)
    .onShown(() => this.onShown())
    .onHidden(() => {
      this.isVisible = false
      this.updateScreenAwake()
      this.toast?.dismiss()
    })
    .onBackPressed(() => {
      FloatingPlayerManager.closePlayerPage(this.route)
      return true
    })
  }
}
