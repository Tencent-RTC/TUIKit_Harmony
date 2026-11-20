import { LoginState, LoginStore, UserProfile } from '@tencentcloud/atomicxcore'
import { promptAction } from '@kit.ArkUI'
import { MineView } from './MineView'
import { MineSettingsView } from './settings/MineSettingsView'
import { AvatarSelectorView } from './settings/AvatarSelectorView'
import { ProfileUpdateInfoView } from './settings/ProfileUpdateInfoView'
import { LogUploadView } from './log/LogUploadView'

@Component
export struct MineViewController {
  onLogout: () => void = () => {}
  onPageStyle: (style: number) => void = () => {}
  onBackReady: (handler: (() => boolean) | undefined) => void = () => {}
  @Prop @Watch('activityChanged') active: boolean = true
  @State private loginState: LoginState = LoginStore.shared().state as LoginState
  @State private saving: boolean = false
  @State private editorPresented: boolean = false
  @State private logsPresented: boolean = false
  @StorageProp('tuilivekit.safeArea.top') private safeTop: number = 0
  @StorageProp('app.windowHeight') private windowHeight: number = 0
  private stack: NavPathStack = new NavPathStack()
  private generation: number = 0
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    this.publishStyle()
    this.onBackReady(() => {
      if (this.logsPresented) { this.logsPresented = false; return true }
      if (this.editorPresented) { this.editorPresented = false; return true }
      if (this.stack.size() > 0) { this.back(); return true }
      return false
    })
  }
  aboutToDisappear(): void { this.alive = false; this.generation++; this.onBackReady(undefined) }
  private activityChanged(): void {
    if (!this.active) { this.generation++; this.saving = false } else { this.publishStyle() }
  }
  private back(): void {
    this.generation++
    this.saving = false
    this.stack.pop()
    this.publishStyle()
  }

  private publishStyle(): void {
    if (!this.alive || !this.active) { return }
    const names = this.stack.getAllPathName()
    const name = names[names.length - 1]
    this.onPageStyle(name === 'settings' ? 1 : name === 'avatar' ? 2 : 0)
  }

  private async update(nickname?: string, avatarURL?: string): Promise<void> {
    const userID = this.loginState.loginUserInfo?.userID ?? ''
    if (this.saving || userID.length === 0) { return }
    const request = ++this.generation
    this.saving = true
    const profile = new UserProfile()
    profile.userID = userID
    if (nickname !== undefined) { profile.nickname = nickname }
    if (avatarURL !== undefined) { profile.avatarURL = avatarURL }
    try {
      await LoginStore.shared().setSelfInfo(profile)
      if (!this.alive || !this.active || request !== this.generation) { return }
      this.saving = false
      if (avatarURL !== undefined) { this.stack.pop() } else { this.editorPresented = false }
    } catch (error) {
      if (!this.alive || !this.active || request !== this.generation) { return }
      this.saving = false
      promptAction.showToast({ message: (error as Error).message })
    }
  }

  @Builder logs() { LogUploadView({ onClose: () => this.logsPresented = false }) }

  @Builder editor() {
    ProfileUpdateInfoView({ initialName: this.loginState.loginUserInfo?.nickname ?? '', saving: this.saving,
      onSave: (name: string) => this.update(name) })
  }

  @Builder destination(name: string, parameter: Object) {
    NavDestination() {
      if (name === 'settings') {
        MineSettingsView({ nickname: this.loginState.loginUserInfo?.nickname ?? '',
          avatarURL: this.loginState.loginUserInfo?.avatarURL ?? '', onBack: () => this.back(),
          onAvatar: () => this.stack.pushPath({ name: 'avatar' }),
          onNickname: () => this.editorPresented = true })
      } else {
        AvatarSelectorView({ currentURL: this.loginState.loginUserInfo?.avatarURL ?? '', saving: this.saving,
          onBack: () => this.back(), onSave: (url: string) => this.update(undefined, url) })
      }
    }.hideTitleBar(true).padding({ top: this.safeTop })
      .backgroundColor(name === 'settings' ? Color.White : $r('app.color.app_grouped_background'))
      .onShown(() => this.publishStyle()).onHidden(() => this.publishStyle()).onBackPressed(() => { this.back(); return true })
  }

  build() {
    Stack() {
      Navigation(this.stack) {
        MineView({ nickname: this.loginState.loginUserInfo?.nickname ?? '',
          userID: this.loginState.loginUserInfo?.userID ?? '', avatarURL: this.loginState.loginUserInfo?.avatarURL ?? '',
          onLogout: () => { if (this.alive && this.active) { this.onLogout() } }, onSettings: () => this.stack.pushPath({ name: 'settings' }), onLogs: () => this.logsPresented = true })
      }.hideTitleBar(true).mode(NavigationMode.Stack).navDestination(this.destination)
        .width('100%').height('100%').backgroundColor($r('app.color.app_background'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .bindSheet($$this.editorPresented, this.editor, { height: 237, showClose: false, dragBar: false,
          onDisappear: () => { this.generation++; this.saving = false } })
    }.width('100%').height('100%')
      .bindSheet($$this.logsPresented, this.logs, { height: this.windowHeight / 2, showClose: false, dragBar: false })
  }
}
