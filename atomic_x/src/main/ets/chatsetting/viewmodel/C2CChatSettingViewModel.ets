import { ContactInfo, ContactStore } from '@tencentcloud/atomicxcore'
import { ConversationInfo, ConversationListStore, ReceiveMessageOption } from '@tencentcloud/atomicxcore'
import { CompletionHandler } from '@tencentcloud/atomicxcore'
import {
  CompletionHandlerAdapter,
  GetContactInfoCompletionHandlerAdapter,
  GetConversationInfoCompletionHandlerAdapter
} from '../../basecomponent/utils/CompletionHandlers'

@Observed
export class C2CChatSettingViewModel {
  readonly userID: string
  readonly conversationID: string
  isLoading: boolean = false
  chatBackgroundImageUri: string | null = null

  private readonly _contactStore: ContactStore = ContactStore.shared
  private readonly _conversationListStore: ConversationListStore = ConversationListStore.create()

  constructor(userID: string) {
    this.userID = userID
    this.conversationID = `c2c_${userID}`

    this._contactStore.loadBlackList()
    this._contactStore.loadFriends()
    this._conversationListStore.getConversationInfo(this.conversationID, new GetConversationInfoCompletionHandlerAdapter())
  }

  get contactStore(): ContactStore {
    return this._contactStore
  }

  get conversationListStore(): ConversationListStore {
    return this._conversationListStore
  }

  private get userInfo(): ContactInfo | undefined {
    return this._contactStore.state.friendList.find((it: ContactInfo) => it.userID === this.userID)
  }

  private get conversationInfo(): ConversationInfo | null {
    const list = this._conversationListStore.state.conversationList
    const index = list.getIndex(this.conversationID)
    if (index < 0) {
      return null
    }
    return list.getData(index)
  }

  get nickname(): string {
    return this.userInfo?.nickname ?? ''
  }

  get avatar(): string {
    return this.userInfo?.avatarURL ?? ''
  }

  get aboutMe(): string {
    return this.userInfo?.aboutMe ?? ''
  }

  get friendRemark(): string {
    return this.userInfo?.friendRemark ?? ''
  }

  get isNotDisturb(): boolean {
    return this.conversationInfo?.receiveOption === ReceiveMessageOption.NOT_NOTIFY
  }

  get isPinned(): boolean {
    return this.conversationInfo?.isPinned ?? false
  }

  get isInBlacklist(): boolean {
    return this._contactStore.state.blackList.some((it: ContactInfo) => it.userID === this.userID)
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

  toggleBlacklist(): void {
    if (this.isInBlacklist) {
      this._contactStore.removeFromBlacklist(this.userID, this.emptyHandler())
    } else {
      this._contactStore.addToBlacklist(this.userID, this.emptyHandler())
    }
  }

  setFriendRemark(remark: string): void {
    this._contactStore.setFriendRemark(this.userID, remark, this.emptyHandler())
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

  deleteFriend(onSuccess?: () => void, onFailure?: (code: number, desc: string) => void): void {
    this._contactStore.deleteFriend(this.userID, new CompletionHandlerAdapter(() => {
      this._conversationListStore.deleteConversation(this.conversationID)
      onSuccess?.()
    }, (code: number, desc: string) => {
      onFailure?.(code, desc)
    }))
  }

  private emptyHandler(): CompletionHandler {
    return new CompletionHandlerAdapter()
  }
}

@Observed
export class C2CSettingState {
  nickname: string = '';
  avatarURL: string = '';
  signature: string = '';
  remark: string = '';
  isNotDisturb: boolean = false;
  isPinned: boolean = false;
  isContact: boolean = false;
  isInBlacklist: boolean = false;
}

@Observed
export class C2CSettingStore {
  readonly userID: string = '';
  state: C2CSettingState = new C2CSettingState();
  private contactStore: ContactStore = ContactStore.shared;
  private conversationStore: ConversationListStore = ConversationListStore.create();
  private conversationID: string = '';

  private constructor(userID: string) {
    this.userID = userID;
    this.conversationID = `c2c_${userID}`;
  }

  static create(userID: string): C2CSettingStore {
    return new C2CSettingStore(userID);
  }

  fetchUserInfo(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new GetContactInfoCompletionHandlerAdapter((contactInfoList: ContactInfo[]) => {
        const info: ContactInfo | undefined = contactInfoList && contactInfoList.length > 0 ? contactInfoList[0] : undefined;
        if (info) {
          this.state.nickname = info.nickname || '';
          this.state.avatarURL = info.avatarURL || '';
          this.state.signature = info.aboutMe || '';
          this.state.remark = info.friendRemark || '';
          this.state.isContact = info.isFriend;
          this.state.isInBlacklist = info.isInBlacklist;
        }
        this.fetchConversationInfo();
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`getContactInfo failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.getContactInfo([this.userID], completion);
    });
  }

  checkBlacklistStatus(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        const list: ContactInfo[] = this.contactStore.state.blackList;
        this.state.isInBlacklist = list.some((item: ContactInfo) => item.userID === this.userID);
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`loadBlackList failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.loadBlackList(completion);
    });
  }

  setUserRemark(remark: string): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.remark = remark;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`setFriendRemark failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.setFriendRemark(this.userID, remark, completion);
    });
  }

  addToBlacklist(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.isInBlacklist = true;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`addToBlacklist failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.addToBlacklist(this.userID, completion);
    });
  }

  removeFromBlacklist(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.isInBlacklist = false;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`removeFromBlacklist failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.removeFromBlacklist(this.userID, completion);
    });
  }

  deleteFriend(): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      const completion = new CompletionHandlerAdapter(() => {
        this.state.isContact = false;
        resolve();
      }, (code: number, desc: string) => {
        reject(new Error(`deleteFriend failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.deleteFriend(this.userID, completion);
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