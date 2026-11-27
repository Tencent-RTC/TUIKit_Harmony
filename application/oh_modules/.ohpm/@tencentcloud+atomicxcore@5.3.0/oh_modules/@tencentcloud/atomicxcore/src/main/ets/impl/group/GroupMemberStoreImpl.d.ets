import { V2TIMFriendInfo, V2TIMFriendshipListener, V2TIMGroupChangeInfo, V2TIMGroupListener, V2TIMGroupMemberChangeInfo, V2TIMGroupMemberInfo } from '@tencentcloud/imsdk';
import { CompletionHandler } from '../../api/Define';
import { GetMemberInfoCompletionHandler, GroupMemberFilterRole, GroupMemberRole, GroupMemberStore } from '../../api/group/GroupMemberStore';
@Observed
export declare class GroupMemberStoreImpl extends GroupMemberStore implements V2TIMGroupListener, V2TIMFriendshipListener {
    private memberFetchNextSeq;
    private weakGroupListener;
    private weakFriendshipListener;
    constructor(groupID: string);
    private get currentUserID();
    loadMembers(roleList: GroupMemberFilterRole[], completion?: CompletionHandler): void;
    loadMoreMembers(completion?: CompletionHandler): void;
    getMemberInfo(userIDList: string[], completion: GetMemberInfoCompletionHandler): void;
    addMember(userIDList: string[], completion?: CompletionHandler): void;
    deleteMember(userIDList: string[], completion?: CompletionHandler): void;
    muteMember(userID: string, time: number, completion?: CompletionHandler): void;
    setSelfNameCard(nameCard: string, completion?: CompletionHandler): void;
    setMemberRole(userID: string, role: GroupMemberRole, completion?: CompletionHandler): void;
    onGroupInfoChanged(groupID: string, changeInfos: V2TIMGroupChangeInfo[]): void;
    onMemberEnter(groupID: string, memberList: V2TIMGroupMemberInfo[]): void;
    onMemberLeave(groupID: string, member: V2TIMGroupMemberInfo): void;
    onMemberInvited(groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]): void;
    onMemberKicked(groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]): void;
    onMemberInfoChanged(groupID: string, changeInfoList: V2TIMGroupMemberChangeInfo[]): void;
    onGrantAdministrator(groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]): void;
    onRevokeAdministrator(groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]): void;
    onFriendInfoChanged(infoList: V2TIMFriendInfo[]): void;
    private fetchMembersInternal;
    private normalizeRoleList;
    private convertToMember;
    private convertBasicMemberInfo;
    private copyMember;
}
