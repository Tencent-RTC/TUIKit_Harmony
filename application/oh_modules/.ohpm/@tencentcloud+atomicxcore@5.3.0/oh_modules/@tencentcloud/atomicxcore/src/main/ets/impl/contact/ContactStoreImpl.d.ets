import { V2TIMFriendApplication, V2TIMFriendInfo, V2TIMFriendshipListener } from '@tencentcloud/imsdk';
import { CompletionHandler } from '../../api/Define';
import { ContactStore, FriendApplicationInfo, GetContactInfoCompletionHandler } from '../../api/contact/ContactStore';
export declare enum ContactNotifyKey {
    FRIEND_DELETED = "FriendDeleted"
}
@Observed
export declare class ContactStoreImpl extends ContactStore implements V2TIMFriendshipListener {
    private weakFriendshipListener;
    private isFriendshipListenerRegistered;
    private loginEventSubscription?;
    private lastLoginStatus;
    constructor();
    private observeLoginStatus;
    private registerFriendshipListenerIfNeeded;
    private unregisterFriendshipListenerIfNeeded;
    private resetAfterLogout;
    loadFriends(completion?: CompletionHandler): void;
    addFriend(userID: string, remark?: string, addWording?: string, completion?: CompletionHandler): void;
    deleteFriend(userID: string, completion?: CompletionHandler): void;
    setFriendRemark(userID: string, remark: string, completion?: CompletionHandler): void;
    getContactInfo(userIDList: string[], completion: GetContactInfoCompletionHandler): void;
    loadBlackList(completion?: CompletionHandler): void;
    private getBlackListWithRetry;
    addToBlacklist(userID: string, completion?: CompletionHandler): void;
    removeFromBlacklist(userID: string, completion?: CompletionHandler): void;
    loadFriendApplications(completion?: CompletionHandler): void;
    acceptFriendApplication(info: FriendApplicationInfo, completion?: CompletionHandler): void;
    refuseFriendApplication(info: FriendApplicationInfo, completion?: CompletionHandler): void;
    clearFriendApplicationUnreadCount(completion?: CompletionHandler): void;
    onFriendListAdded(userList: V2TIMFriendInfo[]): void;
    onFriendListDeleted(userIDList: string[]): void;
    onFriendInfoChanged(userList: V2TIMFriendInfo[]): void;
    onBlackListAdded(userList: V2TIMFriendInfo[]): void;
    onBlackListDeleted(userIDList: string[]): void;
    onFriendApplicationListAdded(applicationList: V2TIMFriendApplication[]): void;
    onFriendApplicationListDeleted(userIDList: string[]): void;
    onFriendApplicationListRead(): void;
    private convertToContactInfo;
    private convertToFriendApplicationList;
    private convertToFriendApplication;
    private mergeFriendsIntoFriendList;
    private completeFriendApplicationOperation;
}
