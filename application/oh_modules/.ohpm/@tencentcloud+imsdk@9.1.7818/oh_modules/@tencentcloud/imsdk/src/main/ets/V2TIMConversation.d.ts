/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMGroupAtInfo, V2TIMMessage, V2TIMReceiveMessageOpt } from "../../../Index";
/**
 * （一）枚举值定义
 */
/**
 * 会话类型
 */
export declare enum V2TIMConversationType {
    /**
     * 未知
     */
    V2TIM_UNKNOWN = 0,
    /**
     * 单聊
     */
    V2TIM_C2C = 1,
    /**
     * 群聊
     */
    V2TIM_GROUP = 2
}
/**
 * 会话标记类型
 */
export declare enum V2TIMConversationMarkType {
    /**
     * 会话标星
     */
    V2TIM_CONVERSATION_MARK_TYPE_STAR = 1,
    /**
     * 会话标记未读（重要会话）
     */
    V2TIM_CONVERSATION_MARK_TYPE_UNREAD = 2,
    /**
     * 会话折叠
     */
    V2TIM_CONVERSATION_MARK_TYPE_FOLD = 4,
    /**
     * 会话隐藏
     */
    V2TIM_CONVERSATION_MARK_TYPE_HIDE = 8
}
/**
 * 会话过滤类型
 */
export declare enum V2TIMConversationFilterType {
    /**
     * 不过滤
     */
    V2TIM_CONVERSATION_FILTER_TYPE_NONE = 0,
    /**
     * 会话标记过滤
     */
    V2TIM_CONVERSATION_FILTER_TYPE_CONVERSATION_MARK = 1,
    /**
     * 会话分组过滤
     */
    V2TIM_CONVERSATION_FILTER_TYPE_CONVERSATION_GROUP = 2,
    /**
     * 会话是否有未读数过滤
     */
    V2TIM_CONVERSATION_FILTER_TYPE_HAS_UNREAD_COUNT = 4,
    /**
     * 会话是否有群 @ 信息过滤
     */
    V2TIM_CONVERSATION_FILTER_TYPE_HAS_GROUP_AT_INFO = 8
}
/**
 * （二）结构体定义
 */
/**
 * 会话对象
 */
export declare class V2TIMConversation {
    /**
     * 会话类型
     */
    type: V2TIMConversationType;
    /**
     * 会话唯一 ID，如果是 C2C 单聊，组成方式为 c2c_userID，如果是群聊，组成方式为 group_groupID
     */
    conversationID: string;
    /**
     * 如果会话类型为 C2C 单聊，userID 会存储对方的用户ID，否则为空字符串
     */
    userID: string;
    /**
     * 如果会话类型为群聊，groupID 会存储当前群的群 ID，否则为空字符串
     */
    groupID: string;
    /**
     * 如果会话类型为群聊，groupType 为当前群类型，否则为空字符串
     */
    groupType: string;
    /**
     * 会话展示名称（群组：群名称 >> 群 ID；C2C：对方好友备注 >> 对方昵称 >> 对方的 userID）
     */
    showName: string;
    /**
     * 会话展示头像（群组：群头像；C2C：对方头像）
     */
    faceUrl: string;
    /**
     * 会话未读消息数量,直播群（AVChatRoom）不支持未读计数，默认为 0
     */
    unreadCount: number;
    /**
     * 消息接收选项（接收 | 接收但不提醒 | 不接收）
     */
    recvOpt: V2TIMReceiveMessageOpt;
    /**
     * 会话最后一条消息，如果会话没有消息，lastMessage 字段为 NULL
     */
    /**
     * 5.5.892 以前版本，请您使用 lastMessage -> timestamp 对会话做排序，timestamp 越大，会话越靠前
     */
    lastMessage: V2TIMMessage;
    /**
     * 群会话 @ 信息列表，用于展示 “有人@我” 或 “@所有人” 这两种提醒状态
     */
    groupAtInfolist: V2TIMGroupAtInfo[];
    /**
     * 草稿信息，设置草稿信息请调用 SetConversationDraft() 接口
     */
    draftText: string;
    /**
     * 草稿编辑时间，草稿设置的时候自动生成
     */
    draftTimestamp: number;
    /**
     * 是否置顶
     */
    isPinned: boolean;
    /**
     * 排序字段（5.5.892 及以后版本支持）
     * @note
     * - 排序字段 orderKey
     * 是按照会话的激活时间线性递增的一个数字（注意：不是时间戳，因为同一时刻可能会有多个会话被同时激活）
     * - 5.5.892 及其以后版本，推荐您使用该字段对所有会话进行排序，orderKey
     * 值越大，代表该会话排序越靠前
     * - 当您 “清空会话所有消息” 或者 “逐个删除会话的所有消息” 之后，会话的 lastMessage
     * 变为空，但会话的 orderKey
     * 不会改变；如果想保持会话的排序位置不变，可以使用该字段对所有会话进行排序
     */
    orderKey: bigint;
    /**
     * 会话标记列表，取值详见 @V2TIMConversationMarkType（从 6.5 版本开始支持）
     */
    markList: number[];
    /**
     * 会话自定义数据（从 6.5 版本开始支持）
     */
    customData: ArrayBuffer;
    /**
     * 会话所属分组列表（从 6.5 版本开始支持）
     */
    conversationGroupList: string[];
    /**
     * 已读消息的时间戳，仅对单聊会话生效（从 7.1 版本开始支持）
     */
    c2cReadTimestamp: number;
    /**
     * 已读消息的 sequence，仅对群聊会话生效（从 7.1 版本开始支持）
     */
    groupReadSequence: number;
}
/**
 * 会话 filter
 */
export interface V2TIMConversationListFilter {
    /**
     * C2C 或群会话(填 0 代表不过滤此项)
     */
    type?: V2TIMConversationType;
    /**
     * 会话过滤类型，取值详见 V2TIMConversationFilterType
     * 如需会话分组过滤，则设置 filterType |= V2TIMConversationFilterType.V2TIM_CONVERSATION_FILTER_TYPE_CONVERSATION_GROUP
     * 如需会话标记过滤，则设置 filterType |= V2TIMConversationFilterType.V2TIM_CONVERSATION_FILTER_TYPE_CONVERSATION_MARK
     * 如需会话未读数过滤，则设置 filterType |= V2TIMConversationFilterType.V2TIM_CONVERSATION_FILTER_TYPE_HAS_UNREAD_COUNT
     * 如需会话群 @ 信息过滤，则设置 filterType |= V2TIMConversationFilterType.V2TIM_CONVERSATION_FILTER_TYPE_HAS_GROUP_AT_INFO
     */
    filterType?: number;
    /**
     * 会话分组名称(填空代表不过滤此项)
     */
    conversationGroup?: string;
    /**
     * 标记类型，取值详见 @V2TIMConversationMarkType(填 0 代表不过滤此项)
     */
    markType?: number;
    /**
     * 会话未读数
     * 当 filterType 设置为需要会话未读数过滤时，该字段才生效，设置为 true 代表过滤含未读数的会话；设置为 false 代表过滤不含未读数的会话
     */
    hasUnreadCount?: boolean;
    /**
     * 会话群 @ 信息
     * 当 filterType 设置为需要会话 @ 信息过滤时，该字段才生效，设置为 true 代表过滤含群 @ 消息的会话；设置为 false 代表过滤不含群 @ 消息的会话
     */
    hasGroupAtInfo?: boolean;
}
/**
 * 获取会话列表结果
 */
export declare class V2TIMConversationResult {
    /**
     * 获取下一次分页拉取的游标
     */
    nextSeq: number;
    /**
     * 会话列表是否已经拉取完毕
     */
    isFinished: boolean;
    /**
     * 获取会话列表
     */
    conversationList: V2TIMConversation[];
}
/**
 * 会话操作结果
 */
export declare class V2TIMConversationOperationResult {
    /**
     * 会话 ID
     */
    conversationID: string;
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
}
