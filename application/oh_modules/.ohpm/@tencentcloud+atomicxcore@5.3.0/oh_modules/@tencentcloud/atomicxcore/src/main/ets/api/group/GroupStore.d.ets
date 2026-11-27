import { CompletionHandler } from '../Define';
import { EventEmitter } from '../common/EventEmitter';
import { V2TIMGroupApplication } from '@tencentcloud/imsdk';
import { GroupMember, GroupMemberRole } from './GroupMemberStore';
export declare enum GroupType {
    WORK = "Work",
    PUBLIC_GROUP = "Public",
    MEETING = "Meeting",
    AV_CHAT_ROOM = "AVChatRoom",
    COMMUNITY = "Community"
}
export declare namespace GroupType {
    function parse(value: string): GroupType;
}
export declare enum GroupJoinOption {
    FORBID = 0,
    AUTH = 1,
    ANY = 2
}
export declare namespace GroupJoinOption {
    function parse(value: number): GroupJoinOption;
}
export declare enum GroupInviteOption {
    FORBID = 0,
    AUTH = 1,
    ANY = 2
}
export declare namespace GroupInviteOption {
    function parse(value: number): GroupInviteOption;
}
export declare enum GroupApplicationType {
    JOIN_APPROVED_BY_ADMIN = 0,
    INVITE_APPROVED_BY_INVITEE = 1,
    INVITE_APPROVED_BY_ADMIN = 2
}
export declare namespace GroupApplicationType {
    function parse(value: number): GroupApplicationType;
}
export declare enum GroupApplicationHandledStatus {
    UNHANDLED = 0,
    BY_OTHER = 1,
    BY_MYSELF = 2
}
export declare namespace GroupApplicationHandledStatus {
    function parse(value: number): GroupApplicationHandledStatus;
}
export declare enum GroupApplicationHandledResult {
    REFUSED = 0,
    AGREED = 1
}
export declare namespace GroupApplicationHandledResult {
    function parse(value: number): GroupApplicationHandledResult;
}
@Observed
export declare class GroupInfo {
    groupID: string;
    groupName?: string;
    avatarURL?: string;
    groupType?: GroupType;
    notification?: string;
    joinOption?: GroupJoinOption;
    inviteOption?: GroupInviteOption;
    memberCount?: number;
    isAllMuted?: boolean;
    groupOwner?: string;
    selfRole?: GroupMemberRole;
    groupAttributes?: Map<string, string>;
    constructor(groupID?: string);
}
@Observed
export declare class GroupApplicationInfo {
    applicationID: string;
    groupID: string;
    fromUser?: string;
    fromUserNickname?: string;
    fromUserAvatarURL?: string;
    toUser?: string;
    addTime: number;
    requestMsg?: string;
    handledMsg?: string;
    type: GroupApplicationType;
    handledStatus?: GroupApplicationHandledStatus;
    handledResult?: GroupApplicationHandledResult;
    rawApplication?: V2TIMGroupApplication;
    constructor(applicationID: string, groupID: string, type: GroupApplicationType);
}
export declare class GroupCreateParams {
    groupType: GroupType;
    groupName: string;
    groupID?: string;
    avatarURL?: string;
    memberList?: string[];
    constructor(groupName: string, groupType?: GroupType, groupID?: string, avatarURL?: string, memberList?: string[]);
}
export interface GetGroupInfoCompletionHandler {
    onSuccess(groupInfo: GroupInfo): void;
    onFailure(code: number, desc: string): void;
}
export interface CreateGroupCompletionHandler {
    onSuccess(groupID: string): void;
    onFailure(code: number, desc: string): void;
}
export declare abstract class GroupEvent {
}
export declare namespace GroupEvent {
    class OnGroupDismissed extends GroupEvent {
        groupID: string;
        opUser: GroupMember;
        constructor(groupID: string, opUser: GroupMember);
    }
    class OnKickedFromGroup extends GroupEvent {
        groupID: string;
        opUser: GroupMember;
        constructor(groupID: string, opUser: GroupMember);
    }
    class OnQuitFromGroup extends GroupEvent {
        groupID: string;
        constructor(groupID: string);
    }
    class OnReceiveJoinApplication extends GroupEvent {
        groupID: string;
        member: GroupMember;
        opReason?: string;
        constructor(groupID: string, member: GroupMember, opReason?: string);
    }
    class OnApplicationProcessed extends GroupEvent {
        groupID: string;
        opUser: GroupMember;
        opResult: boolean;
        opReason?: string;
        constructor(groupID: string, opUser: GroupMember, opResult: boolean, opReason?: string);
    }
}
@Observed
export declare class GroupState {
    joinedGroupList: GroupInfo[];
    applicationList: GroupApplicationInfo[];
    unreadApplicationCount: number;
}
@Observed
export declare abstract class GroupStore {
    protected groupState: GroupState;
    protected groupEventEmitter: EventEmitter<GroupEvent>;
    private static instance;
    static get shared(): GroupStore;
    get state(): Readonly<GroupState>;
    get groupEventFlow(): EventEmitter<GroupEvent>;
    abstract loadJoinedGroups(completion?: CompletionHandler): void;
    abstract loadGroupAttributes(groupID: string, keys?: string[], completion?: CompletionHandler): void;
    abstract getGroupInfo(groupID: string, completion: GetGroupInfoCompletionHandler): void;
    abstract createGroup(params: GroupCreateParams, completion: CreateGroupCompletionHandler): void;
    abstract joinGroup(groupID: string, message?: string, completion?: CompletionHandler): void;
    abstract quitGroup(groupID: string, completion?: CompletionHandler): void;
    abstract dismissGroup(groupID: string, completion?: CompletionHandler): void;
    abstract loadApplications(completion?: CompletionHandler): void;
    abstract acceptApplication(info: GroupApplicationInfo, completion?: CompletionHandler): void;
    abstract refuseApplication(info: GroupApplicationInfo, completion?: CompletionHandler): void;
    abstract clearApplicationUnreadCount(completion?: CompletionHandler): void;
    abstract changeOwner(groupID: string, newOwnerID: string, completion?: CompletionHandler): void;
    abstract updateProfile(groupInfo: GroupInfo, completion?: CompletionHandler): void;
    abstract setJoinOption(groupID: string, option: GroupJoinOption, completion?: CompletionHandler): void;
    abstract setInviteOption(groupID: string, option: GroupInviteOption, completion?: CompletionHandler): void;
    abstract muteAllMembers(groupID: string, isMuted: boolean, completion?: CompletionHandler): void;
}
