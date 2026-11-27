import { CompletionHandler } from '../Define';
import { V2TIMFriendApplication } from '@tencentcloud/imsdk';
export declare enum ContactOnlineStatus {
    UNKNOWN = 0,
    ONLINE = 1,
    OFFLINE = 2
}
export declare namespace ContactOnlineStatus {
    function parse(value: number): ContactOnlineStatus;
}
export declare enum FriendApplicationType {
    RECEIVED = 1,
    SENT = 2,
    BOTH = 3
}
export declare namespace FriendApplicationType {
    function parse(value: number): FriendApplicationType;
}
@Observed
export declare class ContactInfo {
    userID: string;
    avatarURL?: string;
    nickname?: string;
    aboutMe?: string;
    onlineStatus: ContactOnlineStatus;
    isInBlacklist: boolean;
    isFriend: boolean;
    friendRemark?: string;
    constructor(userID?: string);
}
@Observed
export declare class FriendApplicationInfo {
    userID: string;
    avatarURL?: string;
    title?: string;
    source?: string;
    type: FriendApplicationType;
    addWording?: string;
    rawApplication?: V2TIMFriendApplication;
    constructor(userID: string, type: FriendApplicationType);
}
export interface GetContactInfoCompletionHandler {
    onSuccess(contactInfoList: ContactInfo[]): void;
    onFailure(code: number, desc: string): void;
}
@Observed
export declare class ContactState {
    friendList: ContactInfo[];
    friendApplicationList: FriendApplicationInfo[];
    friendApplicationUnreadCount: number;
    blackList: ContactInfo[];
}
@Observed
export declare abstract class ContactStore {
    protected contactState: ContactState;
    private static instance;
    static get shared(): ContactStore;
    get state(): Readonly<ContactState>;
    abstract loadFriends(completion?: CompletionHandler): void;
    abstract addFriend(userID: string, remark?: string, addWording?: string, completion?: CompletionHandler): void;
    abstract deleteFriend(userID: string, completion?: CompletionHandler): void;
    abstract setFriendRemark(userID: string, remark: string, completion?: CompletionHandler): void;
    abstract getContactInfo(userIDList: string[], completion: GetContactInfoCompletionHandler): void;
    abstract loadBlackList(completion?: CompletionHandler): void;
    abstract addToBlacklist(userID: string, completion?: CompletionHandler): void;
    abstract removeFromBlacklist(userID: string, completion?: CompletionHandler): void;
    abstract loadFriendApplications(completion?: CompletionHandler): void;
    abstract acceptFriendApplication(info: FriendApplicationInfo, completion?: CompletionHandler): void;
    abstract refuseFriendApplication(info: FriendApplicationInfo, completion?: CompletionHandler): void;
    abstract clearFriendApplicationUnreadCount(completion?: CompletionHandler): void;
}
