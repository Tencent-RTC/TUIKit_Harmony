import {
  CoGuestLayoutTemplate,
  CoGuestStore,
  DeviceControlPolicy,
  DeviceStatus,
  LiveSeatStore,
  LiveUserInfo,
  LoginStore,
  Role,
  SeatInfo,
  SeatUserInfo,
} from '@tencentcloud/atomicxcore'
import { LiveKitErrorText } from '../../../common/LiveKitErrorText'
import { LiveKitDataObserver, LiveKitResources } from '../../../common/LiveKitResources'
import { LiveKitLog } from '../../../common/log/LiveKitLog'

export const allLayouts: CoGuestLayoutTemplate[] = [
  CoGuestLayoutTemplate.floatLayout, CoGuestLayoutTemplate.dynamicLayout,
  CoGuestLayoutTemplate.columnLayout, CoGuestLayoutTemplate.gridLayout
]

const layoutTitleKeys: string[] =
  ['tuilivekit.pusher.coguest.layout.floating', 'tuilivekit.pusher.coguest.layout.grid2',
    'tuilivekit.pusher.coguest.layout.fixed', 'tuilivekit.pusher.coguest.layout.grid9']
const layoutAssetNames: string[] = ['livekit_coguest_layout_floating', 'livekit_coguest_layout_grid2',
  'livekit_coguest_layout_fixed', 'livekit_coguest_layout_grid9']
const layoutGuestCapacities: number[] = [6, 8, 6, 8]

export class LayoutInfo {
  static title(layout: CoGuestLayoutTemplate): string {
    return LiveKitResources.localizedString(layoutTitleKeys[LayoutInfo.index(layout)] ?? '')
  }

  static assetName(layout: CoGuestLayoutTemplate): string {
    return layoutAssetNames[LayoutInfo.index(layout)] ?? ''
  }

  private static index(layout: CoGuestLayoutTemplate): number {
    return allLayouts.findIndex((item: CoGuestLayoutTemplate) => item.templateId === layout.templateId)
  }

  static guestCapacity(layout: CoGuestLayoutTemplate): number {
    return layoutGuestCapacities[LayoutInfo.index(layout)] ?? 0
  }

  static showsEmptySeats(layout: CoGuestLayoutTemplate): boolean {
    return layout.templateId === CoGuestLayoutTemplate.columnLayout.templateId ||
      layout.templateId === CoGuestLayoutTemplate.gridLayout.templateId
  }
}

export interface PusherCoGuestActionHandling {
  selectLayout(layout: CoGuestLayoutTemplate): void

  acceptApplication(userID: string): void

  invite(userID: string): void

  cancelInvitation(userID: string): void

  disconnect(userID: string): void

  endAllConnections(): void

  markApplicantsSeen(): void

  toggleRemoteMicrophone(userID: string): void
}

export class User {
  userID: string
  userName: string
  avatarURL: string
  microphoneStatus: DeviceStatus = DeviceStatus.off
  allowOpenMicrophone: boolean = true
  cameraStatus: DeviceStatus = DeviceStatus.off
  allowOpenCamera: boolean = true

  constructor(user: LiveUserInfo | SeatUserInfo, seatUser?: SeatUserInfo) {
    this.userID = user.userID
    this.userName = user.userName.length === 0 ? user.userID : user.userName
    this.avatarURL = user.avatarURL
    const deviceUser = seatUser ?? (user instanceof SeatUserInfo ? user : undefined)
    if (deviceUser !== undefined) {
      this.merge(deviceUser)
    }
  }

  equals(other: User): boolean {
    return this.userID === other.userID && this.userName === other.userName && this.avatarURL === other.avatarURL &&
      this.microphoneStatus === other.microphoneStatus && this.allowOpenMicrophone === other.allowOpenMicrophone &&
      this.cameraStatus === other.cameraStatus && this.allowOpenCamera === other.allowOpenCamera
  }

  copy(): User {
    const info = new LiveUserInfo()
    info.userID = this.userID
    info.userName = this.userName
    info.avatarURL = this.avatarURL
    const user = new User(info)
    user.microphoneStatus = this.microphoneStatus
    user.allowOpenMicrophone = this.allowOpenMicrophone
    user.cameraStatus = this.cameraStatus
    user.allowOpenCamera = this.allowOpenCamera
    return user
  }

  merge(seatUser: SeatUserInfo): User {
    this.microphoneStatus = seatUser.microphoneStatus
    this.allowOpenMicrophone = seatUser.allowOpenMicrophone
    this.cameraStatus = seatUser.cameraStatus
    this.allowOpenCamera = seatUser.allowOpenCamera
    return this
  }
}

export class State {
  layout: CoGuestLayoutTemplate = CoGuestLayoutTemplate.dynamicLayout
  connected: User[] = []
  applicants: User[] = []
  candidates: User[] = []
  invitees: User[] = []
  pendingUserIDs: string[] = []
  isUpdatingLayout: boolean = false
  hasUnreadApplicant: boolean = false

  get isFull(): boolean {
    return this.connected.length >= LayoutInfo.guestCapacity(this.layout)
  }

  equals(other: State): boolean {
    return this.layout.templateId === other.layout.templateId && this.isUpdatingLayout === other.isUpdatingLayout &&
      this.hasUnreadApplicant === other.hasUnreadApplicant &&
      this.sameUsers(this.connected, other.connected) && this.sameUsers(this.applicants, other.applicants) &&
      this.sameUsers(this.candidates, other.candidates) && this.sameUsers(this.invitees, other.invitees) &&
      this.pendingUserIDs.length === other.pendingUserIDs.length &&
      this.pendingUserIDs.every((id: string, index: number) => id === other.pendingUserIDs[index])
  }

  private sameUsers(users: User[], other: User[]): boolean {
    return users.length === other.length && users.every((user: User, index: number) => user.equals(other[index]))
  }

  copy(): State {
    const state = new State()
    state.layout = this.layout
    state.connected = this.connected.map((user: User) => user.copy())
    state.applicants = this.applicants.map((user: User) => user.copy())
    state.candidates = this.candidates.map((user: User) => user.copy())
    state.invitees = this.invitees.map((user: User) => user.copy())
    state.pendingUserIDs = this.pendingUserIDs.slice()
    state.isUpdatingLayout = this.isUpdatingLayout
    state.hasUnreadApplicant = this.hasUnreadApplicant
    return state
  }
}

function unique(users: User[]): User[] {
  const seen = new Set<string>()
  return users.filter((user: User) => {
    if (user.userID.length === 0 || seen.has(user.userID)) {
      return false
    }
    seen.add(user.userID)
    return true
  })
}

export class PusherCoGuestStore implements PusherCoGuestActionHandling {
  onToast?: (message: string) => void
  private stateChanged?: (state: State) => void
  state: State = new State()
  private readonly liveID: string
  private readonly sdkStore: CoGuestStore
  private readonly seatStore: LiveSeatStore
  private unobservers: (() => void)[] = []
  private sessionID: number = 0
  private isActive: boolean = false
  private isConnected: boolean = false
  private layoutOperationID: number = 0
  private pendingDesiredLayout?: CoGuestLayoutTemplate = CoGuestLayoutTemplate.dynamicLayout
  private seenApplicantIDs: Set<string> = new Set()
  private seatUsers: Map<string, SeatUserInfo> = new Map()

  constructor(liveID: string, seatStore: LiveSeatStore) {
    this.liveID = liveID
    this.seatStore = seatStore
    this.sdkStore = CoGuestStore.create(liveID)
  }

  set onStateChanged(callback: ((state: State) => void) | undefined) {
    this.stateChanged = callback
    callback?.(this.state)
  }

  get onStateChanged(): ((state: State) => void) | undefined {
    return this.stateChanged
  }

  activate(): void {
    if (this.isActive) {
      return
    }
    this.isActive = true
    this.pendingDesiredLayout = this.state.layout
    const sessionID = this.sessionID
    const applySDK = () => {
      if (this.isActive && this.sessionID === sessionID) {
        this.applyCoGuestState()
      }
    }
    const coGuestState = this.sdkStore.coGuestState
    this.unobservers = [LiveKitDataObserver.observe(coGuestState.connected, applySDK),
    LiveKitDataObserver.observe(coGuestState.applicants, applySDK),
    LiveKitDataObserver.observe(coGuestState.invitees, applySDK),
    LiveKitDataObserver.observe(coGuestState.candidates, applySDK)]
    this.unobservers.push(LiveKitDataObserver.observe(this.seatStore.liveSeatState.seatList, () => {
      if (this.isActive && this.sessionID === sessionID) {
        this.applySeatState()
      }
    }))
    this.applySeatState()
    this.applyCoGuestState()
  }

  deactivate(): void {
    this.sessionID++
    this.isActive = false
    this.isConnected = false
    this.layoutOperationID++
    this.pendingDesiredLayout = undefined
    this.unobservers.forEach((unobserve: () => void) => unobserve())
    this.unobservers = []
    const layout = this.state.layout
    this.state = new State()
    this.state.layout = layout
    this.seenApplicantIDs.clear()
    this.seatUsers.clear()
    this.notify()
  }

  markApplicantsSeen(): void {
    this.seenApplicantIDs = new Set(this.state.applicants.map((user: User) => user.userID))
    if (!this.state.hasUnreadApplicant) {
      return
    }
    this.state.hasUnreadApplicant = false
    this.notify()
  }

  selectLayout(layout: CoGuestLayoutTemplate): void {
    if (!this.isActive || !allLayouts.some((item: CoGuestLayoutTemplate) => item.templateId === layout.templateId) ||
      layout.templateId === this.state.layout.templateId || this.state.isUpdatingLayout) {
      return
    }
    if (this.state.connected.length > LayoutInfo.guestCapacity(layout)) {
      this.onToast?.(LiveKitResources.localizedString('tuilivekit.pusher.coguest.error.capacity'))
      return
    }
    const previousLayout = this.state.layout
    this.pendingDesiredLayout = layout
    if (this.isConnected) {
      this.updateLayout(layout, previousLayout)
    }
  }

  didConnect(): void {
    if (!this.isActive) {
      return
    }
    this.isConnected = true
    this.synchronizeLayoutIfNeeded()
  }

  synchronizeLayoutIfNeeded(): void {
    const desiredLayout = this.pendingDesiredLayout
    if (!this.isActive || !this.isConnected || this.state.isUpdatingLayout || desiredLayout === undefined) {
      return
    }
    this.updateLayout(desiredLayout, this.state.layout)
  }

  private updateLayout(layout: CoGuestLayoutTemplate, rollbackLayout: CoGuestLayoutTemplate): void {
    const operationID = ++this.layoutOperationID
    this.state.isUpdatingLayout = true
    this.notify()
    this.sdkStore.setLayoutTemplate(layout)
      .then(() => true)
      .catch((error: Error) => {
        if (this.layoutOperationID === operationID) {
          LiveKitLog.error(
            `[PusherCoGuest] set layout failed template=${layout.templateId} code=${LiveKitErrorText.code(
              error)} message=${error.message}`)
          this.onToast?.(this.layoutErrorMessage(LiveKitErrorText.code(error)))
        }
        return false
      })
      .then((isSuccess: boolean) => {
        if (this.layoutOperationID !== operationID) {
          return
        }
        this.state.isUpdatingLayout = false
        this.pendingDesiredLayout = undefined
        this.state.layout = isSuccess ? layout : rollbackLayout
        this.notify()
      })
  }

  private layoutErrorMessage(code: number): string {
    let key = 'layout_failed'
    if ([-5, 7008, 9506, 100012].includes(code)) {
      key = 'layout_too_frequent'
    } else if (code === -2) {
      key = 'layout_unavailable'
    } else if (code === -3 || code === 6013) {
      key = 'layout_not_ready'
    } else if (code === -4) {
      key = 'layout_unsupported'
    } else if (code === -7) {
      key = 'layout_room_unsupported'
    } else if (code === 6014) {
      key = 'layout_login_required'
    } else if (code === 9508 || code === 9512 || (code >= 9523 && code <= 9525)) {
      key = 'layout_network'
    } else if (code === 9510 || (code >= 9518 && code <= 9521)) {
      key = 'layout_timeout'
    } else if (code === 100004) {
      key = 'layout_room_missing'
    } else if (code === 100006) {
      key = 'layout_permission_denied'
    }
    return LiveKitResources.localizedString(`tuilivekit.pusher.coguest.error.${key}`)
  }

  acceptApplication(userID: string): void {
    if (this.state.isFull) {
      this.showCapacityError()
      return
    }
    this.perform(userID, () => this.sdkStore.acceptApplication(userID))
  }

  invite(userID: string): void {
    if (this.state.isFull) {
      this.showCapacityError()
      return
    }
    this.perform(userID, () => this.sdkStore.inviteToSeat(userID, -1, 30, ''))
  }

  cancelInvitation(userID: string): void {
    this.perform(userID, () => this.sdkStore.cancelInvitation(userID))
  }

  disconnect(userID: string): void {
    this.perform(userID, () => this.seatStore.kickUserOutOfSeat(userID))
  }

  toggleRemoteMicrophone(userID: string): void {
    const connectedUser = this.state.connected.find((user: User) => user.userID === userID)
    const user = this.seatStore.liveSeatState.seatList.getAllData()
      .find((seat: SeatInfo) => seat.userInfo.userID === userID)?.userInfo
    if (!this.isActive || this.state.pendingUserIDs.includes(userID) || connectedUser === undefined ||
      user === undefined) {
      return
    }
    if (user.allowOpenMicrophone && user.microphoneStatus !== DeviceStatus.on) {
      this.onToast?.(LiveKitResources.localizedString('tuilivekit.pusher.coguest.microphone_manual_open'))
      return
    }
    const toastName = this.microphoneToastName(connectedUser)
    const successMessage = user.allowOpenMicrophone ?
      LiveKitResources.localizedFormat('tuilivekit.pusher.coguest.microphone_closed', toastName) :
      LiveKitResources.localizedFormat('tuilivekit.pusher.coguest.microphone_unlocked', toastName)
    this.perform(userID, () => user.allowOpenMicrophone ? this.seatStore.closeRemoteMicrophone(userID) :
      this.seatStore.openRemoteMicrophone(userID, DeviceControlPolicy.UNLOCK_ONLY), successMessage)
  }

  private microphoneToastName(user: User): string {
    const normalizedName = user.userName.split(/\s+/).filter((part: string) => part.length > 0).join(' ')
    const name = normalizedName.length === 0 ? user.userID : normalizedName
    const characters = Array.from(name)
    return characters.length <= 8 ? name : characters.slice(0, 8).join('') + '…'
  }

  endAllConnections(): void {
    this.state.connected.forEach((user: User) => this.disconnect(user.userID))
  }

  private perform(userID: string, action: () => Promise<void>, successMessage?: string): void {
    if (!this.isActive || userID.length === 0 || this.state.pendingUserIDs.includes(userID)) {
      return
    }
    this.state.pendingUserIDs = this.state.pendingUserIDs.concat([userID])
    this.notify()
    const sessionID = this.sessionID
    action().then(() => true).catch((error: Error) => {
      if (this.isActive && this.sessionID === sessionID) {
        this.onToast?.(LiveKitErrorText.message(error))
      }
      return false
    }).then((isSuccess: boolean) => {
      if (!this.isActive || this.sessionID !== sessionID) {
        return
      }
      this.state.pendingUserIDs = this.state.pendingUserIDs.filter((id: string) => id !== userID)
      this.notify()
      if (isSuccess && successMessage !== undefined) {
        this.onToast?.(successMessage)
      }
    })
  }

  private applyCoGuestState(): void {
    const sdkState = this.sdkStore.coGuestState
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    const connected =
      unique(sdkState.connected.getAllData().filter((user: SeatUserInfo) => user.userID !== loginUserID &&
        (user.liveID.length === 0 || user.liveID === this.liveID) && user.role !== Role.OWNER)
        .map((user: SeatUserInfo) => new User(user, this.seatUsers.get(user.userID))))
    const connectedIDs = new Set(connected.map((user: User) => user.userID))
    const notSelf = (user: User) => !connectedIDs.has(user.userID) && user.userID !== loginUserID
    const applicants =
      unique(sdkState.applicants.getAllData().map((user: LiveUserInfo) => new User(user))).filter(notSelf)
    const applicantIDs = new Set(applicants.map((user: User) => user.userID))
    const invitees = unique(sdkState.invitees.getAllData().map((user: LiveUserInfo) => new User(user))).filter(notSelf)
    const inviteeIDs = new Set(invitees.map((user: User) => user.userID))
    const candidates = unique(sdkState.candidates.getAllData().map((user: LiveUserInfo) => new User(user)))
      .filter((user: User) => notSelf(user) && !applicantIDs.has(user.userID) && !inviteeIDs.has(user.userID))
    this.state.connected = connected
    this.state.applicants = applicants
    this.state.invitees = invitees
    this.state.candidates = candidates
    this.seenApplicantIDs = new Set(Array.from(this.seenApplicantIDs).filter((id: string) => applicantIDs.has(id)))
    this.state.hasUnreadApplicant = applicants.some((user: User) => !this.seenApplicantIDs.has(user.userID))
    this.notify()
  }

  private applySeatState(): void {
    this.seatUsers.clear()
    this.seatStore.liveSeatState.seatList.getAllData()
      .forEach((seat: SeatInfo) => {
        if (seat.userInfo.userID.length > 0) {
          this.seatUsers.set(seat.userInfo.userID, seat.userInfo)
        }
      })
    this.state.connected = this.state.connected.map((user: User) => {
      const seatUser = this.seatUsers.get(user.userID)
      return seatUser === undefined ? user : user.merge(seatUser)
    })
    this.notify()
  }

  private showCapacityError(): void {
    this.onToast?.(LiveKitResources.localizedFormat('tuilivekit.pusher.coguest.error.max_capacity',
      LayoutInfo.guestCapacity(this.state.layout)))
  }

  private notify(): void {
    this.stateChanged?.(this.state)
  }
}
