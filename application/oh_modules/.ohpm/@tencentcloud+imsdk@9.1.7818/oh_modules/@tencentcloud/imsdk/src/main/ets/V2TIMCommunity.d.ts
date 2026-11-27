/**
 * Copyright (c) 2024 Tencent. All rights reserved.
 */
import { V2TIMMessage, V2TIMReceiveMessageOpt, V2TIMGroupAddOpt, V2TIMGroupAtInfo, V2TIMGroupMemberInfo, V2TIMCreateGroupMemberInfo } from "../../../Index";
/**
 * （一）枚举值定义
 */
/**
 * 话题资料修改标记位
 */
export declare enum V2TIMTopicInfoModifyFlag {
    /**
     * 未定义
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_UNKNOWN = 0,
    /**
     * 名称
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_NAME = 1,
    /**
     * 公告
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_NOTIFICATION = 2,
    /**
     * 简介
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_INTRODUCTION = 4,
    /**
     * 头像
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_FACE_URL = 8,
    /**
     * 禁言
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_MUTE_ALL = 256,
    /**
     * 话题自定义字段
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_CUSTOM_STRING = 2048,
    /**
     * 话题草稿
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_DRAFT = 16384,
    /**
     * 话题默认权限，7.8 版本开始支持
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_DEFAULT_PERMISSIONS = 32768,
    /**
     * 话题类型（从 8.5 版本开始支持）
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_TYPE = 16777216,
    /**
     * 申请加入话题选项(私密话题有效)（从 8.4 版本开始支持）
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_ADD_OPT = 33554432,
    /**
     * 话题邀请选项(私密话题有效)（从 8.4 版本开始支持）
     */
    V2TIM_COMMUNITY_MODIFY_FLAG_TOPIC_APPROVE_OPT = 67108864
}
/**
 * 权限组修改标记位
 */
export declare enum V2TIMPermissionGroupInfoModifyFlag {
    /**
     * 未定义
     */
    V2TIM_PERMISSION_MODIFY_FLAG_NONE = 0,
    /**
     * 名称
     */
    V2TIM_PERMISSION_MODIFY_FLAG_NAME = 1,
    /**
     * 群权限
     */
    V2TIM_PERMISSION_MODIFY_FLAG_GROUP_PERMISSION = 2,
    /**
     * 自定义字段
     */
    V2TIM_PERMISSION_MODIFY_FLAG_CUSTOM_DATA = 4
}
export declare enum V2TIMCommunityPermissionValue {
    /**
     * 修改群资料权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_MANAGE_GROUP_INFO = 1,
    /**
     * 群成员管理权限，包含踢人，进群审核、修改成员资料等。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_MANAGE_GROUP_MEMBER = 2,
    /**
     * 管理权限组资料权限，包含创建、修改、删除权限组；在权限组中添加、修改、删除话题权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_MANAGE_PERMISSION_GROUP_INFO = 4,
    /**
     * 权限组成员管理权限，包含邀请成员进权限组和把成员从权限组踢出等。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_MANAGE_PERMISSION_GROUP_MEMBER = 8,
    /**
     * 话题管理权限，包含创建、修改、删除话题等。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_MANAGE_TOPIC_IN_COMMUNITY = 16,
    /**
     * 对某群成员在社群下所有话题的禁言权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_MUTE_MEMBER = 32,
    /**
     * 群成员在社群下所有话题的发消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_SEND_MESSAGE = 64,
    /**
     * 在社群下所有话题发 at all 消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_AT_ALL = 128,
    /**
     * 在社群下所有话题拉取入群前的历史消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_GET_HISTORY_MESSAGE = 256,
    /**
     * 在社群下所有话题撤回他人消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_REVOKE_OTHER_MEMBER_MESSAGE = 512,
    /**
     * 封禁社群成员权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_COMMUNITY_PERMISSION_BAN_MEMBER = 1024
}
export declare enum V2TIMTopicPermissionValue {
    /**
     * 管理指定话题权限，包含修改、删除话题。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_MANAGE_TOPIC = 1,
    /**
     * 在话题中管理话题权限，包含添加、修改、移除话题权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_MANAGE_TOPIC_PERMISSION = 2,
    /**
     * 在话题中禁言成员权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_MUTE_MEMBER = 4,
    /**
     * 在话题中发消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_SEND_MESSAGE = 8,
    /**
     * 在话题中拉取入群前的历史消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_GET_HISTORY_MESSAGE = 16,
    /**
     * 在话题中撤回他人消息权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_REVOKE_OTHER_MEMBER_MESSAGE = 32,
    /**
     * 在话题中发消息时有 at all 权限。该位设置为0，表示没有该权限；设置为1，表示有该权限
     */
    V2TIM_TOPIC_PERMISSION_AT_ALL = 64
}
/**
 * （二）结构体定义
 */
/**
 * 话题基本资料（可以通过 getTopics 获取，不支持由客户自行创建）
 */
export declare class V2TIMTopicInfo {
    /**
     * 话题 ID
     */
    topicID: string;
    /**
     * 话题类型（默认为 Public 话题）(从 8.4 版本开始支持)
     * "Public"  ：公开话题，社群内成员可以自由进出发言。
     * "Private" ：私密话题，有自己的成员列表（成员上限 10000 人），社群成员需要加入话题才能发言（私密话题需要购买企业版套餐包）。
     */
    topicType: string;
    /**
     * 话题名称
     */
    topicName: string;
    /**
     * 话题头像
     */
    topicFaceURL: string;
    /**
     * 话题介绍
     */
    introduction: string;
    /**
     * 话题公告
     */
    notification: string;
    /**
     * 话题全员禁言
     */
    isAllMuted: boolean;
    /**
     * 当前用户在话题中的禁言时间
     */
    selfMuteTime: number;
    /**
     * 话题自定义字段
     */
    customString: string;
    /**
     * 话题消息接收选项，修改话题消息接收选项请调用 setGroupReceiveMessageOpt 接口
     */
    recvOpt: V2TIMReceiveMessageOpt;
    /**
     * 话题草稿
     */
    draftText: string;
    /**
     * 话题消息未读数量
     */
    unreadCount: number;
    /**
     * 话题 lastMessage
     */
    lastMessage: V2TIMMessage;
    /**
     * 话题已读消息的 sequence，从 7.8 版本开始支持
     */
    readSequence: number;
    /**
     * 话题 at 信息列表
     */
    groupAtInfoList: V2TIMGroupAtInfo[];
    /**
     * 话题创建时间，单位：秒
     */
    createTime: number;
    /**
     * 申请加入话题是否需要管理员审批（私密话题有效，默认不需要审批，可以自由加入）(从 8.4 版本开始支持)
     */
    topicAddOpt: V2TIMGroupAddOpt;
    /**
     * 邀请加入话题是否需要管理员审批（私密话题有效，默认不需要审批，可以自由加入）(从 8.4 版本开始支持)
     */
    topicApproveOpt: V2TIMGroupAddOpt;
    /**
     * 话题默认群成员（私密话题有效，最大支持 100 个群成员，只能在创建话题的时候设置）(从 8.4 版本开始支持)
     */
    memberList: V2TIMCreateGroupMemberInfo[];
    /**
     * 话题成员的最大个数（私密话题有效，最大支持 10000，默认 10000，只能在创建话题的时候设置）(从 8.4 版本开始支持)
     */
    memberMaxCount: number;
    /**
     * 话题默认权限，7.8 版本开始支持
     * 群成员在没有加入任何权限组时的默认权限，仅在社群资料 V2TIMGroupInfo 中 enablePermissionGroup = true 打开权限组之后生效
     */
    default_permissions: number;
    /**
     * 获取登录用户在话题中的消息接收选项是否继承社群。该功能仅增强版 SDK 8.1 及以上版本支持。
     */
    isInheritMessageReceiveOptionFromCommunity(): boolean;
    /**
     * 设置登录用户在话题中的消息接收选项是否继承社群。该功能仅增强版 SDK 8.1 及以上版本支持。
     */
    setInheritMessageReceiveOptionFromCommunity(isInherit: boolean): Promise<void>;
    /**
     * 话题资料修改标记位
     * 枚举 V2TIMGroupInfoModifyFlag 列出哪些字段支持修改，如果您修改群资料，请设置这个字段值
     * 如果您同时修改多个字段，多个枚举值按位或 | 组合，例如，同时修改群名称和头像
     * info.topicName = "new group name";
     * info.topicFaceURL = "new face url";
     * info.modifyFlag = V2TIM_GROUP_INFO_MODIFY_FLAG_GROUP_NAME |
     * V2TIM_GROUP_INFO_MODIFY_FLAG_FACE_URL;
     */
    modifyFlag: number;
}
/**
 * 话题处理结果
 */
export declare class V2TIMTopicOperationResult {
    /**
     * 结果 0：成功；非0：失败
     */
    errorCode: number;
    /**
     * 如果删除失败，会返回错误信息
     */
    errorMsg: string;
    /**
     * 如果删除成功，会返回对应的 topicID
     */
    topicID: string;
}
/**
 * 话题资料获取结果
 */
export declare class V2TIMTopicInfoResult {
    /**
     * 结果 0：成功；非0：失败
     */
    errorCode: number;
    /**
     * 如果获取失败，会返回错误信息
     */
    errorMsg: string;
    /**
     * 如果获取成功，会返回对应的 info
     */
    topicInfo: V2TIMTopicInfo;
}
/**
 * 权限组信息
 */
export declare class V2TIMPermissionGroupInfo {
    /**
     * 群 ID
     */
    groupID: string;
    /**
     * 权限组 ID
     */
    permissionGroupID: string;
    /**
     * 权限组名称
     */
    permissionGroupName: string;
    /**
     * 权限组自定义字段
     */
    customData: string;
    /**
     * 群权限
     */
    groupPermission: number;
    /**
     * 权限组当前人数
     */
    memberCount: number;
    /**
     * 权限组资料修改标记位
     * 枚举 V2TIMPermissionGroupInfoModifyFlag 列出哪些字段支持修改，如果您修改权限组资料，请设置这个字段值
     * 如果您同时修改多个字段，多个枚举值按位或 | 组合，例如，同时修改群名称和头像
     * info.permissionGroupName = "new permission group name";
     * info.customData = "new custom data";
     * info.modifyFlag = V2TIM_PERMISSION_MODIFY_FLAG_NAME | V2TIM_PERMISSION_MODIFY_FLAG_CUSTOM_STRING;
     */
    modifyFlag: number;
}
/**
 * 权限组信息获取结果
 */
export declare class V2TIMPermissionGroupInfoResult {
    /**
     * 结果 0：成功；非0：失败
     */
    resultCode: number;
    /**
     * 如果获取失败，会返回错误信息
     */
    resultMsg: string;
    /**
     * 如果获取成功，会返回对应的 info
     */
    info: V2TIMPermissionGroupInfo;
}
/**
 * 权限组处理结果
 */
export declare class V2TIMPermissionGroupOperationResult {
    /**
     * 结果 0：成功；非0：失败
     */
    resultCode: number;
    /**
     * 如果处理失败，会返回错误信息
     */
    resultMsg: string;
    /**
     * 权限组 ID
     */
    permissionGroupID: string;
}
/**
 * 权限组成员获取结果
 */
export declare class V2TIMPermissionGroupMemberInfoResult {
    /**
     * 分页拉取的游标
     */
    nextCursor: string;
    /**
     * 群成员列表
     */
    memberInfoList: V2TIMGroupMemberInfo[];
}
/**
 * 权限组成员处理结果
 */
export declare class V2TIMPermissionGroupMemberOperationResult {
    /**
     * 被操作成员
     */
    memberID: string;
    /**
     * 结果 0：成功；非0：失败
     */
    resultCode: number;
}
/**
 * 话题权限获取结果
 */
export declare class V2TIMTopicPermissionResult {
    /**
     * 话题 ID
     */
    topicID: string;
    /**
     * 结果 0：成功；非0：失败
     */
    resultCode: number;
    /**
     * 如果处理失败，会返回错误信息
     */
    resultMsg: string;
    /**
     * 话题权限
     */
    topicPermission: number;
    /**
     * 社群 ID
     */
    groupID: string;
    /**
     * 权限组 ID
     */
    permissionGroupID: string;
}
/**
 * 设置话题基本资料参数
 */
export interface V2TIMSetTopicInfoParam {
    /**
     * 话题 ID
     */
    topicID: string;
    /**
     * 话题类型
     */
    topicType: string;
    /**
     * 话题名称
     */
    topicName: string;
    /**
     * 话题头像
     */
    topicFaceURL: string;
    /**
     * 话题介绍
     */
    introduction: string;
    /**
     * 话题公告
     */
    notification: string;
    /**
     * 话题全员禁言
     */
    isAllMuted: boolean;
    /**
     * 当前用户在话题中的禁言时间
     */
    selfMuteTime: number;
    /**
     * 话题自定义字段
     */
    customString: string;
    /**
     * 话题消息接收选项，修改话题消息接收选项请调用 setGroupReceiveMessageOpt 接口
     */
    recvOpt: V2TIMReceiveMessageOpt;
    /**
     * 话题草稿
     */
    draftText: string;
    /**
     * 话题消息未读数量
     */
    unreadCount: number;
    /**
     * 话题 lastMessage
     */
    lastMessage: V2TIMMessage;
    /**
     * 话题 at 信息列表
     */
    groupAtInfoList: V2TIMGroupAtInfo[];
    /**
     * 话题创建时间，单位：秒
     */
    createTime: number;
    /**
     * 话题默认权限，7.8 版本开始支持
     * 群成员在没有加入任何权限组时的默认权限，仅在社群资料 V2TIMGroupInfo 中 enablePermissionGroup = true 打开权限组之后生效
     */
    default_permissions: number;
}
/**
 * 创建话题参数
 */
export interface V2TIMCreateTopicInCommunityParam {
    /**
     * 话题 ID
     */
    topicID: string;
    /**
     * 话题名称
     */
    topicName: string;
    /**
     * 话题头像
     */
    topicFaceURL: string;
    /**
     * 话题介绍
     */
    introduction: string;
    /**
     * 话题公告
     */
    notification: string;
    /**
     * 话题全员禁言
     */
    isAllMuted: boolean;
    /**
     * 当前用户在话题中的禁言时间
     */
    selfMuteTime: number;
    /**
     * 话题自定义字段
     */
    customString: string;
    /**
     * 话题消息接收选项，修改话题消息接收选项请调用 setGroupReceiveMessageOpt 接口
     */
    recvOpt: V2TIMReceiveMessageOpt;
    /**
     * 话题草稿
     */
    draftText: string;
    /**
     * 话题消息未读数量
     */
    unreadCount: number;
    /**
     * 话题 lastMessage
     */
    lastMessage: V2TIMMessage;
    /**
     * 话题 at 信息列表
     */
    groupAtInfoList: V2TIMGroupAtInfo[];
    /**
     * 话题创建时间，单位：秒
     */
    createTime: number;
    /**
     * 话题默认权限，7.8 版本开始支持
     * 群成员在没有加入任何权限组时的默认权限，仅在社群资料 V2TIMGroupInfo 中 enablePermissionGroup = true 打开权限组之后生效
     */
    default_permissions: number;
}
/**
 * 设置社群权限组信息参数
 */
export interface V2TIMModifyPermissionGroupInfoInCommunityParam {
    /**
     * 群 ID
     */
    groupID: string;
    /**
     * 权限组 ID
     */
    permissionGroupID: string;
    /**
     * 权限组名称
     */
    permissionGroupName?: string;
    /**
     * 权限组自定义字段
     */
    customData?: string;
    /**
     * 群权限
     */
    groupPermission?: number;
}
/**
 * 创建社群权限组参数
 */
export interface V2TIMCreatePermissionGroupInCommunityParam {
    /**
     * 群 ID
     */
    groupID: string;
    /**
     * 权限组 ID
     */
    permissionGroupID?: string;
    /**
     * 权限组名称
     */
    permissionGroupName: string;
    /**
     * 权限组自定义字段
     */
    customData?: string;
    /**
     * 群权限
     */
    groupPermission?: number;
}
