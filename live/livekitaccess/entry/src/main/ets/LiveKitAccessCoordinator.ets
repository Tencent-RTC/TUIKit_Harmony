import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { window } from '@kit.ArkUI'
import { LoginEvent, LoginStore, UserProfile } from '@tencentcloud/atomicxcore'
import { KeyMetrics, LiveKitSafeArea, LiveToast } from 'tuilivekit'
import { GenerateTestUserSig } from './GenerateTestUserSig'
import { LoginViewController } from './LoginViewController'
import { PlayerViewController } from './PlayerViewController'
import { PusherViewController } from './PusherViewController'
import { WaterfallViewController } from './WaterfallViewController'

const cachedUserIDKey: string = 'livekit.access.loginUserID'
const avatarURLs: string[] = [1, 2, 3, 4, 5].map((index: number) =>
`https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar${index}.png`)
const nicknameKeys: string[] = [1, 2, 3, 4, 5].map((index: number) => `livekit_access_user_name_${index}`)
const profileWaitTimeout: number = 5000
const demoLoginSuccess: number = 1302
const demoClickLive: number = 1119

enum Root {
  login,
  liveList,
}

function localized(name: string, ...args: (string | number)[]): string {
  return getContext().resourceManager.getStringByNameSync(name, ...args)
}

function randomElement(values: string[]): string {
  return values[Math.floor(Math.random() * values.length)]
}

@Entry
@Component
struct LiveKitAccessCoordinator {
  @State private root: Root = Root.login
  @State private loginUserID: string = ''
  @State private isLoginLoading: boolean = false
  @State private liveListReloadToken: number = 0
  @Provide('navigationStack') private navigationStack: NavPathStack = new NavPathStack()
  private pusherExitAfterAccountInvalidation?: () => void
  private isPusherVisible: boolean = false
  private unsubscribeLoginEvents?: () => void

  aboutToAppear(): void {
    LiveKitSafeArea.observe()
    this.loginUserID = this.loadUserID()
    this.observeLoginEvents()
    this.showLogin()
  }

  aboutToDisappear(): void {
    this.unsubscribeLoginEvents?.()
  }

  private store(): preferences.Preferences {
    return preferences.getPreferencesSync(getContext(), { name: 'livekit_access' })
  }

  private loadUserID(): string {
    const cached = this.store().getSync(cachedUserIDKey, '') as string
    if (cached.length > 0) {
      return cached
    }
    const generated = `${Math.floor(1000000 + Math.random() * 9000000)}`
    this.saveUserID(generated)
    return generated
  }

  private saveUserID(userID: string): void {
    const store = this.store()
    store.putSync(cachedUserIDKey, userID)
    store.flush()
  }

  private observeLoginEvents(): void {
    this.unsubscribeLoginEvents = LoginStore.shared().loginEventEmitter.subscribe(this, (event: LoginEvent) => {
      if (event === LoginEvent.KICKED_OFFLINE) {
        this.handleAccountKickedOffline()
      } else if (event === LoginEvent.LOGIN_EXPIRED) {
        this.showLogin(localized('livekit_access_login_expired'))
      } else {
        this.showLogin(localized('livekit_access_login_state_changed'))
      }
    })
  }

  private handleAccountKickedOffline(): void {
    const message = localized('livekit_access_login_kicked_offline')
    if (this.isPusherVisible) {
      this.pusherExitAfterAccountInvalidation = () => this.showLogin(message)
    } else {
      this.showLogin(message)
    }
  }

  private login(userID: string): void {
    this.loginUserID = userID
    this.saveUserID(userID)
    GenerateTestUserSig.genTestUserSig(userID).then((userSig: string) => {
      if (GenerateTestUserSig.SDKAPPID <= 0 || userID.length === 0 || userSig.length === 0) {
        LiveToast.show(localized('livekit_access_login_missing_config'))
        return
      }
      this.isLoginLoading = true
      LoginStore.shared().login(GenerateTestUserSig.SDKAPPID, userID, userSig, getContext(this)).then(() => {
        KeyMetrics.reportAtomicMetrics(demoLoginSuccess)
        this.ensureSelfInfo(userID)
      }).catch((error: Error) => {
        this.isLoginLoading = false
        if (this.root === Root.login) {
          LiveToast.show(localized('livekit_access_login_failed', Number(Reflect.get(error, 'code') ?? -1),
            error.message ?? ''))
        }
      })
    })
  }

  private ensureSelfInfo(userID: string): void {
    this.waitForLoginUserInfo((loginUserInfo: UserProfile | undefined) => {
      const nickname = loginUserInfo?.nickname ?? ''
      const avatarURL = loginUserInfo?.avatarURL ?? ''
      if (nickname.length === 0 || avatarURL.length === 0) {
        this.setSelfInfo(userID, nickname.length === 0, avatarURL.length === 0)
      } else {
        this.isLoginLoading = false
        this.showLiveList()
      }
    })
  }

  private waitForLoginUserInfo(completion: (profile: UserProfile | undefined) => void): void {
    const isReady = (profile: UserProfile | undefined): boolean => profile !== undefined && profile.userID.length > 0
    const current = (): UserProfile | undefined => LoginStore.shared().state.loginUserInfo
    if (isReady(current())) {
      completion(current())
      return
    }
    const startTime = Date.now()
    const timer = setInterval(() => {
      if (isReady(current()) || Date.now() - startTime >= profileWaitTimeout) {
        clearInterval(timer)
        completion(current())
      }
    }, 100)
  }

  private setSelfInfo(userID: string, needsNickname: boolean, needsAvatarURL: boolean): void {
    const userProfile = new UserProfile()
    userProfile.userID = userID
    userProfile.nickname = needsNickname ? localized(randomElement(nicknameKeys)) : undefined
    userProfile.avatarURL = needsAvatarURL ? randomElement(avatarURLs) : undefined
    LoginStore.shared().setSelfInfo(userProfile).catch(() => {
    }).finally(() => {
      this.isLoginLoading = false
      this.showLiveList()
    })
  }

  private showLogin(message?: string): void {
    this.navigationStack.clear(false)
    this.isPusherVisible = false
    this.pusherExitAfterAccountInvalidation = undefined
    this.isLoginLoading = false
    this.root = Root.login
    this.updateStatusBar()
    if (message !== undefined) {
      setTimeout(() => LiveToast.show(message), 0)
    }
  }

  private showLiveList(): void {
    KeyMetrics.reportAtomicMetrics(demoClickLive)
    this.navigationStack.clear(false)
    this.root = Root.liveList
    this.updateStatusBar()
  }

  private updateStatusBar(): void {
    window.getLastWindow(getContext(this)).then((target: window.Window) => {
      target.setWindowSystemBarProperties({ statusBarContentColor: this.root === Root.login ? '#000000' : '#FFFFFF' })
    }).catch(() => {
    })
  }

  @Builder
  destination(name: string, liveID: string) {
    NavDestination() {
      if (name === 'player') {
        PlayerViewController({ liveID: liveID })
      } else {
        PusherViewController({
          liveID: liveID,
          onBack: () => this.navigationStack.pop(),
        })
      }
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Black)
    .onShown(() => this.isPusherVisible = name === 'pusher')
    .onHidden(() => {
      if (name === 'pusher') {
        this.isPusherVisible = false
        const onExit = this.pusherExitAfterAccountInvalidation
        this.pusherExitAfterAccountInvalidation = undefined
        if (onExit !== undefined) {
          setTimeout(onExit, 0)
        }
      }
    })
    .onBackPressed(() => {
      if (name !== 'pusher') {
        return false
      }
      const context = getContext(this) as common.UIAbilityContext
      context.eventHub.emit('tuilivekit.pusher.hostBack', liveID)
      return true
    })
  }

  build() {
    Navigation(this.navigationStack) {
      if (this.root === Root.login) {
        LoginViewController({
          initialUserID: this.loginUserID,
          isLoading: this.isLoginLoading,
          onLogin: (userID: string) => this.login(userID),
        })
      } else {
        WaterfallViewController({
          reloadToken: this.liveListReloadToken,
          onPlay: (liveID: string) => this.navigationStack.pushPath({ name: 'player', param: liveID }),
          onPush: (liveID: string) => this.navigationStack.pushPath({ name: 'pusher', param: liveID }),
        })
          .onVisibleAreaChange([0, 1], (isVisible: boolean) => {
            if (isVisible) {
              this.liveListReloadToken++
              this.updateStatusBar()
            }
          })
      }
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.navigationDestination)
    .width('100%')
    .height('100%')
  }

  @Builder
  navigationDestination(name: string, param: Object) {
    this.destination(name, param as string)
  }
}
