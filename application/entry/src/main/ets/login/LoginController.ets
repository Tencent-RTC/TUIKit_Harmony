import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LoginEvent, LoginStore, UserProfile } from '@tencentcloud/atomicxcore'
import { GenerateTestUserSig } from '../debug/GenerateTestUserSig'

export enum LoginPhase { login, register, home }

export class LoginController {
  userID: string = ''
  automatic: boolean = false
  onInvalidation?: (kicked: boolean) => void
  onChanged?: (phase: LoginPhase, loading: boolean, error: string) => void
  private phase: LoginPhase = LoginPhase.login
  private loading: boolean = false
  private generation: number = 0
  private timer: number = -1
  private unsubscribe?: () => void
  private storage?: preferences.Preferences
  private context?: common.UIAbilityContext

  attach(context: common.UIAbilityContext): void {
    this.context = context
    this.storage = preferences.getPreferencesSync(context, { name: 'app_uikit' })
    this.userID = this.storage.getSync('userID', '') as string
    this.automatic = this.storage.getSync('automatic', false) as boolean
    this.unsubscribe = LoginStore.shared().loginEventEmitter.subscribe(this, (event: LoginEvent) => {
      if (event === LoginEvent.KICKED_OFFLINE || event === LoginEvent.LOGIN_EXPIRED) {
        this.onInvalidation?.(event === LoginEvent.KICKED_OFFLINE)
        this.generation++
        this.stopTimer()
        this.loading = false
        this.phase = LoginPhase.login
        this.publish(context.resourceManager.getStringSync($r('app.string.app_account_invalid').id))
      }
    })
    if (this.automatic && this.userID.length > 0) {
      this.login(this.userID)
    }
  }

  detach(): void {
    this.generation++
    this.stopTimer()
    this.unsubscribe?.()
    this.unsubscribe = undefined
    this.onChanged = undefined
    this.onInvalidation = undefined
  }

  setAutomatic(value: boolean): void {
    this.automatic = value
    this.storage?.putSync('automatic', value)
    this.storage?.flush()
  }

  async login(value: string): Promise<void> {
    const userID = value.trim()
    if (this.loading || this.phase !== LoginPhase.login || userID.length === 0 || this.context === undefined) { return }
    const request = ++this.generation
    this.loading = true
    this.publish()
    try {
      const signature = await GenerateTestUserSig.genTestUserSig(userID)
      if (request !== this.generation) { return }
      if (signature.length === 0) { throw new Error('SDKAppID / UserSig configuration is missing') }
      await LoginStore.shared().login(GenerateTestUserSig.SDKAPPID, userID, signature, this.context)
      if (request !== this.generation) { return }
      this.userID = userID
      this.storage?.putSync('userID', userID)
      this.storage?.flush()
      const deadline = Date.now() + 5000
      this.timer = setInterval(() => {
        if (request !== this.generation) { this.stopTimer(); return }
        const profile = LoginStore.shared().state.loginUserInfo
        if (profile !== undefined && profile.userID === userID) {
          this.stopTimer()
          this.generation++
          this.phase = (profile.nickname ?? '').length > 0 ? LoginPhase.home : LoginPhase.register
          this.loading = false
          this.publish()
        } else if (Date.now() >= deadline) {
          this.stopTimer()
          this.loading = false
          this.publish(this.context?.resourceManager.getStringSync($r('app.string.app_profile_timeout').id) ?? '')
        }
      }, 100)
    } catch (error) {
      if (request !== this.generation) { return }
      this.loading = false
      this.publish((error as Error).message)
    }
  }

  async register(nickname: string): Promise<void> {
    if (this.loading || this.phase !== LoginPhase.register || nickname.trim().length === 0) { return }
    const request = ++this.generation
    this.loading = true
    this.publish()
    const profile = new UserProfile()
    profile.userID = this.userID
    profile.nickname = nickname.trim()
    profile.avatarURL = 'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png'
    try {
      await LoginStore.shared().setSelfInfo(profile)
      if (request !== this.generation) { return }
      this.loading = false
      this.phase = LoginPhase.home
      this.publish()
    } catch (error) {
      if (request !== this.generation) { return }
      this.loading = false
      this.publish((error as Error).message)
    }
  }

  cancelRegistration(): void {
    if (this.phase !== LoginPhase.register) { return }
    this.generation++
    this.loading = false
    this.phase = LoginPhase.login
    this.publish()
  }

  async logout(): Promise<void> {
    if (this.loading || this.phase !== LoginPhase.home) { return }
    const request = ++this.generation
    this.loading = true
    this.publish()
    try {
      await LoginStore.shared().logout()
      if (request !== this.generation) { return }
      this.phase = LoginPhase.login
      this.storage?.deleteSync('userID')
      this.storage?.flush()
      this.userID = ''
      this.loading = false
      this.publish()
    } catch (error) {
      if (request !== this.generation) { return }
      this.loading = false
      this.publish((error as Error).message)
    }
  }

  private publish(error: string = ''): void { this.onChanged?.(this.phase, this.loading, error) }
  private stopTimer(): void { if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1 } }
}
