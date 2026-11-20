import {
  CoHostStore, CoHostStatus, CoHostLayoutTemplate, CoHostListener, SeatUserInfo,
  V2TIMManager, V2TIMFriendshipListener, V2TIMUserFullInfo, V2TIMFollowTypeCheckResult
} from '@tencentcloud/atomicxcore'
import { LiveKitDataObserver, LiveKitResources } from '../../../common/LiveKitResources'
import { LiveKitErrorText } from '../../../common/LiveKitErrorText'

export class CoHostUser {
  liveID: string = ''
  userID: string = ''
  userName: string = ''
  avatarURL: string = ''
  followType: number = -1
  constructor(info: SeatUserInfo, previous?: CoHostUser) {
    this.liveID = info.liveID
    this.userID = info.userID || previous?.userID || ''
    this.userName = info.userName || previous?.userName || this.userID
    this.avatarURL = info.avatarURL || previous?.avatarURL || ''
  }
}

export class CoHostState {
  candidates: CoHostUser[] = []
  connected: CoHostUser[] = []
  invitees: CoHostUser[] = []
  applicant?: CoHostUser
  applicantDeadline: number = 0
  pendingLiveIDs: string[] = []
  isLoading: boolean = false
  hasMore: boolean = true
  loadError: string = ''
  isConnected: boolean = false
  isExiting: boolean = false
  connectionStartedAt: number = 0
  isBusy(id: string): boolean { return this.isExiting || this.pendingLiveIDs.includes(id) }
  isInvited(id: string): boolean { return this.invitees.some((user: CoHostUser) => user.liveID === id) }
}

export class PusherCoHostStore {
  onStateChanged?: (state: CoHostState) => void
  onToast?: (message: string) => void
  state: CoHostState = new CoHostState()
  private readonly liveID: string
  private readonly sdk: CoHostStore
  private active: boolean = false
  private generation: number = 0
  private sequence: number = 0
  private operations: Map<string, number> = new Map()
  private cancellations: Map<string, CoHostUser> = new Map()
  private followTypes: Map<string, number> = new Map()
  private followRequests: Map<string, number> = new Map()
  private observers: (() => void)[] = []
  private listener?: CoHostListener
  private friendship?: V2TIMFriendshipListener
  private lastPublished: string = ''
  private nextCursor: string = ''
  private candidateRequest: number = 0
  private applicantToken: number = 0
  private responding: boolean = false
  private timeout: number = -1
  private expiredApplicant: string = ''

  constructor(liveID: string) {
    this.liveID = liveID
    this.sdk = CoHostStore.create(liveID)
  }

  activate(): void {
    if (this.active) return
    this.active = true
    const generation = ++this.generation
    const changed = () => { if (this.valid(generation)) this.apply() }
    const state = this.sdk.coHostState
    this.observers = [LiveKitDataObserver.observe(state.connected, changed),
      LiveKitDataObserver.observe(state.invitees, changed), LiveKitDataObserver.observe(state.candidates, changed)]
    const listener = new CoHostListener()
    listener.onCoHostRequestReceived = (info: SeatUserInfo) => {
      if (!this.valid(generation)) return
      this.expiredApplicant = ''
      this.updateApplicant(new CoHostUser(info))
      this.apply()
    }
    listener.onCoHostRequestCancelled = (info: SeatUserInfo) => {
      if (!this.valid(generation)) return
      this.clearApplicant(info.liveID)
      this.apply()
    }
    listener.onCoHostRequestAccepted = (info: SeatUserInfo) => {
      if (!this.valid(generation)) return
      this.cancellations.delete(info.liveID)
      this.apply()
    }
    listener.onCoHostRequestRejected = (info: SeatUserInfo) => {
      if (!this.valid(generation)) return
      this.cancellations.delete(info.liveID)
      this.toast('request_rejected')
      this.apply()
    }
    listener.onCoHostRequestTimeout = (inviter: SeatUserInfo, invitee: SeatUserInfo) => {
      if (!this.valid(generation)) return
      this.clearApplicant(inviter.liveID)
      const id = inviter.liveID === this.liveID ? invitee.liveID : inviter.liveID
      this.operations.delete(id)
      this.cancellations.delete(id)
      this.toast('request_timeout')
      this.apply()
    }
    listener.onCoHostUserJoined = changed
    listener.onCoHostUserLeft = changed
    this.listener = listener
    this.sdk.addCoHostListener(listener)
    const refreshFollow = (users: V2TIMUserFullInfo[]) => {
      if (!this.valid(generation)) return
      users.forEach((user: V2TIMUserFullInfo) => {
        this.followTypes.delete(user.userID ?? '')
        this.followRequests.delete(user.userID ?? '')
      })
      this.queryFollow(users.map((user: V2TIMUserFullInfo) => user.userID ?? ''))
    }
    const friendship: V2TIMFriendshipListener = {
      onMyFollowingListChanged: (users: V2TIMUserFullInfo[], _isAdd: boolean) => refreshFollow(users),
      onMyFollowersListChanged: (users: V2TIMUserFullInfo[], _isAdd: boolean) => refreshFollow(users)
    }
    this.friendship = friendship
    V2TIMManager.getFriendshipManager().addFriendListener(friendship)
    this.apply()
  }

  deactivate(): void {
    this.active = false
    this.generation++
    clearTimeout(this.timeout)
    this.timeout = -1
    this.observers.forEach((remove: () => void) => remove())
    this.observers = []
    if (this.listener) this.sdk.removeCoHostListener(this.listener)
    if (this.friendship) V2TIMManager.getFriendshipManager().removeFriendListener(this.friendship)
    this.listener = undefined
    this.friendship = undefined
    this.operations.clear()
    this.cancellations.clear()
    this.followTypes.clear()
    this.followRequests.clear()
    this.nextCursor = ''
    this.applicantToken++
    this.responding = false
    this.expiredApplicant = ''
    this.state = new CoHostState()
    this.publish()
  }

  refresh(): void {
    if (!this.active || this.state.isLoading) return
    this.followTypes.clear()
    this.followRequests.clear()
    this.fetch('')
  }
  loadMore(): void {
    if (this.active && !this.state.isLoading && this.state.hasMore) this.fetch(this.nextCursor)
  }
  invite(id: string): void {
    if (id === this.liveID || this.state.isInvited(id) ||
      this.state.connected.some((user: CoHostUser) => user.liveID === id)) return
    this.perform(id, () => this.sdk.requestHostConnection(id, CoHostLayoutTemplate.HOST_DYNAMIC_GRID, 10, ''))
  }
  cancelInvitation(id: string): void {
    const user = this.state.invitees.find((item: CoHostUser) => item.liveID === id)
    if (!user || this.state.isBusy(id)) return
    this.cancellations.set(id, user)
    this.perform(id, () => this.sdk.cancelHostConnection(id), (success: boolean) => {
      if (success) this.cancellations.delete(id)
      this.apply()
    })
  }
  acceptInvitation(): void { this.respond(true) }
  rejectInvitation(): void { this.respond(false) }

  exitConnection(): void {
    if (!this.active || !this.state.isConnected || this.state.isExiting || this.operations.size > 0) return
    this.state.isExiting = true
    this.publish()
    this.cancelAndExit(this.state.invitees.slice(), this.generation)
  }
  private cancelAndExit(users: CoHostUser[], generation: number): void {
    const user = users[0]
    if (user) this.cancellations.set(user.liveID, user)
    const request = user ? this.sdk.cancelHostConnection(user.liveID) : this.sdk.exitHostConnection()
    request.then(() => {
      if (!this.valid(generation)) return
      if (user) {
        this.cancellations.delete(user.liveID)
        this.apply()
        this.cancelAndExit(users.slice(1), generation)
      } else {
        this.state.isExiting = false
        this.apply()
      }
    }).catch((error: Error) => {
      if (!this.valid(generation)) return
      this.state.isExiting = false
      this.apply()
      this.onToast?.(LiveKitErrorText.message(error))
    })
  }
  private respond(accept: boolean): void {
    const applicant = this.state.applicant
    if (!applicant || this.state.isBusy(applicant.liveID)) return
    if (Date.now() >= this.state.applicantDeadline) { this.expire(this.applicantToken); return }
    if (this.sdk.coHostState.applicant?.liveID !== applicant.liveID) { this.apply(); return }
    const token = this.applicantToken
    clearTimeout(this.timeout)
    this.responding = true
    this.perform(applicant.liveID, () => accept ? this.sdk.acceptHostConnection(applicant.liveID) :
      this.sdk.rejectHostConnection(applicant.liveID), () => {
      if (token !== this.applicantToken) return
      this.responding = false
      this.apply()
      if (token === this.applicantToken) this.scheduleTimeout()
    })
  }
  private perform(id: string, action: () => Promise<void>, done?: (success: boolean) => void): void {
    if (!this.active || !id || this.state.isBusy(id)) return
    const generation = this.generation
    const operation = ++this.sequence
    this.operations.set(id, operation)
    this.publish()
    action().then(() => true).catch((error: Error) => {
      if (this.valid(generation) && this.operations.get(id) === operation) {
        this.onToast?.(LiveKitErrorText.message(error))
      }
      return false
    }).then((success: boolean) => {
      if (!this.valid(generation) || this.operations.get(id) !== operation) return
      this.operations.delete(id)
      done?.(success)
      this.publish()
    })
  }
  private fetch(cursor: string): void {
    const generation = this.generation
    const request = ++this.sequence
    this.candidateRequest = request
    this.state.isLoading = true
    this.state.loadError = ''
    this.publish()
    this.sdk.getCoHostCandidates(cursor).then(() => {
      if (!this.valid(generation) || request !== this.candidateRequest) return
      this.state.isLoading = false
      this.nextCursor = this.sdk.coHostState.candidatesCursor
      this.state.hasMore = this.nextCursor.length > 0 && this.nextCursor !== cursor
      this.apply()
      this.queryFollow(this.state.candidates.map((user: CoHostUser) => user.userID))
    }).catch((error: Error) => {
      if (!this.valid(generation) || request !== this.candidateRequest) return
      this.state.isLoading = false
      this.state.loadError = LiveKitErrorText.message(error)
      this.publish()
    })
  }
  private users(infos: SeatUserInfo[]): CoHostUser[] {
    const seen = new Set<string>()
    return infos.filter((info: SeatUserInfo) => {
      if (!info.liveID || info.liveID === this.liveID || seen.has(info.liveID)) return false
      seen.add(info.liveID)
      return true
    }).map((info: SeatUserInfo) => {
      const user = new CoHostUser(info, this.state.candidates.find((item: CoHostUser) => item.liveID === info.liveID))
      user.followType = this.followTypes.get(user.userID) ?? -1
      return user
    })
  }
  private apply(): void {
    if (!this.active) return
    const sdk = this.sdk.coHostState
    this.state.connected = this.users(sdk.connected.getAllData())
    this.state.connected.forEach((user: CoHostUser) => this.cancellations.delete(user.liveID))
    const invitees = this.users(sdk.invitees.getAllData())
    this.state.invitees = invitees.concat(Array.from(this.cancellations.values()).filter((user: CoHostUser) =>
      !invitees.some((item: CoHostUser) => item.liveID === user.liveID)))
    this.state.candidates = this.users(sdk.connected.getAllData().concat(sdk.candidates.getAllData())
      .concat(sdk.invitees.getAllData()))
    this.state.candidates = this.state.candidates.concat(this.state.invitees.filter((user: CoHostUser) =>
      !this.state.candidates.some((item: CoHostUser) => item.liveID === user.liveID)))
    const connected = sdk.coHostStatus === CoHostStatus.CONNECTED
    if (connected !== this.state.isConnected) {
      this.state.isConnected = connected
      this.state.connectionStartedAt = connected ? Date.now() : 0
    }
    if (sdk.applicant && sdk.applicant.liveID !== this.expiredApplicant) {
      this.updateApplicant(new CoHostUser(sdk.applicant))
    } else if (!sdk.applicant && !this.responding) {
      this.resetApplicant()
      this.expiredApplicant = ''
    }
    this.publish()
  }
  private updateApplicant(user: CoHostUser): void {
    const changed = this.state.applicant?.liveID !== user.liveID || this.state.applicant?.userID !== user.userID
    user.followType = this.followTypes.get(user.userID) ?? -1
    this.state.applicant = user
    if (!changed) return
    this.applicantToken++
    this.responding = false
    this.state.applicantDeadline = Date.now() + 10000
    this.scheduleTimeout()
    this.queryFollow([user.userID])
  }
  private scheduleTimeout(): void {
    clearTimeout(this.timeout)
    if (!this.state.applicant || !this.active) return
    const token = this.applicantToken
    const generation = this.generation
    this.timeout = setTimeout(() => {
      if (this.valid(generation)) this.expire(token)
    }, Math.max(0, this.state.applicantDeadline - Date.now()))
  }
  private expire(token: number): void {
    const user = this.state.applicant
    if (!user || token !== this.applicantToken || this.responding) return
    const current = this.sdk.coHostState.applicant
    const pending = current?.liveID === user.liveID && current?.userID === user.userID
    this.expiredApplicant = user.liveID
    this.clearApplicant(user.liveID)
    this.publish()
    if (pending) this.sdk.rejectHostConnection(user.liveID).catch(() => {})
    else this.apply()
  }
  private clearApplicant(id: string): void {
    if (this.state.applicant?.liveID !== id) return
    this.operations.delete(id)
    this.resetApplicant()
  }
  private resetApplicant(): void {
    clearTimeout(this.timeout)
    this.timeout = -1
    this.applicantToken++
    this.state.applicant = undefined
    this.state.applicantDeadline = 0
    this.responding = false
  }
  private queryFollow(ids: string[]): void {
    const unique = Array.from(new Set(ids)).filter((id: string) => id.length > 0 &&
      !this.followTypes.has(id) && !this.followRequests.has(id))
    const batch = unique.slice(0, 100)
    if (!this.active || !batch.length) return
    const generation = this.generation
    const request = ++this.sequence
    batch.forEach((id: string) => this.followRequests.set(id, request))
    V2TIMManager.getFriendshipManager().checkFollowType(batch).then((results: V2TIMFollowTypeCheckResult[]) => {
      if (!this.valid(generation)) return
      results.forEach((result: V2TIMFollowTypeCheckResult) => {
        const id = result.userID ?? ''
        if (this.followRequests.get(id) === request && result.resultCode === 0) {
          this.followTypes.set(id, result.followType)
        }
      })
      batch.forEach((id: string) => { if (this.followRequests.get(id) === request) this.followRequests.delete(id) })
      this.apply()
      this.queryFollow(unique.slice(100))
    }).catch(() => {
      if (!this.valid(generation)) return
      batch.forEach((id: string) => { if (this.followRequests.get(id) === request) this.followRequests.delete(id) })
      this.toast('follow_query_failed')
    })
  }
  private valid(generation: number): boolean { return this.active && generation === this.generation }
  private toast(key: string): void {
    this.onToast?.(LiveKitResources.localizedString(`tuilivekit.pusher.cohost.${key}`))
  }
  private publish(): void {
    const next = new CoHostState()
    next.candidates = this.state.candidates.slice()
    next.connected = this.state.connected.slice()
    next.invitees = this.state.invitees.slice()
    next.applicant = this.state.applicant
    next.applicantDeadline = this.state.applicantDeadline
    next.pendingLiveIDs = Array.from(this.operations.keys())
    next.isLoading = this.state.isLoading
    next.hasMore = this.state.hasMore
    next.loadError = this.state.loadError
    next.isConnected = this.state.isConnected
    next.isExiting = this.state.isExiting
    next.connectionStartedAt = this.state.connectionStartedAt
    this.state = next
    // The working state is replaced before any subsequent mutation.
    const snapshot = new CoHostState()
    snapshot.candidates = next.candidates
    snapshot.connected = next.connected
    snapshot.invitees = next.invitees
    snapshot.applicant = next.applicant
    snapshot.applicantDeadline = next.applicantDeadline
    snapshot.pendingLiveIDs = next.pendingLiveIDs
    snapshot.isLoading = next.isLoading
    snapshot.hasMore = next.hasMore
    snapshot.loadError = next.loadError
    snapshot.isConnected = next.isConnected
    snapshot.isExiting = next.isExiting
    snapshot.connectionStartedAt = next.connectionStartedAt
    const signature = JSON.stringify(snapshot)
    if (this.lastPublished === signature) return
    this.lastPublished = signature
    this.onStateChanged?.(snapshot)
  }
}
