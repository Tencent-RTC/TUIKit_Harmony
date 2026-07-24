import { ContactInfo, ContactStore } from '@tencentcloud/atomicxcore'
import { ConversationInfo, ConversationListStore, ReceiveMessageOption } from '@tencentcloud/atomicxcore'
import { GroupInviteOption, GroupJoinOption, GroupStore, GroupType } from '@tencentcloud/atomicxcore'
import { GroupMember, GroupMemberFilterRole, GroupMemberRole, GroupMemberStore } from '@tencentcloud/atomicxcore'
import { LoginStore } from '@tencentcloud/atomicxcore'
import { CompletionHandler } from '@tencentcloud/atomicxcore'
import { GroupInfo } from '@tencentcloud/atomicxcore'
import { PublishParams, TUIEventBus } from '../../basecomponent/utils/TUIEventBus'
import {
  CompletionHandlerAdapter,
  GetConversationInfoCompletionHandlerAdapter,
  GetGroupInfoCompletionHandlerAdapter,
  GetMemberInfoCompletionHandlerAdapter
} from '../../basecomponent/utils/CompletionHandlers'

const GROUP_AVATAR_URL_TEMPLATE: string =
  'https://im.sdk.qcloud.com/download/tuikit-resource/group-avatar/group_avatar_%s.png'
const GROUP_AVATAR_URL_COUNT: number = 24

export function getGroupAvatarUrls(): string[] {
  const list: string[] = []
  for (let i = 1; i <= GROUP_AVATAR_URL_COUNT; i++) {
    list.push(GROUP_AVATAR_URL_TEMPLATE.replace('%s', `${i}`))
  }
  return list
}

@Observed
export class GroupChatSettingViewModel {
  readonly groupID: string
  readonly conversationID: string
  isLoading: boolean = false
  selfNameCard: string | null = null
  chatBackgroundImageUri: string | null = null

  private readonly _contactStore: ContactStore = ContactStore.shared
  private readonly _groupStore: GroupStore = GroupStore.shared
  private readonly _groupMemberStore: GroupMemberStore
  private readonly _conversationListStore: ConversationListStore = ConversationListStore.create()

  private pendingAllMemberCallbacks: Array<() => void> = []
  private isFetchingAllMembers: boolean = false

  constructor(groupID: string) {
    this.groupID = groupID
    this.conversationID = `group_${groupID}`
    this._groupMemberStore = GroupMemberStore.create(groupID)

    this._contactStore.loadFriends()
    this._groupStore.loadJoinedGroups()
    this._conversationListStore.getConversationInfo(this.conversationID, new GetConversationInfoCompletionHandlerAdapter())

    this.loadAllMembers(GroupMemberFilterRole.ALL, () => {
    })
    this.refreshSelfNameCard()
  }

  get contactStore(): ContactStore {
    return this._contactStore
  }

  get groupStore(): GroupStore {
    return this._groupStore
  }

  get groupMemberStore(): GroupMemberStore {
    return this._groupMemberStore
  }

  get conversationListStore(): ConversationListStore {
    return this._conversationListStore
  }

  private get currentUserID(): string {
    return LoginStore.shared().state.loginUserInfo?.userID ?? ''
  }

  private get groupInfo(): GroupInfo | undefined {
    return this._groupStore.state.joinedGroupList.find((it: GroupInfo) => it.groupID === this.groupID)
  }

  private get conversationInfo(): ConversationInfo | null {
    const list = this._conversationListStore.state.conversationList
    const index = list.getIndex(this.conversationID)
    if (index < 0) {
      return null
    }
    return list.getData(index)
  }

  get friendList(): ContactInfo[] {
    return this._contactStore.state.friendList
  }

  get groupType(): GroupType {
    return this.groupInfo?.groupType ?? GroupType.WORK
  }

  get groupName(): string {
    return this.groupInfo?.groupName ?? ''
  }

  get avatarURL(): string {
    return this.groupInfo?.avatarURL ?? ''
  }

  get notification(): string {
    return this.groupInfo?.notification ?? ''
  }

  get isNotDisturb(): boolean {
    return this.conversationInfo?.receiveOption === ReceiveMessageOption.NOT_NOTIFY
  }

  get isPinned(): boolean {
    return this.conversationInfo?.isPinned ?? false
  }

  get isAllMuted(): boolean {
    return this.groupInfo?.isAllMuted ?? false
  }

  get memberList(): GroupMember[] {
    return this._groupMemberStore.state.memberList
  }

  get silencedMembers(): GroupMember[] {
    return this.memberList.filter((it: GroupMember) => it.isMuted)
  }

  get adminMembers(): GroupMember[] {
    return this.memberList.filter((it: GroupMember) => it.role === GroupMemberRole.ADMIN)
  }

  get selfRole(): GroupMemberRole {
    return this.groupInfo?.selfRole ?? GroupMemberRole.MEMBER
  }

  get memberCount(): number {
    return this.groupInfo?.memberCount ?? 0
  }

  get joinGroupApprovalType(): GroupJoinOption {
    return this.groupInfo?.joinOption ?? GroupJoinOption.ANY
  }

  get inviteToGroupApprovalType(): GroupInviteOption {
    return this.groupInfo?.inviteOption ?? GroupInviteOption.ANY
  }

  get hasMoreMembers(): boolean {
    return this._groupMemberStore.state.hasMoreMembers
  }

  private refreshSelfNameCard(): void {
    const userID = this.currentUserID
    if (userID.length === 0) {
      return
    }
    this._groupMemberStore.getMemberInfo([userID], new GetMemberInfoCompletionHandlerAdapter((memberInfoList: GroupMember[]) => {
      this.selfNameCard = memberInfoList[0]?.nameCard ?? null
    }))
  }

  private loadAllMembers(role: GroupMemberFilterRole, onComplete: () => void): void {
    this._groupMemberStore.loadMembers([role], new CompletionHandlerAdapter(() => {
      this.loadMoreMembersUntilEnd(onComplete)
    }, () => {
      onComplete()
    }))
  }

  private loadMoreMembersUntilEnd(onComplete: () => void): void {
    if (!this._groupMemberStore.state.hasMoreMembers) {
      onComplete()
      return
    }
    this._groupMemberStore.loadMoreMembers(new CompletionHandlerAdapter(() => {
      this.loadMoreMembersUntilEnd(onComplete)
    }, () => {
      onComplete()
    }))
  }

  loadAllGroupMembers(onComplete?: () => void): void {
    if (onComplete) {
      this.pendingAllMemberCallbacks.push(onComplete)
    }
    if (!this._groupMemberStore.state.hasMoreMembers) {
      this.notifyAllMemberCallbacks()
      return
    }
    if (this.isFetchingAllMembers) {
      return
    }
    this.isFetchingAllMembers = true
    this.loadAllMembers(GroupMemberFilterRole.ALL, () => {
      this.isFetchingAllMembers = false
      this.notifyAllMemberCallbacks()
    })
  }

  private notifyAllMemberCallbacks(): void {
    const callbacks = this.pendingAllMemberCallbacks.slice()
    this.pendingAllMemberCallbacks = []
    callbacks.forEach((cb: () => void) => cb())
  }

  toggleDoNotDisturb(): void {
    const mute = !this.isNotDisturb
    this._conversationListStore.setReceiveMessageOpt(
      this.conversationID,
      mute ? ReceiveMessageOption.NOT_NOTIFY : ReceiveMessageOption.RECEIVE,
      this.emptyHandler()
    )
  }

  togglePinChat(): void {
    const pin = !this.isPinned
    this._conversationListStore.pinConversation(this.conversationID, pin, this.emptyHandler())
  }

  setGroupName(name: string): void {
    const info = new GroupInfo(this.groupID)
    info.groupName = name
    const conversationID = this.conversationID
    this._groupStore.updateProfile(info, new CompletionHandlerAdapter(() => {
      console.info(`[GroupChatSettingViewModel] setGroupName success, publish event. conversationID=${conversationID}, title=${name}`)
      const data: Record<string, Object> = {
        'conversationID': conversationID as Object,
        'title': name as Object,
      }
      TUIEventBus.getInstance().publish('chat.conversation.profileUpdated', null, new PublishParams(false, data))
    }, (code: number, desc: string) => {
      console.error(`[GroupChatSettingViewModel] setGroupName failed: code=${code}, desc=${desc}`)
    }))
  }

  setGroupAvatar(avatarUrl: string): void {
    const info = new GroupInfo(this.groupID)
    info.avatarURL = avatarUrl
    const conversationID = this.conversationID
    this._groupStore.updateProfile(info, new CompletionHandlerAdapter(() => {
      console.info(`[GroupChatSettingViewModel] setGroupAvatar success, publish event. conversationID=${conversationID}, avatarURL=${avatarUrl}`)
      const data: Record<string, Object> = {
        'conversationID': conversationID as Object,
        'avatarURL': avatarUrl as Object,
      }
      TUIEventBus.getInstance().publish('chat.conversation.profileUpdated', null, new PublishParams(false, data))
    }, (code: number, desc: string) => {
      console.error(`[GroupChatSettingViewModel] setGroupAvatar failed: code=${code}, desc=${desc}`)
    }))
  }

  setGroupNotice(notice: string): void {
    const info = new GroupInfo(this.groupID)
    info.notification = notice
    this._groupStore.updateProfile(info, this.emptyHandler())
  }

  setJoinGroupApproveType(type: GroupJoinOption): void {
    this._groupStore.setJoinOption(this.groupID, type, this.emptyHandler())
  }

  setInviteGroupApproveType(type: GroupInviteOption): void {
    this._groupStore.setInviteOption(this.groupID, type, this.emptyHandler())
  }

  setGroupNickname(nickname: string): void {
    this._groupMemberStore.setSelfNameCard(nickname, new CompletionHandlerAdapter(() => {
      this.refreshSelfNameCard()
    }))
  }

  addMember(userIDList: string[]): void {
    if (userIDList.length === 0) {
      return
    }
    this._groupMemberStore.addMember(userIDList, this.emptyHandler())
  }

  quitGroup(onSuccess?: () => void, onFailure?: (code: number, desc: string) => void): void {
    this._groupStore.quitGroup(this.groupID, new CompletionHandlerAdapter(() => {
      this._conversationListStore.deleteConversation(this.conversationID)
      onSuccess?.()
    }, (code: number, desc: string) => {
      onFailure?.(code, desc)
    }))
  }

  dismissGroup(onSuccess?: () => void, onFailure?: (code: number, desc: string) => void): void {
    this._groupStore.dismissGroup(this.groupID, new CompletionHandlerAdapter(() => {
      this._conversationListStore.deleteConversation(this.conversationID)
      onSuccess?.()
    }, (code: number, desc: string) => {
      onFailure?.(code, desc)
    }))
  }

  clearChatHistory(): void {
    this._conversationListStore.clearConversationMessages(this.conversationID, this.emptyHandler())
  }

  setChatBackground(imageUri: string | null): void {
    // TODO(harmony): MmkvChatBackgroundStore / ChatEventBus not implemented on Harmony yet
    this.chatBackgroundImageUri = imageUri
  }

  clearChatBackground(): void {
    // TODO(harmony): MmkvChatBackgroundStore / ChatEventBus not implemented on Harmony yet
    this.chatBackgroundImageUri = null
  }

  changeOwner(newOwnerID: string): void {
    this._groupStore.changeOwner(this.groupID, newOwnerID)
  }

  toggleGroupAllMute(): void {
    const mute = !this.isAllMuted
    this._groupStore.muteAllMembers(this.groupID, mute, this.emptyHandler())
  }

  muteGroupMember(userID: string, muteTimeSeconds: number, onFailure?: (code: number, desc: string) => void): void {
    this._groupMemberStore.muteMember(userID, muteTimeSeconds, new CompletionHandlerAdapter(undefined, (code: number, desc: string) => {
      onFailure?.(code, desc)
    }))
  }

  setMemberRole(userID: string, role: GroupMemberRole, onFailure?: (code: number, desc: string) => void): void {
    this._groupMemberStore.setMemberRole(userID, role, new CompletionHandlerAdapter(undefined, (code: number, desc: string) => {
      onFailure?.(code, desc)
    }))
  }

  deleteMember(members: GroupMember[]): void {
    const userIDList = members.map((it: GroupMember) => it.userID)
    this._groupMemberStore.deleteMember(userIDList, this.emptyHandler())
  }

  private emptyHandler(): CompletionHandler {
    return new CompletionHandlerAdapter()
  }
}

@Observed
export class GroupSettingState {
  groupType: GroupType = GroupType.WORK;
  groupName: string = '';
  avatarURL: string = '';
  notice: string = '';
  isNotDisturb: boolean = false;
  isAllMuted: boolean = false;
  isPinned: boolean = false;
  groupOwner?: GroupMember = undefined;
  allMembers: GroupMember[] = [];
  currentUserRole: GroupMemberRole = GroupMemberRole.MEMBER;
  selfNameCard: string = '';
  memberCount: number = 0;
  joinGroupApprovalType: GroupJoinOption = GroupJoinOption.ANY;
  inviteToGroupApprovalType: GroupJoinOption = GroupJoinOption.ANY;
}

@Observed
export class GroupSettingStore {
  readonly groupID: string = '';
  state: GroupSettingState = new GroupSettingState();
  private groupStore: GroupStore = GroupStore.shared;
  private memberStore: GroupMemberStore;
  private conversationStore: ConversationListStore = ConversationListStore.create();
  private conversationID: string = '';

  private constructor(groupID: string) {
    this.groupID = groupID;
    this.conversationID = `group_${groupID}`;
    this.memberStore = GroupMemberStore.create(groupID);
  }

  static create(groupID: string): GroupSettingStore {
    return new GroupSettingStore(groupID);
  }

  fetchGroupInfo(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new GetGroupInfoCompletionHandlerAdapter((info: GroupInfo) => {
        this.state.groupType = info.groupType ?? GroupType.WORK;
        this.state.groupName = info.groupName || '';
        this.state.avatarURL = info.avatarURL || '';
        this.state.notice = info.notification || '';
        this.state.memberCount = info.memberCount ?? 0;
        this.state.isAllMuted = info.isAllMuted ?? false;
        this.state.joinGroupApprovalType = info.joinOption ?? GroupJoinOption.ANY;
        this.state.inviteToGroupApprovalType = (info.inviteOption as number as GroupJoinOption) ?? GroupJoinOption.ANY;
        this.state.currentUserRole = info.selfRole ?? GroupMemberRole.MEMBER;
        this.fetchConversationInfo();
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`getGroupInfo failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.getGroupInfo(this.groupID, completion);
    });
  }

  fetchGroupMemberList(_role: GroupMemberRole): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        const members: GroupMember[] = this.memberStore.state.memberList.slice();
        this.state.allMembers = members;
        this.state.memberCount = members.length;
        this.state.groupOwner = members.find((m: GroupMember) => m.role === GroupMemberRole.OWNER);
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`loadMembers failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.loadMembers([GroupMemberFilterRole.ALL], completion);
    });
  }

  fetchSelfMemberInfo(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const currentUserID: string = LoginStore.shared().state.loginUserInfo?.userID ?? '';
      const selfFromList: GroupMember | undefined = this.state.allMembers.find((m: GroupMember) => m.userID === currentUserID);
      if (selfFromList) {
        this.state.currentUserRole = selfFromList.role;
        this.state.selfNameCard = selfFromList.nameCard || '';
      } else if (currentUserID.length > 0 && this.state.groupOwner?.userID === currentUserID) {
        this.state.currentUserRole = GroupMemberRole.OWNER;
        this.state.selfNameCard = this.state.groupOwner?.nameCard || '';
      }
      resolve();
    });
  }

  setGroupJoinOption(option: GroupJoinOption): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.joinGroupApprovalType = option;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`setJoinOption failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.setJoinOption(this.groupID, option, completion);
    });
  }

  setGroupInviteOption(option: GroupJoinOption): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const inviteOpt: GroupInviteOption = option as number as GroupInviteOption;
      const completion = new CompletionHandlerAdapter(() => {
        this.state.inviteToGroupApprovalType = option;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`setInviteOption failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.setInviteOption(this.groupID, inviteOpt, completion);
    });
  }

  updateGroupProfile(name?: string, notice?: string, avatarURL?: string): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const info: GroupInfo = new GroupInfo(this.groupID);
      if (name !== undefined) {
        info.groupName = name;
      }
      if (notice !== undefined) {
        info.notification = notice;
      }
      if (avatarURL !== undefined) {
        info.avatarURL = avatarURL;
      }
      const conversationID = this.conversationID;
      const completion = new CompletionHandlerAdapter(() => {
        if (name !== undefined) {
          this.state.groupName = name;
        }
        if (notice !== undefined) {
          this.state.notice = notice;
        }
        if (avatarURL !== undefined) {
          this.state.avatarURL = avatarURL;
        }
        if (name !== undefined || avatarURL !== undefined) {
          const data: Record<string, Object> = {
            'conversationID': conversationID as Object,
          };
          if (name !== undefined) {
            data['title'] = name as Object;
          }
          if (avatarURL !== undefined) {
            data['avatarURL'] = avatarURL as Object;
          }
          console.info(`[GroupSettingStore] updateGroupProfile success, publish event. conversationID=${conversationID}, title=${name}, avatar=${avatarURL}`);
          TUIEventBus.getInstance().publish('chat.conversation.profileUpdated', null, new PublishParams(false, data));
        }
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`updateProfile failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.updateProfile(info, completion);
    });
  }

  setSelfGroupNameCard(nameCard: string): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.selfNameCard = nameCard;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`setSelfNameCard failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.setSelfNameCard(nameCard, completion);
    });
  }

  addGroupMember(userIDList: string[]): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.fetchGroupMemberList(GroupMemberRole.MEMBER);
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`addMember failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.addMember(userIDList, completion);
    });
  }

  deleteGroupMember(members: GroupMember[]): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const userIDList: string[] = members.map((m: GroupMember) => m.userID);
      const completion = new CompletionHandlerAdapter(() => {
        this.fetchGroupMemberList(GroupMemberRole.MEMBER);
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`deleteMember failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.deleteMember(userIDList, completion);
    });
  }

  changeGroupOwner(newOwnerID: string): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`changeOwner failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.changeOwner(this.groupID, newOwnerID, completion);
    });
  }

  setGroupMemberRole(userID: string, role: GroupMemberRole): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`setMemberRole failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.setMemberRole(userID, role, completion);
    });
  }

  setGroupMemberMuteTime(userID: string, time: number): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`muteMember failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.muteMember(userID, time, completion);
    });
  }

  setMuteAllMembers(value: boolean): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.isAllMuted = value;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`muteAllMembers failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.muteAllMembers(this.groupID, value, completion);
    });
  }

  dismissGroup(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`dismissGroup failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.dismissGroup(this.groupID, completion);
    });
  }

  quitGroup(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`quitGroup failed: code=${code}, desc=${desc}`));
      });
      this.groupStore.quitGroup(this.groupID, completion);
    });
  }

  getMemberInfo(userIDList: string[]): Promise<GroupMember[]> {
    return new Promise<GroupMember[]>((resolve: (members: GroupMember[]) => void, reject: (e: Error) => void) => {
      const completion = new GetMemberInfoCompletionHandlerAdapter((memberInfoList: GroupMember[]) => {
        resolve(memberInfoList);
      }, (code: number, desc: string) => {
        reject(new Error(`getMemberInfo failed: code=${code}, desc=${desc}`));
      });
      this.memberStore.getMemberInfo(userIDList, completion);
    });
  }

  private fetchConversationInfo(): void {
    const completion = new GetConversationInfoCompletionHandlerAdapter((conversationInfo: ConversationInfo) => {
      this.state.isPinned = conversationInfo.isPinned ?? false;
      this.state.isNotDisturb = conversationInfo.receiveOption !== ReceiveMessageOption.RECEIVE;
    });
    this.conversationStore.getConversationInfo(this.conversationID, completion);
  }
}

export function muteConversationCompat(
  store: ConversationListStore,
  conversationID: string,
  mute: boolean
): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
    const opt: ReceiveMessageOption = mute ? ReceiveMessageOption.NOT_NOTIFY : ReceiveMessageOption.RECEIVE;
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
      reject(new Error(`setReceiveMessageOpt failed: code=${code}, desc=${desc}`));
    });
    store.setReceiveMessageOpt(conversationID, opt, completion);
  });
}

export function pinConversationCompat(
  store: ConversationListStore,
  conversationID: string,
  pin: boolean
): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
      reject(new Error(`pinConversation failed: code=${code}, desc=${desc}`));
    });
    store.pinConversation(conversationID, pin, completion);
  });
}

export function clearConversationMessagesCompat(
  store: ConversationListStore,
  conversationID: string
): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
      reject(new Error(`clearConversationMessages failed: code=${code}, desc=${desc}`));
    });
    store.clearConversationMessages(conversationID, completion);
  });
}

export function deleteConversationCompat(
  store: ConversationListStore,
  conversationID: string
): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
const completion = new CompletionHandlerAdapter(() => {
        resolve();
      }, (code: number, desc: string) => {
      reject(new Error(`deleteConversation failed: code=${code}, desc=${desc}`));
    });
    store.deleteConversation(conversationID, completion);
  });
}

export function fetchConversationInfoCompat(
  store: ConversationListStore,
  conversationID: string
): Promise<ConversationInfo | null> {
  return new Promise<ConversationInfo | null>((resolve: (info: ConversationInfo | null) => void, reject: (e: Error) => void) => {
    const completion = new GetConversationInfoCompletionHandlerAdapter((info: ConversationInfo) => {
      resolve(info);
    }, (code: number, desc: string) => {
      reject(new Error(`getConversationInfo failed: code=${code}, desc=${desc}`));
    });
    store.getConversationInfo(conversationID, completion);
  });
}