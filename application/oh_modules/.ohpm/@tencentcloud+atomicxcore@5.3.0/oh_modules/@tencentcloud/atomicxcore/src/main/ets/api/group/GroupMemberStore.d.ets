import { CompletionHandler } from '../Define';
@Observed
export declare class GroupMember {
    userID: string;
    nickname?: string;
    friendRemark?: string;
    nameCard?: string;
    avatarURL?: string;
    role: GroupMemberRole;
    muteUntil: number;
    constructor(userID?: string);
    get isMuted(): boolean;
}
export declare enum GroupMemberFilterRole {
    ALL = 0,
    MEMBER = 200,
    ADMIN = 300,
    OWNER = 400
}
export declare namespace GroupMemberFilterRole {
    function parse(value: number): GroupMemberFilterRole;
}
export declare enum GroupMemberRole {
    MEMBER = 200,
    ADMIN = 300,
    OWNER = 400
}
export declare namespace GroupMemberRole {
    function parse(value: number): GroupMemberRole;
}
export interface GetMemberInfoCompletionHandler {
    onSuccess(memberInfoList: GroupMember[]): void;
    onFailure(code: number, desc: string): void;
}
@Observed
export declare class GroupMemberState {
    memberList: GroupMember[];
    hasMoreMembers: boolean;
}
@Observed
export declare abstract class GroupMemberStore {
    readonly groupID: string;
    protected groupMemberState: GroupMemberState;
    constructor(groupID: string);
    get state(): Readonly<GroupMemberState>;
    static create(groupID: string): GroupMemberStore;
    abstract loadMembers(roleList: GroupMemberFilterRole[], completion?: CompletionHandler): void;
    abstract loadMoreMembers(completion?: CompletionHandler): void;
    abstract getMemberInfo(userIDList: string[], completion: GetMemberInfoCompletionHandler): void;
    abstract addMember(userIDList: string[], completion?: CompletionHandler): void;
    abstract deleteMember(userIDList: string[], completion?: CompletionHandler): void;
    abstract muteMember(userID: string, time: number, completion?: CompletionHandler): void;
    abstract setSelfNameCard(nameCard: string, completion?: CompletionHandler): void;
    abstract setMemberRole(userID: string, role: GroupMemberRole, completion?: CompletionHandler): void;
}
