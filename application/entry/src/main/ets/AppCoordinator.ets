import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { LoginController, LoginPhase } from './login/LoginController'
import { LoginView } from './login/LoginView'
import { RegisterView } from './register/RegisterView'
import { HomeView } from './home/HomeView'
import { LiveHomeView } from './live/home/LiveHomeView'
import { PusherViewController } from './live/PusherViewController'
import { HomeMessagesView } from './chat/HomeMessagesView'
import { MineViewController } from './mine/MineViewController'
import { RoomRootPage } from './room/RoomRootPage'

@Entry
@Component
struct AppCoordinator {
  @State private phase: LoginPhase = LoginPhase.login
  @State private loading: boolean = false
  @State private fullscreen: boolean = false
  @State private liveJoining: boolean = false
  @State private pusherVisible: boolean = false
  @State private pusherLiveID: string = ''
  private deferInvalidation: boolean = false
  @State private selectedTab: number = 1
  @State private profileStyle: number = 0
  private messageBack?: () => boolean
  private mineBack?: () => boolean
  private liveBack?: () => boolean
  private roomBack?: () => boolean
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0
  @StorageProp('tuilivekit.safeArea.bottom') private safeBottom: number = 0
  private controller: LoginController = new LoginController()

  aboutToAppear(): void {
    this.controller.onInvalidation = (kicked: boolean) => this.deferInvalidation = kicked && this.pusherVisible
    this.controller.onChanged = (phase: LoginPhase, loading: boolean, error: string) => {
      if (!(this.deferInvalidation && this.pusherVisible && phase === LoginPhase.login)) {
        if (phase === LoginPhase.home && this.phase !== LoginPhase.home) { this.selectedTab = 1 }
        if (phase !== LoginPhase.home) {
          this.fullscreen = false
          this.pusherVisible = false
          this.liveJoining = false
        }
        this.phase = phase
      }
      this.publishStyle()
      this.loading = loading
      if (error.length > 0) { promptAction.showToast({ message: error }) }
    }
    this.controller.attach(getContext(this) as common.UIAbilityContext)
  }

  aboutToDisappear(): void { this.controller.detach() }

  onBackPress(): boolean {
    if (this.phase === LoginPhase.register) { this.controller.cancelRegistration(); return true }
    if (this.pusherVisible) {
      const context = getContext(this) as common.UIAbilityContext
      context.eventHub.emit('tuilivekit.pusher.hostBack', this.pusherLiveID)
      return true
    }
    if (this.selectedTab === 0 && this.roomBack !== undefined) { return this.roomBack() }
    if (this.selectedTab === 3 && this.messageBack !== undefined) { return this.messageBack() }
    if (this.selectedTab === 4 && this.mineBack !== undefined) { return this.mineBack() }
    if (this.selectedTab === 1 && this.liveBack !== undefined) { return this.liveBack() }
    return this.liveJoining
  }

  private publishStyle(): void {
    const context = getContext(this) as common.UIAbilityContext
    context.eventHub.emit('app.uikit.lightContent', this.phase === LoginPhase.home && this.selectedTab === 1)
  }

  @Builder roomContent(active: boolean) {
    RoomRootPage({ active: active, onFullscreen: (fullscreen: boolean) => this.fullscreen = fullscreen,
      onBackReady: (handler: (() => boolean) | undefined) => this.roomBack = handler })
  }

  @Builder liveContent(active: boolean) {
    LiveHomeView({ active: active && !this.pusherVisible, onFullscreen: (fullscreen: boolean) => this.fullscreen = fullscreen,
      onJoining: (joining: boolean) => this.liveJoining = joining,
      onBackReady: (handler: (() => boolean) | undefined) => this.liveBack = handler,
      onStart: () => {
        if (this.phase !== LoginPhase.home || this.pusherVisible || this.liveJoining) { return }
        this.pusherLiveID = `live_${this.controller.userID}_${Date.now()}`
        this.pusherVisible = true
        this.fullscreen = true
      } })
  }

  @Builder messageContent() {
    HomeMessagesView({ onFullscreen: (fullscreen: boolean) => this.fullscreen = fullscreen,
      onBackReady: (handler: (() => boolean) | undefined) => this.messageBack = handler })
  }

  @Builder mineContent() {
    MineViewController({ onPageStyle: (style: number) => this.profileStyle = style, active: this.selectedTab === 4, onLogout: () => this.controller.logout(),
      onBackReady: (handler: (() => boolean) | undefined) => this.mineBack = handler })
  }

  build() {
    Stack() {
      if (this.phase === LoginPhase.login) {
        LoginView({ initialUserID: this.controller.userID, automatic: this.controller.automatic, loading: this.loading,
          onLogin: (userID: string) => this.controller.login(userID),
          onAutomatic: (value: boolean) => this.controller.setAutomatic(value) })
      } else if (this.phase === LoginPhase.register) {
        RegisterView({ loading: this.loading, onBack: () => this.controller.cancelRegistration(), onRegister: (name: string) => this.controller.register(name) })
      } else {
        HomeView({ fullscreen: $fullscreen, profileStyle: this.profileStyle,
          roomContent: (active: boolean): void => this.roomContent(active),
          liveContent: (active: boolean): void => this.liveContent(active), interactionEnabled: !this.liveJoining,
          messageContent: (): void => this.messageContent(), mineContent: (): void => this.mineContent(), onTab: (index: number) => { this.selectedTab = index; this.publishStyle() } })
        if (this.pusherVisible) {
          PusherViewController({ liveID: this.pusherLiveID, onExit: () => {
            this.pusherVisible = false
            this.fullscreen = false
            if (this.deferInvalidation) {
              this.deferInvalidation = false
              this.phase = LoginPhase.login
            }
          } })
        }
      }
    }.width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .padding({ top: this.phase === LoginPhase.home ? 0 : this.safeTop,
        bottom: this.phase === LoginPhase.home ? 0 : this.safeBottom })
      .backgroundColor(Color.White)
    // Login and registration use the system keyboard avoidance; no local keyboard offset is applied.
  }
}
