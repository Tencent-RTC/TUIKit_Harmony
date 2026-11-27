/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMConversation, V2TIMConversationListFilter, V2TIMConversationListener, V2TIMConversationOperationResult, V2TIMConversationResult } from "../../../Index";
/**
 * 腾讯云通信服务 IMSDK
 *
 * 会话接口，里面包含了会话的获取，删除，更新的逻辑
 */
export declare class V2TIMConversationManager {
    /**
     * 1.1 添加会话监听器
     */
    addConversationListener(listener: V2TIMConversationListener): void;
    /**
     * 1.2 移除会话监听器
     */
    removeConversationListener(listener: V2TIMConversationListener): void;
    /**
     * 1.3 获取单个会话
     *
     * @param conversationID  会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"：
     * 群聊组成方式为: "group_groupID"
     */
    getConversation(conversationID: string): Promise<V2TIMConversation>;
    /**
     * 1.4 获取指定会话列表
     *
     * @param conversationIDList 会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"：
     * 群聊组成方式为: "group_groupID"
     */
    getConversations(conversationIDList: string[]): Promise<V2TIMConversation[]>;
    /**
     * 1.5 获取会话列表高级接口（从 6.5 版本开始支持）
     *
     * @param filter 会话 filter
     * @param nextSeq 分页拉取的游标
     * @param count 分页拉取的个数
     */
    getConversationListByFilter(nextSeq: number, count: number, filter?: V2TIMConversationListFilter): Promise<V2TIMConversationResult>;
    /**
     * 1.6 删除会话
     *
     * @param conversationID 会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"：
     * 群聊组成方式为: "group_groupID"
     *
     * @note
     * - 删除会话会在本地删除的同时，在服务器也会同步删除。
     * - 会话内的消息在本地删除的同时，在服务器也会同步删除。
     */
    deleteConversation(conversationID: string): Promise<void>;
    /**
     * 1.7 删除会话列表（7.1 及以上版本支持）
     *
     * @param conversationIDList 会话唯一 ID 列表，C2C 单聊组成方式为: "c2c_userID"：群聊组成方式为: "group_groupID"
     * @param clearMessage 是否删除会话中的消息；设置为 false 时，保留会话消息；设置为 true 时，本地和服务器的消息会一起删除，并且不可恢复
     *
     * @note 每次最多支持删除 100 个会话
     */
    deleteConversationList(conversationIDList: string[], clearMessage: boolean): Promise<V2TIMConversationOperationResult[]>;
    /**
     * 1.8 设置会话草稿
     *
     * @param conversationID 会话唯一 ID，C2C 会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"：
     * 群聊组成方式为: "group_groupID"
     *
     * 只在本地保存，不会存储 Server，不能多端同步，程序卸载重装会失效。
     *
     * @param draftText 草稿内容, 空字符串表示 则表示取消草稿
     */
    setConversationDraft(conversationID: string, draftText: string): Promise<void>;
    /**
     * 1.9 设置会话自定义数据（从 6.5 版本开始支持）
     *
     * @param customData 自定义数据，最大支持 256 bytes
     */
    setConversationCustomData(conversationIDList: string[], customData: ArrayBuffer): Promise<V2TIMConversationOperationResult[]>;
    /**
     * 1.10 设置会话置顶（5.3.425 及以上版本支持）
     *
     * @param conversationID 会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"：
     * 群聊组成方式为: "group_groupID"
     *
     * @param isPinned 是否置顶
     */
    pinConversation(conversationID: string, isPinned: boolean): Promise<void>;
    /**
     * 1.11 标记会话（从 6.5 版本开始支持，需要您购买旗舰版套餐）
     *
     * @param conversationIDList 会话列表
     * @param markType 会话标记类型，取值详见 @V2TIMConversationMarkType。
     * @param enableMark YES：设置标记 NO：取消标记
     *
     * 如果已有标记不能满足您的需求，您可以自定义扩展标记，扩展标记需要满足以下两个条件：
     * 1、扩展标记值不能和 V2TIMConversationMarkType 已有的标记值冲突
     * 2、扩展标记值必须是 0x1LL << n 的位移值（32 <= n < 64，即 n 必须大于等于 32 并且小于 64），比如扩展标记值 0x1LL << 32 表示 "Windows 在线"
     *
     * @note:扩展标记值不能设置为 0x1 << 32，要设置为 0x1LL << 32，明确告诉编译器是 64 位的整型常量。
     *
     */
    markConversation(conversationIDList: string[], markType: number, enableMark: boolean): Promise<V2TIMConversationOperationResult[]>;
    /**
     * 1.12 获取全部会话的未读总数（5.3.425 及以上版本支持）
     * @note
     * - 调用该接口以后，任意会话的未读数发生变化时，SDK 都会给您抛 OnTotalUnreadMessageCountChanged 回调。
     * - 未读总数会减去设置为免打扰的会话的未读数，即消息接收选项设置为
     * V2TIM_NOT_RECEIVE_MESSAGE 或 V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE  或 V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT 的会话。
     */
    getTotalUnreadMessageCount(): Promise<number>;
    /**
     * 1.13 获取按会话 filter 过滤的未读总数（7.0 及以上版本支持）
     *
     * @param filter 会话 filter
     *
     * @note
     * - 未读总数会减去设置为免打扰的会话的未读数，即消息接收选项设置为
     * V2TIM_NOT_RECEIVE_MESSAGE 或 V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE 或 V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE_EXCEPT_AT 的会话。
     */
    getUnreadMessageCountByFilter(filter: V2TIMConversationListFilter): Promise<number>;
    /**
     * 1.14 注册监听指定 filter 的会话未读总数变化（7.0 及以上版本支持）
     *
     * @param filter 会话 filter
     *
     * @note
     * - 当您调用这个接口以后，该 filter 下的未读数发生变化时，SDK 会给您抛 OnUnreadMessageCountChangedByFilter 回调。
     */
    subscribeUnreadMessageCountByFilter(filter: V2TIMConversationListFilter): void;
    /**
     * 1.15 取消监听指定 filter 的会话未读总数变化（7.0 及以上版本支持）
     *
     * @param filter 会话 filter
     *
     */
    unsubscribeUnreadMessageCountByFilter(filter: V2TIMConversationListFilter): void;
    /**  1.16 清理会话的未读消息计数（7.1 及以上版本支持）
     *
     * @param conversationID  会话唯一 ID，C2C 单聊组成方式为: "c2c_userID"；群聊组成方式为: "group_groupID"
     * @param cleanTimestamp  清理时间戳，单位为秒，仅对单聊会话生效，指定清理哪一个 timestamp 之前的未读消息计数；当传入为 0 时，对应会话所有的未读消息将被清理，会话的未读数会清 0
     * @param cleanSequence  清理 sequence，仅对群聊会话生效，指定清理哪一个 sequence 之前的未读消息计数；当传入为 0 时，对应会话所有的未读消息将被清理，会话的未读数会清 0
     *
     * @note
     * - 当您想清理所有单聊会话的未读消息计数，conversationID 请传入 "c2c"，即不指定具体的 userID；
     * - 当您想清理所有群聊会话的未读消息计数，conversationID 请传入 "group"，即不指定具体的 groupID；
     * - 当您想清理所有会话的未读消息计数，conversationID 请传入 ""；
     * - 该接口调用成功后，SDK 会通过 onConversationChanged 回调将对应会话的最新未读数通知给您。
     */
    cleanConversationUnreadMessageCount(conversationID: string, option?: {
        cleanTimestamp?: number;
        cleanSequence?: number;
    }): Promise<void>;
    /**
     * 2.1 创建会话分组
     *
     * @param groupName 分组名（必填参数，长度要 > 0，最大支持 32 bytes）
     * @param conversationIDList 会话 ID 列表（必填参数，不能为空）
     *
     * @note 会话分组最大支持 20 个，不再使用的分组请及时删除
     */
    createConversationGroup(groupName: string, conversationIDList: string[]): Promise<V2TIMConversationOperationResult[]>;
    /**
     * 2.2 获取会话分组列表
     * @note 该接口获取的是本地缓存的会话分组，建议在 onSyncServerFinish 之后调用。
     */
    getConversationGroupList(): Promise<string[]>;
    /**
     * 2.3 删除会话分组
     */
    deleteConversationGroup(groupName: string): Promise<void>;
    /**
     * 2.4 重命名会话分组
     *
     */
    renameConversationGroup(oldName: string, newName: string): Promise<void>;
    /**
     * 2.5 添加会话到一个会话分组
     */
    addConversationsToGroup(groupName: string, conversationIDList: string[]): Promise<V2TIMConversationOperationResult[]>;
    /**
     * 2.6 从一个会话分组中删除会话
     */
    deleteConversationsFromGroup(groupName: string, conversationIDList: string[]): Promise<V2TIMConversationOperationResult[]>;
}
