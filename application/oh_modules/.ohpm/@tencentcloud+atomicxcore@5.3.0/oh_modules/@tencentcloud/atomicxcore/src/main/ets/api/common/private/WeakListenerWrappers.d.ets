import { V2TIMAdvancedMsgListener, V2TIMConversation, V2TIMConversationListFilter, V2TIMConversationListener, V2TIMFriendApplication, V2TIMFriendInfo, V2TIMFriendshipListener, V2TIMGroupChangeInfo, V2TIMGroupListener, V2TIMGroupMemberChangeInfo, V2TIMGroupMemberInfo, V2TIMMessage, V2TIMMessageExtension, V2TIMMessageReactionChangeInfo, V2TIMMessageReceipt, V2TIMOfficialAccountInfo, V2TIMReceiveMessageOptInfo, V2TIMSDKListener, V2TIMTopicInfo, V2TIMUserFullInfo, V2TIMUserStatus } from '@tencentcloud/imsdk';
export declare class WeakConversationListenerWrapper {
    private targetRef;
    constructor(target: V2TIMConversationListener);
    onConversationChanged: (conversationList: V2TIMConversation[]) => void;
    onSyncServerStart: () => void;
    onSyncServerFinish: () => void;
    onSyncServerFailed: () => void;
    onNewConversation: (conversationList: V2TIMConversation[]) => void;
    onConversationDeleted: (conversationIDList: string[]) => void;
    onTotalUnreadMessageCountChanged: (totalUnreadCount: number) => void;
    onUnreadMessageCountChangedByFilter: (filter: V2TIMConversationListFilter, totalUnreadCount: number) => void;
    onConversationGroupCreated: (groupName: string, conversationList: V2TIMConversation[]) => void;
    onConversationGroupDeleted: (groupName: string) => void;
    onConversationGroupNameChanged: (oldName: string, newName: string) => void;
    onConversationsAddedToGroup: (groupName: string, conversationList: V2TIMConversation[]) => void;
    onConversationsDeletedFromGroup: (groupName: string, conversationList: V2TIMConversation[], reason: number) => void;
    private handleEvent;
}
export declare class WeakFriendshipListenerWrapper {
    private targetRef;
    constructor(target: V2TIMFriendshipListener);
    onFriendListAdded: (userList: V2TIMFriendInfo[]) => void;
    onFriendListDeleted: (userIDList: string[]) => void;
    onFriendInfoChanged: (userList: V2TIMFriendInfo[]) => void;
    onBlackListAdded: (userList: V2TIMFriendInfo[]) => void;
    onBlackListDeleted: (userIDList: string[]) => void;
    onFriendApplicationListAdded: (applicationList: V2TIMFriendApplication[]) => void;
    onFriendApplicationListDeleted: (userIDList: string[]) => void;
    onFriendApplicationListRead: () => void;
    onFriendGroupCreated: (groupName: string, friendInfoList: V2TIMFriendInfo[]) => void;
    onFriendGroupDeleted: (groupNameList: string[]) => void;
    onFriendGroupNameChanged: (oldGroupName: string, newGroupName: string) => void;
    onFriendsAddedToGroup: (groupName: string, friendInfoList: V2TIMFriendInfo[]) => void;
    onFriendsDeletedFromGroup: (groupName: string, friendIDList: string[]) => void;
    onOfficialAccountSubscribed: (officialAccountInfo: V2TIMOfficialAccountInfo) => void;
    onOfficialAccountUnsubscribed: (officialAccountID: string) => void;
    onOfficialAccountDeleted: (officialAccountID: string) => void;
    onOfficialAccountInfoChanged: (officialAccountInfo: V2TIMOfficialAccountInfo) => void;
    onMyFollowingListChanged: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => void;
    onMyFollowersListChanged: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => void;
    onMutualFollowersListChanged: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => void;
    private handleEvent;
}
export declare class WeakGroupListenerWrapper {
    private targetRef;
    constructor(target: V2TIMGroupListener);
    onGroupInfoChanged: (groupID: string, changeInfos: V2TIMGroupChangeInfo[]) => void;
    onMemberEnter: (groupID: string, memberList: V2TIMGroupMemberInfo[]) => void;
    onMemberLeave: (groupID: string, member: V2TIMGroupMemberInfo) => void;
    onMemberInvited: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    onMemberKicked: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    onMemberInfoChanged: (groupID: string, v2TIMGroupMemberChangeInfoList: V2TIMGroupMemberChangeInfo[]) => void;
    onAllGroupMembersMuted: (groupID: string, isMute: boolean) => void;
    onMemberMarkChanged: (groupID: string, memberIDList: string[], markType: number, enableMark: boolean) => void;
    onGroupCreated: (groupID: string) => void;
    onGroupRecycled: (groupID: string, opUser: V2TIMGroupMemberInfo) => void;
    onApplicationProcessed: (groupID: string, opUser: V2TIMGroupMemberInfo, isAgreeJoin: boolean, opReason: string) => void;
    onGrantAdministrator: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    onRevokeAdministrator: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    onReceiveJoinApplication: (groupID: string, member: V2TIMGroupMemberInfo, opReason: string) => void;
    onQuitFromGroup: (groupID: string) => void;
    onGroupDismissed: (groupID: string, opUser: V2TIMGroupMemberInfo) => void;
    onReceiveRESTCustomData: (groupID: string, customData: ArrayBuffer) => void;
    onGroupAttributeChanged: (groupID: string, groupAttributeMap: Map<string, string>) => void;
    onTopicCreated: (groupID: string, topicID: string) => void;
    onTopicDeleted: (groupID: string, topicIDList: string[]) => void;
    onTopicChanged: (groupID: string, topicInfo: V2TIMTopicInfo) => void;
    onGroupCounterChanged: (groupID: string, key: string, newValue: number) => void;
    private handleEvent;
}
export declare class WeakAdvancedMsgListenerWrapper {
    private targetRef;
    constructor(target: V2TIMAdvancedMsgListener);
    onRecvNewMessage: (msg: V2TIMMessage) => void;
    onRecvC2CReadReceipt: (receiptList: V2TIMMessageReceipt[]) => void;
    onRecvMessageRevoked: (msgID: string, operateUser: V2TIMUserFullInfo, reason?: string) => void;
    onRecvMessageModified: (msg: V2TIMMessage) => void;
    onRecvMessageReadReceipts: (receiptList: V2TIMMessageReceipt[]) => void;
    onRecvMessageReactionsChanged: (changeList: V2TIMMessageReactionChangeInfo[]) => void;
    onRecvMessageExtensionsChanged: (msgID: string, extensions: V2TIMMessageExtension[]) => void;
    onRecvMessageExtensionsDeleted: (msgID: string, extensionKeys: string[]) => void;
    onGroupMessagePinned: (groupID: string, message: V2TIMMessage, isPinned: Boolean, opUser: V2TIMGroupMemberInfo) => void;
    private handleEvent;
}
export declare class WeakSDKListenerWrapper {
    private targetRef;
    constructor(target: V2TIMSDKListener);
    onConnecting: () => void;
    onConnectSuccess: () => void;
    onConnectFailed: (code: number, message: string) => void;
    onKickedOffline: () => void;
    onUserSigExpired: () => void;
    onSelfInfoUpdated: (info: V2TIMUserFullInfo) => void;
    onUserStatusChanged: (userStatusList: V2TIMUserStatus[]) => void;
    onUserInfoChanged: (userInfoList: V2TIMUserFullInfo[]) => void;
    onAllReceiveMessageOptChanged: (receiveMessageOptInfo: V2TIMReceiveMessageOptInfo) => void;
    onExperimentalNotify: (key: string, param: Object) => void;
    private handleEvent;
}
