import { MessageInfo, MessageType } from '../message/MessageListStore';
import { UserProfile, Gender } from '../login/LoginStore';
import { GroupMember } from '../group/GroupMemberStore';
import { GroupType, GroupJoinOption, GroupInviteOption } from '../group/GroupStore';
import { CompletionHandler } from '../Define';
import BasicData from '../common/BasicData';
import BasicDataSource from '../common/BasicDataSource';
export declare enum KeywordListMatchMode {
    OR = 0,
    AND = 1
}
export declare namespace KeywordListMatchMode {
    function parse(value: number): KeywordListMatchMode;
}
export declare enum SearchType {
    FRIEND = 0,
    GROUP = 1,
    GROUP_MEMBER = 2,
    MESSAGE = 3
}
export declare namespace SearchType {
    function parse(value: number): SearchType | undefined;
}
export declare class UserSearchFilter {
    gender: Gender;
    minBirthday: number;
    maxBirthday?: number;
}
export declare class GroupMemberSearchFilter {
    groupIDList: string[];
}
export declare class MessageSearchFilter {
    conversationID?: string;
    searchTimePosition: number;
    searchTimePeriod: number;
    senderUserIDList?: string[];
    messageTypeList?: MessageType[];
}
export declare class SearchOption {
    keywordListMatchMode: KeywordListMatchMode;
    searchScope: SearchType[];
    pageSize: number;
    userFilter?: UserSearchFilter;
    groupMemberFilter?: GroupMemberSearchFilter;
    messageFilter?: MessageSearchFilter;
}
@Observed
export declare class FriendSearchInfo extends BasicData {
    userID: string;
    friendRemark?: string;
    friendAddTime: number;
    friendCustomInfo?: Map<string, ArrayBuffer>;
    userInfo: UserProfile;
    constructor(userID: string, userInfo: UserProfile);
}
@Observed
export declare class GroupSearchInfo extends BasicData {
    groupID: string;
    groupType: GroupType;
    groupName?: string;
    memberCount: number;
    groupAvatarURL?: string;
    introduction?: string;
    joinGroupApprovalType: GroupJoinOption;
    inviteToGroupApprovalType: GroupInviteOption;
    constructor(groupID?: string, groupName?: string, groupAvatarURL?: string, introduction?: string);
}
@Observed
export declare class MessageSearchResultItem extends BasicData {
    conversationID: string;
    conversationShowName: string;
    conversationAvatarURL?: string;
    messageCount: number;
    messageList: MessageInfo[];
    constructor(conversationID?: string, conversationShowName?: string, conversationAvatarURL?: string, messageCount?: number, messageList?: MessageInfo[]);
}
@Observed
export declare class SearchState {
    userList: UserProfile[];
    userTotalCount: number;
    hasMoreUsers: boolean;
    friendList: BasicDataSource<FriendSearchInfo>;
    friendTotalCount: number;
    hasMoreFriends: boolean;
    groupList: BasicDataSource<GroupSearchInfo>;
    groupTotalCount: number;
    hasMoreGroups: boolean;
    groupMemberList: Map<string, GroupMember[]>;
    groupMemberTotalCount: number;
    hasMoreGroupMembers: boolean;
    messageResults: BasicDataSource<MessageSearchResultItem>;
    messageResultTotalCount: number;
    hasMoreMessageResults: boolean;
}
@Observed
export declare abstract class SearchStore {
    protected searchState: SearchState;
    static create(): SearchStore;
    get state(): Readonly<SearchState>;
    abstract search(keywordList: string[], option?: SearchOption, completion?: CompletionHandler): void;
    abstract searchMore(searchType: SearchType, completion?: CompletionHandler): void;
}
