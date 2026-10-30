import {
  LiveAudienceListener,
  LiveAudienceState,
  LiveAudienceStore,
  LiveUserInfo,
  V2TIMFollowTypeCheckResult,
  V2TIMFollowOperationResult,
  V2TIMFriendshipListener,
  V2TIMManager,
  V2TIMUserFullInfo,
} from '@tencentcloud/atomicxcore'
import { AudienceWelcome } from '../../../common/audience/AudienceWelcomeView'
import { LiveKitDataObserver } from '../../../common/LiveKitResources'

function isFollowed(followType: number): boolean {
  return followType === 1 || followType === 3
}

export class User {
  userID: string
  userName: string
  avatarURL: string
  level: number

  constructor(userID: string, userName: string, avatarURL: string, level: number) {
    this.userID = userID
    this.userName = userName
    this.avatarURL = avatarURL
    this.level = level
  }

  equals(other: User): boolean {
    return this.userID === other.userID && this.userName === other.userName &&
      this.avatarURL === other.avatarURL && this.level === other.level
  }
}

export enum FollowStatus {
  unknown,
  notFollowing,
  following,
}

export enum Action {
  follow,
  unfollow,
  mute,
  unmute,
  remove,
}

export class State {
  users: User[] = []
  count: number = 0
  mutedUserIDs: string[] = []
  followStatusByUserID: Map<string, FollowStatus> = new Map()
  pendingActionByUserID: Map<string, Action> = new Map()

  followStatus(userID: string): FollowStatus {
    return this.followStatusByUserID.get(userID) ?? FollowStatus.unknown
  }

  equals(other: State): boolean {
    return this.count === other.count && this.users.length === other.users.length &&
      this.users.every((user: User, index: number) => user.equals(other.users[index])) &&
      this.mutedUserIDs.length === other.mutedUserIDs.length &&
      this.mutedUserIDs.every((id: string, index: number) => id === other.mutedUserIDs[index]) &&
      this.followStatusByUserID.size === other.followStatusByUserID.size &&
      Array.from(this.followStatusByUserID.keys()).every((id: string) =>
      this.followStatusByUserID.get(id) === other.followStatusByUserID.get(id)) &&
      this.pendingActionByUserID.size === other.pendingActionByUserID.size &&
      Array.from(this.pendingActionByUserID.keys()).every((id: string) =>
      this.pendingActionByUserID.get(id) === other.pendingActionByUserID.get(id))
  }

  copy(): State {
    const state = new State()
    state.users = this.users.map((user: User) => new User(user.userID, user.userName, user.avatarURL, user.level))
    state.count = this.count
    state.mutedUserIDs = this.mutedUserIDs.slice()
    state.followStatusByUserID = new Map(this.followStatusByUserID)
    state.pendingActionByUserID = new Map(this.pendingActionByUserID)
    return state
  }
}

export class PusherAudienceStore {
  onAudienceEntered?: (welcome: AudienceWelcome) => void
  onActionCompleted?: (userID: string, action: Action, succeeded: boolean) => void
  state: State = new State()
  private stateChanged?: (state: State) => void
  private readonly sdkStore: LiveAudienceStore
  private unobservers: (() => void)[] = []
  private operationIDs: Map<string, number> = new Map()
  private operationSeed: number = 0
  private followQueryIDs: Map<string, number> = new Map()
  private refreshID?: number
  private activationID?: number
  private audienceListener?: LiveAudienceListener
  private friendshipListener?: V2TIMFriendshipListener

  constructor(liveID: string) {
    this.sdkStore = LiveAudienceStore.create(liveID)
  }

  get sdkState(): LiveAudienceState {
    return this.sdkStore.liveAudienceState
  }

  set onStateChanged(callback: ((state: State) => void) | undefined) {
    this.stateChanged = callback
    callback?.(this.state)
  }

  get onStateChanged(): ((state: State) => void) | undefined {
    return this.stateChanged
  }

  activate(): void {
    if (this.activationID !== undefined) {
      return
    }
    const activationID = ++this.operationSeed
    this.activationID = activationID
    const applySDK = () => {
      if (this.activationID === activationID) {
        this.apply()
      }
    }
    const sdkState = this.sdkStore.liveAudienceState
    this.unobservers = [LiveKitDataObserver.observe(sdkState.audienceList, applySDK),
      LiveKitDataObserver.observe(sdkState.messageBannedUserList, applySDK)]
    const audienceListener = new LiveAudienceListener()
    audienceListener.onAudienceJoined = (audience: LiveUserInfo) => {
      if (this.activationID === activationID) {
        this.onAudienceEntered?.(new AudienceWelcome(audience.userID,
          audience.userName.length === 0 ? audience.userID : audience.userName, Math.max(0, audience.level)))
      }
    }
    this.audienceListener = audienceListener
    this.sdkStore.addLiveAudienceListener(audienceListener)
    const friendshipListener: V2TIMFriendshipListener = {
      onMyFollowingListChanged: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => {
        const userIDs = userInfoList.map((info: V2TIMUserFullInfo) => info.userID ?? '')
          .filter((id: string) => id.length > 0)
        if (this.activationID === activationID && userIDs.length > 0) {
          this.handleFollowingListChanged(userIDs)
        }
      }
    }
    this.friendshipListener = friendshipListener
    V2TIMManager.getFriendshipManager().addFriendListener(friendshipListener)
    applySDK()
  }

  deactivate(resetState: boolean): void {
    this.activationID = undefined
    this.unobservers.forEach((unobserve: () => void) => unobserve())
    this.unobservers = []
    if (this.audienceListener !== undefined) {
      this.sdkStore.removeLiveAudienceListener(this.audienceListener)
      this.audienceListener = undefined
    }
    if (this.friendshipListener !== undefined) {
      V2TIMManager.getFriendshipManager().removeFriendListener(this.friendshipListener)
      this.friendshipListener = undefined
    }
    this.operationIDs.clear()
    this.followQueryIDs.clear()
    this.refreshID = undefined
    this.state.pendingActionByUserID = new Map()
    this.state.followStatusByUserID = new Map()
    if (resetState) {
      this.state.users = []
      this.state.count = 0
      this.state.mutedUserIDs = []
    }
    this.notify()
  }

  refresh(): void {
    if (this.activationID === undefined) {
      return
    }
    if (this.refreshID !== undefined) {
      return
    }
    const requestID = ++this.operationSeed
    this.refreshID = requestID
    this.sdkStore.fetchAudienceList().catch(() => {
    }).then(() => {
      if (this.refreshID === requestID) {
        this.refreshID = undefined
      }
    })
  }

  refreshFollowStatus(userID: string): void {
    if (this.activationID === undefined || userID.length === 0) {
      return
    }
    this.state.followStatusByUserID.set(userID, FollowStatus.unknown)
    this.notify()
    this.checkFollowStatus([userID])
  }

  toggleFollow(userID: string): void {
    const status = this.state.followStatus(userID)
    if (status === FollowStatus.unknown) {
      this.refreshFollowStatus(userID)
      return
    }
    const action = status === FollowStatus.following ? Action.unfollow : Action.follow
    const manager = V2TIMManager.getFriendshipManager()
    this.performAction(userID, action,
      () => (action === Action.follow ? manager.followUser([userID]) : manager.unfollowUser([userID])).then(
        (results: V2TIMFollowOperationResult[]) => {
          const result = results.find((item: V2TIMFollowOperationResult) => item.userID === userID)
          if (result === undefined || result.resultCode !== 0) {
            throw new Error(result?.resultInfo ?? 'Missing follow result')
          }
        }),
      () => this.state.followStatusByUserID.set(userID,
        action === Action.follow ? FollowStatus.following : FollowStatus.notFollowing))
  }

  toggleMessagePermission(userID: string): void {
    const isMuted = this.state.mutedUserIDs.includes(userID)
    this.performAction(userID, isMuted ? Action.unmute : Action.mute,
      () => this.sdkStore.disableSendMessage(userID, !isMuted), () => this.refresh())
  }

  removeFromRoom(userID: string): void {
    this.performAction(userID, Action.remove, () => this.sdkStore.kickUserOutOfRoom(userID), () => this.refresh())
  }

  apply(): void {
    if (this.activationID === undefined) {
      return
    }
    const sdkState = this.sdkStore.liveAudienceState
    const users = sdkState.audienceList.getAllData().filter((user: LiveUserInfo) => user.userID.length > 0)
      .map((user: LiveUserInfo) => new User(user.userID, user.userName, user.avatarURL, Math.max(0, user.level)))
    const count = Math.max(0, sdkState.audienceCount)
    const mutedUserIDs = sdkState.messageBannedUserList.getAllData().map((user: LiveUserInfo) => user.userID)
      .filter((id: string) => id.length > 0)
    const sameUsers = users.length === this.state.users.length && users.every((user: User, index: number) => {
      const old = this.state.users[index]
      return old.userID === user.userID && old.userName === user.userName && old.avatarURL === user.avatarURL &&
        old.level === user.level
    })
    const sameMuted = mutedUserIDs.length === this.state.mutedUserIDs.length &&
      mutedUserIDs.every((id: string) => this.state.mutedUserIDs.includes(id))
    if (sameUsers && count === this.state.count && sameMuted) {
      return
    }
    this.state.users = users
    this.state.count = count
    this.state.mutedUserIDs = mutedUserIDs
    this.notify()
  }

  private handleFollowingListChanged(userIDs: string[]): void {
    if (this.activationID === undefined) {
      return
    }
    const relevantIDs = userIDs.filter((id: string) => this.state.followStatusByUserID.has(id))
    this.checkFollowStatus(relevantIDs)
  }

  private performAction(userID: string, action: Action, operation: () => Promise<void>, onSuccess: () => void): void {
    if (this.activationID === undefined || userID.length === 0 || this.operationIDs.has(userID)) {
      return
    }
    const operationID = ++this.operationSeed
    this.operationIDs.set(userID, operationID)
    if (action === Action.follow || action === Action.unfollow) {
      this.followQueryIDs.delete(userID)
    }
    this.state.pendingActionByUserID.set(userID, action)
    this.notify()
    const activationID = this.activationID
    operation().then(() => true).catch(() => false).then((succeeded: boolean) => {
      if (this.activationID !== activationID || this.operationIDs.get(userID) !== operationID) {
        return
      }
      if (succeeded) {
        onSuccess()
      }
      this.operationIDs.delete(userID)
      this.state.pendingActionByUserID.delete(userID)
      this.notify()
      this.onActionCompleted?.(userID, action, succeeded)
    })
  }

  private checkFollowStatus(userIDs: string[]): void {
    const activationID = this.activationID
    if (activationID === undefined || userIDs.length === 0) {
      return
    }
    const queryID = ++this.operationSeed
    const requestedIDs = userIDs.filter((id: string) => !this.operationIDs.has(id))
    if (requestedIDs.length === 0) {
      return
    }
    requestedIDs.forEach((id: string) => this.followQueryIDs.set(id, queryID))
    V2TIMManager.getFriendshipManager().checkFollowType(requestedIDs).then((results: V2TIMFollowTypeCheckResult[]) => {
      if (this.activationID !== activationID) {
        return
      }
      results.forEach((result: V2TIMFollowTypeCheckResult) => {
        if ((result.userID ?? '').length > 0 && this.followQueryIDs.get(result.userID as string) === queryID) {
          this.state.followStatusByUserID.set(result.userID as string,
            isFollowed(result.followType) ? FollowStatus.following : FollowStatus.notFollowing)
        }
      })
      this.notify()
    }).catch(() => {
    })
  }

  private notify(): void {
    this.stateChanged?.(this.state)
  }
}
