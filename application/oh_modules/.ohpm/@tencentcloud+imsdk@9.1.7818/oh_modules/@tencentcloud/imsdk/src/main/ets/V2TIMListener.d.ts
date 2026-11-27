/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMConversation, V2TIMConversationListFilter, V2TIMFriendApplication, V2TIMFriendInfo, V2TIMGroupChangeInfo, V2TIMGroupMemberChangeInfo, V2TIMGroupMemberInfo, V2TIMLogLevel, V2TIMMessage, V2TIMMessageExtension, V2TIMMessageReactionChangeInfo, V2TIMMessageReceipt, V2TIMReceiveMessageOptInfo, V2TIMTopicInfo, V2TIMUserFullInfo, V2TIMUserInfo, V2TIMUserStatus, V2TIMOfficialAccountInfo, V2TIMGroupMemberFullInfo, V2TIMPermissionGroupInfo, V2TIMTTSResponse } from "../../../Index";
/**
 * IMSDK 全局监听类
 */
/**
 * （一）SDK 事件监听类
 */
export interface V2TIMSDKListener {
    /**
     * SDK 正在连接到腾讯云服务器
     */
    onConnecting?: () => void;
    /**
     * SDK 已经成功连接到腾讯云服务器
     */
    onConnectSuccess?: () => void;
    /**
     * SDK 连接腾讯云服务器失败
     */
    onConnectFailed?: (code: number, message: string) => void;
    /**
     * 当前用户被踢下线，此时可以 UI 提示用户，并再次调用 V2TIMManager 的 login() 函数重新登录。
     */
    onKickedOffline?: () => void;
    /**
     * 在线时票据过期：此时您需要生成新的 userSig 并再次调用 V2TIMManager 的 login() 函数重新登录。
     */
    onUserSigExpired?: () => void;
    /**
     * 登录用户的资料发生了更新
     *
     */
    onSelfInfoUpdated?: (info: V2TIMUserFullInfo) => void;
    /**
     * 用户状态变更通知
     *
     * @note 收到通知的情况：
     * 1. 订阅过的用户发生了状态变更（包括在线状态和自定义状态），会触发该回调
     * 2. 在 IM 控制台打开了好友状态通知开关，即使未主动订阅，当好友状态发生变更时，也会触发该回调
     * 3. 同一个账号多设备登录，当其中一台设备修改了自定义状态，所有设备都会收到该回调
     */
    onUserStatusChanged?: (userStatusList: V2TIMUserStatus[]) => void;
    /**
     * 用户资料变更通知
     *
     * @note
     * 仅当通过 SubscribeUserInfo 成功订阅的用户（仅限非好友用户）的资料发生变更时，才会激活此回调函数
     */
    onUserInfoChanged?: (userinfoList: V2TIMUserFullInfo[]) => void;
    /**
     * 全局消息接收选项变更通知
     */
    onAllReceiveMessageOptChanged?: (receiveMessageOptInfo: V2TIMReceiveMessageOptInfo) => void;
    /**
     * 实验性事件通知
     */
    onExperimentalNotify?: (key: string, param: string | Object) => void;
}
/**
 * （二）基本消息（文本消息和自定义消息）的事件监听类
 */
export interface V2TIMSimpleMsgListener {
    /**
     * 收到 C2C 文本消息
     *
     * @param msgID 消息唯一标识
     * @param sender 发送方信息
     * @param text 发送内容
     */
    onRecvC2CTextMessage?: (msgID: string, sender: V2TIMUserInfo, text: string) => void;
    /**
     * 收到 C2C 自定义（信令）消息
     *
     * @param msgID 消息唯一标识
     * @param sender 发送方信息
     * @param customData 发送内容
     */
    onRecvC2CCustomMessage?: (msgID: string, sender: V2TIMUserInfo, customData: ArrayBuffer) => void;
    /**
     * 收到群文本消息
     *
     * @param msgID 消息唯一标识
     * @param groupID 群 ID
     * @param sender 发送方群成员信息
     * @param text 发送内容
     */
    onRecvGroupTextMessage?: (msgID: string, groupID: string, sender: V2TIMGroupMemberFullInfo, text: string) => void;
    /**
     * 收到群自定义（信令）消息
     *
     * @param msgID 消息唯一标识
     * @param groupID 群 ID
     * @param sender 发送方群成员信息
     * @param customData 发送内容
     */
    onRecvGroupCustomMessage?: (msgID: string, groupID: string, sender: V2TIMGroupMemberFullInfo, customData: ArrayBuffer) => void;
}
/**
 * （三）高级消息监听器
 */
export interface V2TIMAdvancedMsgListener {
    /**
     * 收到新消息
     *
     * @param message 消息
     */
    onRecvNewMessage?: (message: V2TIMMessage) => void;
    /**
     * C2C 对端用户会话已读通知（如果对端用户调用 MarkC2CMessageAsRead 接口，自己会收到该回调，回调只会携带对端 userID和对端已读 timestamp 信息）
     *
     * @param receiptList 已读回执列表
     */
    onRecvC2CReadReceipt?: (receiptList: V2TIMMessageReceipt[]) => void;
    /**
     * 消息已读回执通知
     *
     * @param receiptList 已读回执列表
     */
    onRecvMessageReadReceipts?: (receiptList: V2TIMMessageReceipt[]) => void;
    /**
     * 收到消息撤回的通知
     *
     * @param msgID 消息唯一标识
     * @param operateUser 撤回者信息
     * @param reason 撤回原因
     */
    onRecvMessageRevoked?: (msgID: string, operateUser: V2TIMUserFullInfo, reason: string) => void;
    /**
     * 消息内容被修改
     */
    onRecvMessageModified?: (message: V2TIMMessage) => void;
    /**
     * 消息扩展信息更新
     */
    onRecvMessageExtensionsChanged?: (msgID: string, extensions: V2TIMMessageExtension[]) => void;
    /**
     * 消息扩展信息被删除
     */
    onRecvMessageExtensionsDeleted?: (msgID: string, extensionKeys: string[]) => void;
    /**
     * 消息回应信息更新
     * 该回调是消息 Reaction 的增量回调，只会携带变更的 Reaction 信息。
     * 当变更的 Reaction 信息里的 totalUserCount 字段值为 0 时，表明该 Reaction 已经没有用户在使用，您可以在 UI 上移除该Reaction 的展示。
     */
    onRecvMessageReactionsChanged?: (changeInfos: V2TIMMessageReactionChangeInfo[]) => void;
    /**
     * 置顶群消息列表变更通知
     *
     * @param groupID    群 ID
     * @param message    变更消息
     * @param isPinned   置顶/取消置顶
     * @param opUser     处理人
     *
     * @note
     * - 如果变更类型为取消置顶，message 参数中只有消息的 key，不包含完整的消息体。
     */
    onGroupMessagePinned?: (groupID: string, message: V2TIMMessage, isPinned: Boolean, opUser: V2TIMGroupMemberInfo) => void;
    /**
     * TTS 流式语音合成数据回调
     *
     * @param response TTS 流式响应（含 msgID / audioDataList / isFinished）
     *
     * @note
     * - SDK 会按协议推送顺序回调，业务方需按 audioDataList 顺序拼接播放。
     * - isFinished = true 表示任务终态，SDK 不保证对 stopTTS 清理的其它任务补发终态回调。
     */
    onRecvTTSResponse?: (response: V2TIMTTSResponse) => void;
}
/**
 * （四）群组事件的监听类
 */
export interface V2TIMGroupListener {
    /**
     * 有新成员加入群（该群所有的成员都能收到）
     * 会议群（Meeting）默认无此回调，如需回调，请前往 [控制台](https://console.cloud.tencent.com/im)
     * (功能配置 -> 群组配置 -> 群系统通知配置 -> 群成员变更通知) 主动配置。
     *
     * @param groupID    群 ID
     * @param memberList 加入的成员
     */
    onMemberEnter?: (groupID: string, memberList: V2TIMGroupMemberInfo[]) => void;
    /**
     * 有成员离开群（该群所有的成员都能收到）
     * 会议群（Meeting）默认无此回调，如需回调，请前往 [控制台](https://console.cloud.tencent.com/im)
     * (功能配置 -> 群组配置 -> 群系统通知配置 -> 群成员变更通知) 主动配置。
     *
     * @param groupID 群 ID
     * @param member  离开的成员
     */
    onMemberLeave?: (groupID: string, member: V2TIMGroupMemberInfo) => void;
    /**
     * 某成员被拉入某群（该群所有的成员都能收到）
     *
     * @param groupID    群 ID
     * @param opUser     处理人
     * @param memberList 被拉进群成员
     */
    onMemberInvited?: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    /**
     * 有成员被踢出某群（该群所有的成员都能收到）
     *
     * @param groupID    群 ID
     * @param opUser     处理人
     * @param memberList 被踢成员
     */
    onMemberKicked?: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    /**
     * 某成员信息发生变更（该群所有的成员都能收到）。
     * @note 会议群（Meeting）和直播群（AVChatRoom）默认无此回调，如需回调，请前往 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 群组配置 -> 群系统通知配置 -> 群成员资料变更通知) 主动配置。
     *
     * @param groupID 群 ID
     * @param v2TIMGroupMemberChangeInfoList 被修改的群成员信息
     */
    onMemberInfoChanged?: (groupID: string, v2TIMGroupMemberChangeInfoList: V2TIMGroupMemberChangeInfo[]) => void;
    /**
     * 群组全体成员被禁言/解除禁言了（该群所有的成员都能收到）
     * 需要提前在 [控制台](https://console.cloud.tencent.com/im) 开启通知开关。开关路径：功能配置 -> 群组配置 -> 群系统通知配置 -> 群资料变更通知 -> 群禁言变更通知。
     * 7.5 及以上版本支持。
     *
     * @param groupID 群 ID
     * @param isMute 禁言或解除禁言
     */
    onAllGroupMembersMuted?: (groupID: string, isMute: boolean) => void;
    /**
     * @hidden
     *
     * 有成员被标记（该群所有的成员都能收到） 仅社群（Community）支持该回调。 7.5 及以上版本支持，需要您购买旗舰版套餐。
     *
     * @param groupID 群 ID
     * @param memberIDList 被操作的群成员 userID 列表
     * @param markType 标记类型
     * @param enableMark true 标记，false 取消标记
     */
    onMemberMarkChanged?: (groupID: string, memberIDList: string[], markType: number, enableMark: boolean) => void;
    /**
     * 创建群（主要用于多端同步）
     *
     * @param groupID 群 ID
     */
    onGroupCreated?: (groupID: string) => void;
    /**
     * 群被解散了（全员能收到）
     *
     * @param groupID 群 ID
     * @param opUser  处理人
     */
    onGroupDismissed?: (groupID: string, opUser: V2TIMGroupMemberInfo) => void;
    /**
     * 群被回收（全员能收到）
     *
     * @param groupID 群 ID
     * @param opUser  处理人
     */
    onGroupRecycled?: (groupID: string, opUser: V2TIMGroupMemberInfo) => void;
    /**
     * 群信息被修改（全员能收到）
     * 以下字段的修改可能会引发该通知 groupName  introduction  notification  faceUrl  owner  allMute  custom
     * 控制指定字段 下发通知/存漫游 请前往 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 群组配置 -> 群系统通知配置 -> 群资料变更通知) 主动配置。
     *
     * @param changeInfos 修改的群信息
     */
    onGroupInfoChanged?: (groupID: string, changeInfos: V2TIMGroupChangeInfo[]) => void;
    /**
     * 收到群属性更新的回调
     *
     * @param groupID           群 ID
     * @param groupAttributeMap 群的所有属性
     */
    onGroupAttributeChanged?: (groupID: string, groupAttributeMap: Map<string, string>) => void;
    /**
     * 某个已加入的群的计数器被修改了（全员能收到）
     *
     * @param groupID  群 ID
     * @param key 当前变更的群计数器的 key
     * @param newValue 变更之后的 value
     */
    onGroupCounterChanged?: (groupID: string, key: string, newValue: number) => void;
    /**
     * 有新的加群请求（只有群主或管理员会收到）
     *
     * @param groupID  群 ID
     * @param member   申请人
     * @param opReason 申请原因
     */
    onReceiveJoinApplication?: (groupID: string, member: V2TIMGroupMemberInfo, opReason: string) => void;
    /**
     * 加群或者邀请加群请求已经被群主或管理员处理了（只有申请人能够收到）
     *
     * @param groupID     群 ID
     * @param opUser      处理人
     * @param isAgreeJoin 是否同意加群
     * @param opReason    处理原因
     */
    onApplicationProcessed?: (groupID: string, opUser: V2TIMGroupMemberInfo, isAgreeJoin: boolean, opReason: string) => void;
    /**
     * 指定管理员身份
     *
     * @param groupID    群 ID
     * @param opUser     处理人
     * @param memberList 被处理的群成员
     */
    onGrantAdministrator?: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    /**
     * 取消管理员身份
     *
     * @param groupID    群 ID
     * @param opUser     处理人
     * @param memberList 被处理的群成员
     */
    onRevokeAdministrator?: (groupID: string, opUser: V2TIMGroupMemberInfo, memberList: V2TIMGroupMemberInfo[]) => void;
    /**
     * 主动退出群组（主要用于多端同步，直播群（AVChatRoom）不支持）
     *
     * @param groupID 群 ID
     */
    onQuitFromGroup?: (groupID: string) => void;
    /**
     * 收到 RESTAPI 下发的自定义系统消息
     *
     * @param groupID    群 ID
     * @param customData 自定义数据
     */
    onReceiveRESTCustomData?: (groupID: string, customData: ArrayBuffer) => void;
    /**
     * 话题创建
     *
     * @param topicID 话题 ID
     */
    onTopicCreated?: (groupID: string, topicID: string) => void;
    /**
     * 话题被删除
     * @param groupID 话题所属的社群 ID
     * @param topicIDList 话题列表
     */
    onTopicDeleted?: (groupID: string, topicIDList: string[]) => void;
    /**
     * 话题更新
     * @param topicInfo 话题信息
     */
    onTopicChanged?: (groupID: string, topicInfo: V2TIMTopicInfo) => void;
}
/**
 * （五）日志监听类
 */
/**
 * 14.1 有日志打印时的回调
 *
 * @param logLevel 日志等级, 参见 V2TIMLogLevel
 * @param logContent 日志内容
 */
export type V2TIMLogListener = (logLevel: V2TIMLogLevel, logContent: string) => void;
/**
 * （六）会话事件的监听类
 */
export interface V2TIMConversationListener {
    /**
     * 同步服务器会话开始，SDK
     * 会在登录成功或者断网重连后自动同步服务器会话，您可以监听这个事件做一些 UI 进度展示操作。
     */
    onSyncServerStart?: () => void;
    /**
     * 同步服务器会话完成，如果会话有变更，会通过 OnNewConversation | OnConversationChanged
     * 回调告知客户
     */
    onSyncServerFinish?: () => void;
    /**
     * 同步服务器会话失败
     */
    onSyncServerFailed?: () => void;
    /**
     * 有新的会话（比如收到一个新同事发来的单聊消息、或者被拉入了一个新的群组中），可以根据会话的
     * orderKey 重新对会话列表做排序
     *
     * @param conversationList 会话列表
     */
    onNewConversation?: (conversationList: V2TIMConversation[]) => void;
    /**
     * 某些会话的关键信息发生变化（未读计数发生变化、最后一条消息被更新等等），可以根据会话的
     * orderKey 重新对会话列表做排序
     *
     * @param conversationList 会话列表
     */
    onConversationChanged?: (conversationList: V2TIMConversation[]) => void;
    /**
     * 会话被删除的通知（7.2 及以上版本支持）
     *
     * @note
     * conversationIDList 表示被删除的会话唯一 ID 列表。C2C 单聊组成方式为: "c2c_userID"：群聊组成方式为: "group_groupID"
     */
    onConversationDeleted?: (conversationIDList: string[]) => void;
    /**
     * 全部会话未读总数变更的通知（5.3.425 及以上版本支持）
     *
     * @note
     * - 当您调用 GetTotalUnreadMessageCount 获取全部会话未读总数以后，任意会话的未读数发生变化时，SDK 都会通过该回调把最新的未读总数通知给您。
     * - 未读总数会减去设置为免打扰的会话的未读数，即消息接收选项设置为
     * V2TIM_NOT_RECEIVE_MESSAGE  or V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE or V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT 的会话。
     */
    onTotalUnreadMessageCountChanged?: (totalUnreadCount: number) => void;
    /**
     * 根据 filter 过滤的未读消息总数变更通知（7.0 及以上版本支持）
     * @note
     * - 您可以调用 SubscribeUnreadMessageCountByFilter 注册监听指定 filter 下的未读总数变化，SDK 通过这个回调把最新的未读总数通知给您。
     * - 您可以注册监听多个不同 filter 下的未读总数变化，这个回调的 filter 参数就是注册监听时指定的 filter，该 filter 携带了 conversationType、conversationGroup 和 markType 三个字段，通过判断这三字段是不是都相同，来区分出不同的 filter。
     * - 未读总数会减去设置为免打扰的会话的未读数，即消息接收选项设置为
     * V2TIM_NOT_RECEIVE_MESSAGE  or V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE or V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT 的会话。
     */
    onUnreadMessageCountChangedByFilter?: (filter: V2TIMConversationListFilter, totalUnreadCount: number) => void;
    /**
     * 会话分组相关通知（从 6.5 版本开始支持）
     */
    /**
     * 会话分组被创建
     */
    onConversationGroupCreated?: (groupName: string, conversationList: V2TIMConversation[]) => void;
    /**
     * 会话分组被删除
     */
    onConversationGroupDeleted?: (groupName: string) => void;
    /**
     * 会话分组名变更
     */
    onConversationGroupNameChanged?: (oldName: string, newName: string) => void;
    /**
     * 会话分组新增会话
     */
    onConversationsAddedToGroup?: (groupName: string, conversationList: V2TIMConversation[]) => void;
    /**
     * 会话分组删除会话
     * @note
     * - reason 表示会话从所在分组删除的原因，其取值有：
     * - 当 reason 为 0 时，表示由用户主动调用 deleteConversationsFromGroup 触发
     * - 当 reason 为 1 时，表示添加到分组的会话数量超过 1000，最早添加进分组的会话被淘汰
     */
    onConversationsDeletedFromGroup?: (groupName: string, conversationList: V2TIMConversation[], reason: number) => void;
}
/**
 * （七）关系链事件的监听类
 */
export interface V2TIMFriendshipListener {
    /**
     * 好友申请新增通知，两种情况会收到这个回调：
     * 1. 自己申请加别人好友
     * 2. 别人申请加自己好友
     */
    onFriendApplicationListAdded?: (applicationList: V2TIMFriendApplication[]) => void;
    /**
     * 好友申请删除通知，四种情况会收到这个回调
     * 1. 调用 DeleteFriendApplication 主动删除好友申请
     * 2. 调用 RefuseFriendApplication 拒绝好友申请
     * 3. 调用 AcceptFriendApplication 同意好友申请且同意类型为 V2TIM_FRIEND_ACCEPT_AGREE 时
     * 4. 申请加别人好友被拒绝
     */
    onFriendApplicationListDeleted?: (userIDList: string[]) => void;
    /**
     * 好友申请已读通知，如果调用 setFriendApplicationRead
     * 设置好友申请列表已读，会收到这个回调（主要用于多端同步）
     */
    onFriendApplicationListRead?: () => void;
    /**
     * 好友新增通知
     */
    onFriendListAdded?: (userIDList: V2TIMFriendInfo[]) => void;
    /**
     * 好友删除通知，，两种情况会收到这个回调：
     * 1. 自己删除好友（单向和双向删除都会收到回调）
     * 2. 好友把自己删除（双向删除会收到）
     */
    onFriendListDeleted?: (userIDList: string[]) => void;
    /**
     * 黑名单新增通知
     */
    onBlackListAdded?: (infoList: V2TIMFriendInfo[]) => void;
    /**
     * 黑名单删除通知
     */
    onBlackListDeleted?: (userIDList: string[]) => void;
    /**
     * 好友资料更新通知
     */
    onFriendInfoChanged?: (infoList: V2TIMFriendInfo[]) => void;
    /**
     * 好友分组被创建
     */
    onFriendGroupCreated?: (groupName: string, friendInfoList: V2TIMFriendInfo[]) => void;
    /**
     * 好友分组被删除
     */
    onFriendGroupDeleted?: (groupNameList: string[]) => void;
    /**
     * 好友分组名变更
     */
    onFriendGroupNameChanged?: (oldGroupName: string, newGroupName: string) => void;
    /**
     * 好友分组新增好友
     */
    onFriendsAddedToGroup?: (groupName: string, friendInfoList: V2TIMFriendInfo[]) => void;
    /**
     * 好友分组删除好友
     */
    onFriendsDeletedFromGroup?: (groupName: string, friendIDList: string[]) => void;
    /**
     * 订阅公众号通知
     * @param officialAccountInfo	订阅的公众号资料
     */
    onOfficialAccountSubscribed?: (officialAccountInfo: V2TIMOfficialAccountInfo) => void;
    /**
     * 取消订阅公众号通知
     * @param officialAccountID	取消订阅的公众号 ID
     */
    onOfficialAccountUnsubscribed?: (officialAccountID: string) => void;
    /**
     * 订阅的公众号被删除通知
     * @param officialAccountID	删除的公众号 ID
     */
    onOfficialAccountDeleted?: (officialAccountID: string) => void;
    /**
     * 订阅的公众号资料更新通知
     */
    onOfficialAccountInfoChanged?: (officialAccountInfo: V2TIMOfficialAccountInfo) => void;
    /**
     * 关注列表变更通知
     */
    onMyFollowingListChanged?: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => void;
    /**
     * 粉丝列表变更通知
     */
    onMyFollowersListChanged?: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => void;
    /**
     * 互关列表变更通知
     */
    OnMutualFollowersListChanged?: (userInfoList: V2TIMUserFullInfo[], isAdd: boolean) => void;
}
/**
 * （八）信令事件监听类
 */
export interface V2TIMSignalingListener {
    /**
     * 收到邀请
     */
    onReceiveNewInvitation?: (inviteID: string, inviter: string, groupID: string, inviteeList: string[], data: string) => void;
    /**
     * 被邀请者接受邀请
     */
    onInviteeAccepted?: (inviteID: string, invitee: string, data: string) => void;
    /**
     * 被邀请者拒绝邀请
     */
    onInviteeRejected?: (inviteID: string, invitee: string, data: string) => void;
    /**
     * 邀请被取消
     */
    onInvitationCancelled?: (inviteID: string, inviter: string, data: string) => void;
    /**
     * 邀请超时
     */
    onInvitationTimeout?: (inviteID: string, inviteeList: string[]) => void;
    /**
     * 邀请被修改（6.7 及其以上版本支持）
     */
    onInvitationModified?: (inviteID: string, data: string) => void;
}
/**
 * （九）社群事件监听类
 */
export interface V2TIMCommunityListener {
    /**
     * 收到邀请
     */
    onCreateTopic?: (groupID: string, TopicID: string) => void;
    /**
     * 被邀请者接受邀请
     */
    onDeleteTopic?: (groupID: string, topicIDList: string[]) => void;
    /**
     * 被邀请者拒绝邀请
     */
    onChangeTopicInfo?: (groupID: string, topicInfo: V2TIMTopicInfo) => void;
    /**
     * 邀请被取消
     */
    onReceiveTopicRESTCustomData?: (topicID: string, customData: ArrayBuffer) => void;
    /**
     * 权限组创建通知
     */
    onCreatePermissionGroup?: (groupID: string, permissionGroupInfo: V2TIMPermissionGroupInfo) => void;
    /**
     * 权限组删除通知
     */
    onDeletePermissionGroup?: (groupID: string, permissionGroupIDList: string[]) => void;
    /**
     * 权限组更新通知
     */
    onChangePermissionGroupInfo?: (groupID: string, permissionGroupInfo: V2TIMPermissionGroupInfo) => void;
    /**
     * 添加成员到权限组中
     */
    onAddMembersToPermissionGroup?: (groupID: string, permissionGroupID: string, memberIDList: string[]) => void;
    /**
     * 从权限组中删除成员
     */
    onRemoveMembersFromPermissionGroup?: (groupID: string, permissionGroupID: string, memberIDList: string[]) => void;
    /**
     * 增加话题权限到权限组中通知
     */
    onAddTopicPermission?: (groupID: string, permissionGroupID: string, topicPermissionMap: Map<string, number>) => void;
    /**
     * 从权限组删除的话题权限通知
     */
    onDeleteTopicPermission?: (groupID: string, permissionGroupID: string, topicIDList: string[]) => void;
    /**
     * 权限组中的话题权限修改通知
     */
    onModifyTopicPermission?: (groupID: string, permissionGroupID: string, topicPermissionMap: Map<string, number>) => void;
}
