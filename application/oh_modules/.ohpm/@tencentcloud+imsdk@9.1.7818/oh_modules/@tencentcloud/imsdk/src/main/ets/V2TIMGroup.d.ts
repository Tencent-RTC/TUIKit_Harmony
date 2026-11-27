/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMKeywordListMatchType, V2TIMReceiveMessageOpt } from "../../../Index";
/**
 * （一）枚举值定义
 */
/**
 * 群类型
 */
export declare enum V2TIMGroupType {
    /**
     * 工作群
     */
    Work = "Work",
    /**
     * 公开群
     */
    Public = "Public",
    /**
     * 会议群
     */
    Meeting = "Meeting",
    /**
     * 社群
     */
    Community = "Community",
    /**
     * 直播群
     */
    AVChatRoom = "AVChatRoom"
}
/**
 * 群成员角色
 */
export declare enum V2TIMGroupMemberRole {
    /**
     * 未定义（没有获取该字段）
     */
    V2TIM_GROUP_MEMBER_UNDEFINED = 0,
    /**
     * 群成员
     */
    V2TIM_GROUP_MEMBER_ROLE_MEMBER = 200,
    /**
     * 群管理员
     */
    V2TIM_GROUP_MEMBER_ROLE_ADMIN = 300,
    /**
     * 群主
     */
    V2TIM_GROUP_MEMBER_ROLE_SUPER = 400
}
/**
 * 群变更信息 Tips 类型
 */
export declare enum V2TIMGroupInfoChangeType {
    /**
     * 群名修改
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_NAME = 1,
    /**
     * 群简介修改
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_INTRODUCTION = 2,
    /**
     * 群公告修改
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_NOTIFICATION = 3,
    /**
     * 群头像修改
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_FACE = 4,
    /**
     * 群主变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_OWNER = 5,
    /**
     * 群自定义字段变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_CUSTOM = 6,
    /**
     * 全员禁言字段变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_SHUT_UP_ALL = 8,
    /**
     * 消息接收选项变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_RECEIVE_MESSAGE_OPT = 10,
    /**
     * 申请加群方式下管理员审批选项变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_ADD_OPT = 11,
    /**
     * 邀请进群方式下管理员审批选项变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_APPROVE_OPT = 12,
    /**
     * 是否开启权限组功能变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_ENABLE_PERMISSION_GROUP = 13,
    /**
     * 群默认权限变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_DEFAULT_PERMISSIONS = 14,
    /**
     * 申请加入私密话题时管理员的审批选项变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_TOPIC_ADD_OPT = 15,
    /**
     * 邀请进入私密话题时管理员的审批选项变更
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_TOPIC_APPROVE_OPT = 16,
    /**
     * 私密话题最大成员数量
     */
    V2TIM_GROUP_INFO_CHANGE_TYPE_TOPIC_MEMBER_MAX_COUNT = 17
}
/**
 * 加群选项
 */
export declare enum V2TIMGroupAddOpt {
    /**
     * 禁止加群
     */
    V2TIM_GROUP_ADD_FORBID = 0,
    /**
     * 需要管理员审批
     */
    V2TIM_GROUP_ADD_AUTH = 1,
    /**
     * 任何人可以加入
     */
    V2TIM_GROUP_ADD_ANY = 2,
    /**
     * 未定义
     */
    V2TIM_GROUP_ADD_UNKNOWN = 3
}
/**
 * 群资料修改标记位
 */
export declare enum V2TIMGroupInfoModifyFlag {
    /**
     * 未定义
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_UNKNOWN = 0,
    /**
     * 名称
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_GROUP_NAME = 1,
    /**
     * 公告
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_NOTIFICATION = 2,
    /**
     * 简介
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_INTRODUCTION = 4,
    /**
     * 头像
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_FACE_URL = 8,
    /**
     * 申请加群管理员审批选项
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_GROUP_ADD_OPTION = 16,
    /**
     * 禁言
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_SHUTUP_ALL = 256,
    /**
     * 群自定义数据
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_CUSTOM_INFO = 512,
    /**
     * 话题自定义字段
     */
    V2TIM_TOPIC_INFO_MODIFY_FLAG_CUSTOM_STRING = 2048,
    /**
     * 邀请进群管理员审批选项
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_GROUP_APPROVE_OPTION = 4096,
    /**
     * 开启权限组功能，仅支持社群，7.8 版本开始支持
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_ENABLE_PERMISSION_GROUP = 8192,
    /**
     * 群默认权限，仅支持社群，7.8 版本开始支持
     */
    V2TIM_GROUP_INFO_MODIFY_FLAG_DEFAULT_PERMISSIONS = 16384
}
/**
 * 群组操作结果
 */
export declare enum V2TIMGroupMemberResult {
    /**
     * 操作失败
     */
    V2TIM_GROUP_MEMBER_RESULT_FAIL = 0,
    /**
     * 操作成功
     */
    V2TIM_GROUP_MEMBER_RESULT_SUCC = 1,
    /**
     * 无效操作，加群时已经是群成员，移除群组时不在群内
     */
    V2TIM_GROUP_MEMBER_RESULT_INVALID = 2,
    /**
     * 等待处理，邀请入群时等待审批
     */
    V2TIM_GROUP_MEMBER_RESULT_PENDING = 3,
    /**
     * 操作失败，创建群指定初始群成员列表或邀请入群时，被邀请者加入的群总数超限
     */
    V2TIM_GROUP_MEMBER_RESULT_OVERLIMIT = 4
}
/**
 * 群成员角色过滤方式
 */
export declare enum V2TIMGroupMemberFilter {
    /**
     * 全部成员
     */
    V2TIM_GROUP_MEMBER_FILTER_ALL = 0,
    /**
     * 群主
     */
    V2TIM_GROUP_MEMBER_FILTER_OWNER = 1,
    /**
     * 管理员
     */
    V2TIM_GROUP_MEMBER_FILTER_ADMIN = 2,
    /**
     * 普通成员
     */
    V2TIM_GROUP_MEMBER_FILTER_COMMON = 4
}
/**
 * 群成员资料修改标记位
 */
export declare enum V2TIMGroupMemberInfoModifyFlag {
    /**
     * 未定义
     */
    V2TIM_GROUP_MEMBER_INFO_MODIFY_FLAG_UNKNOWN = 0,
    /**
     * 群内角色
     */
    V2TIM_GROUP_MEMBER_INFO_MODIFY_FLAG_MEMBER_ROLE = 2,
    /**
     * 禁言时间
     */
    V2TIM_GROUP_MEMBER_INFO_MODIFY_FLAG_SHUTUP_TIME = 4,
    /**
     * 群名片
     */
    V2TIM_GROUP_MEMBER_INFO_MODIFY_FLAG_NAME_CARD = 8,
    /**
     * 群成员自定义数据
     */
    V2TIM_GROUP_MEMBER_INFO_MODIFY_FLAG_CUSTOM_INFO = 16,
    /**
     * @hidden
     * 登录用户在话题中的消息接收选项是否继承社群
     */
    V2TIM_GROUP_MEMBER_INFO_MODIFY_FLAG_TOPIC_INHERIT_MESSAGE_RECEIVE_OPTION_FROM_COMMUNITY = 32
}
/**
 * 群组未决请求类型
 */
export declare enum V2TIMGroupApplicationType {
    /**
     * 申请入群
     */
    V2TIM_GROUP_JOIN_APPLICATION_NEED_APPROVED_BY_ADMIN = 0,
    /**
     * 等待被邀请者同意的邀请入群请求
     */
    V2TIM_GROUP_INVITE_APPLICATION_NEED_APPROVED_BY_INVITEE = 1,
    /**
     * 等待被群主或管理员审批的邀请入群请求
     */
    V2TIM_GROUP_INVITE_APPLICATION_NEED_APPROVED_BY_ADMIN = 2
}
/**
 * 群组已决标志
 */
export declare enum V2TIMGroupApplicationHandleStatus {
    /**
     * 未处理
     */
    V2TIM_GROUP_APPLICATION_HANDLE_STATUS_UNHANDLED = 0,
    /**
     * 被他人处理
     */
    V2TIM_GROUP_APPLICATION_HANDLE_STATUS_HANDLED_BY_OTHER = 1,
    /**
     * 自己已处理
     */
    V2TIM_GROUP_APPLICATION_HANDLE_STATUS_HANDLED_BY_SELF = 2
}
/**
 * 群组已决结果
 */
export declare enum V2TIMGroupApplicationHandleResult {
    /**
     * 拒绝申请
     */
    V2TIM_GROUP_APPLICATION_HANDLE_RESULT_REFUSE = 0,
    /**
     * 同意申请
     */
    V2TIM_GROUP_APPLICATION_HANDLE_RESULT_AGREE = 1
}
/**
 * @ 类型
 */
export declare enum V2TIMGroupAtType {
    /**
     * @ 我
     */
    V2TIM_AT_ME = 1,
    /**
     * @ 群里所有人
     */
    V2TIM_AT_ALL = 2,
    /**
     * @ 群里所有人并且单独 @ 我
     */
    V2TIM_AT_ALL_AT_ME = 3
}
/**
 * （二）结构体定义
 */
/**
 * 群成员基本资料
 */
export declare class V2TIMGroupMemberInfo {
    /**
     * 用户 ID
     */
    userID: string;
    /**
     * 用户昵称
     */
    nickName: string;
    /**
     * 用户好友备注
     */
    friendRemark: string;
    /**
     * 群成员名片
     */
    nameCard: string;
    /**
     * 用户头像
     */
    faceURL: string;
    /**
     * 在线终端列表
     */
    onlineDevices: string[];
}
/**
 * 群成员详细资料
 */
export declare class V2TIMGroupMemberFullInfo extends V2TIMGroupMemberInfo {
    /**
     * 群成员自定义字段
     * 首先要在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 群成员自定义字段)
     * 配置用户自定义字段，然后再调用该接口进行设置。
     */
    customInfo: Map<string, ArrayBuffer>;
    /**
     * 群成员角色,修改群成员角色请调用 V2TIMManagerGroup.h -> SetGroupMemberRole 接口
     */
    role: number;
    /**
     * 群成员禁言结束时间戳，禁言用户请调用 V2TIMManagerGroup.h -> MuteGroupMember 接口
     */
    muteUntil: number;
    /**
     * 群成员入群时间，自动生成，不可修改
     */
    joinTime: number;
    /**
     * 群成员是否在线
     * @note 请注意：
     * - 不支持直播群 AVChatRoom；
     * - 该字段仅在调用 getGroupMemberList 接口时有效；
     * - 7.3 及其以上版本支持，需要您购买旗舰版套餐。
     */
    isOnline: boolean;
    /**
     * @hidden
     * 登录用户在话题中的消息接收选项是否继承社群
     */
    _inheritMessageReceiveOptionFromCommunity: boolean;
    /**
     * @hidden
     */
    modifyFlag?: number;
}
/**
 * 群成员详细资料
 */
export interface V2TIMSetGroupMemberInfo {
    /**
     * 用户 ID
     */
    userID: string;
    /**
     * 群成员名片
     */
    nameCard?: string;
    /**
     * 群成员自定义字段
     * 首先要在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 群成员自定义字段)
     * 配置用户自定义字段，然后再调用该接口进行设置。
     */
    customInfo?: Map<string, ArrayBuffer>;
    /**
     * 群成员角色,修改群成员角色请调用 V2TIMManagerGroup.h -> SetGroupMemberRole 接口
     */
    role?: number;
    /**
     * 群成员禁言结束时间戳，禁言用户请调用 V2TIMManagerGroup.h -> MuteGroupMember 接口
     */
    muteUntil?: number;
}
/**
 * 获取群成员信息的结果
 */
export declare class V2TIMGroupMemberInfoResult {
    /**
     * 获取分页拉取的 seq。如果为 0 表示拉取结束
     */
    nextSequence: number;
    /**
     * 群成员信息列表
     */
    memberInfoList: V2TIMGroupMemberFullInfo[];
}
/**
 * 群 tips，群变更信息
 */
export declare class V2TIMGroupChangeInfo {
    /**
     * 变更类型
     */
    type: V2TIMGroupInfoChangeType;
    /**
     * 根据变更类型表示不同的值,例如 type = V2TIM_GROUP_INFO_CHANGE_TYPE_NAME，value 表示群新的
     * groupName
     */
    value: string;
    /**
     * 变更自定义字段的 key 值（type = V2TIM_GROUP_INFO_CHANGE_TYPE_CUSTOM 生效）
     * 因为历史遗留原因，如果只修改了群自定义字段，当前消息不会存漫游和 DB
     */
    key: string;
    /**
     * 根据变更类型表示不同的值
     * 当前在 type = V2TIM_GROUP_INFO_CHANGE_TYPE_SHUT_UP_ALL 或者 V2TIM_GROUP_INFO_CHANGE_TYPE_ENABLE_PERMISSION_GROUP 时有效
     */
    boolValue: boolean;
    /**
     * 根据变更类型表示不同的值
     * @note 仅针对以下类型有效：
     * - 从 6.5 版本开始，当 type 为 V2TIM_GROUP_INFO_CHANGE_TYPE_RECEIVE_MESSAGE_OPT 时，该字段标识了群消息接收选项发生了变化，其取值详见 @V2TIMReceiveMessageOpt；
     * - 从 6.5 版本开始，当 type 为 V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_ADD_OPT 时，该字段标识了申请加群审批选项发生了变化，其取值详见 @V2TIMGroupAddOpt;
     * - 从 7.1 版本开始，当 type 为 V2TIM_GROUP_INFO_CHANGE_TYPE_GROUP_APPROVE_OPT 时，该字段标识了邀请进群审批选项发生了变化，取值类型详见 @V2TIMGroupAddOpt。
     */
    intValue: number;
    /**
     * 根据变更类型表示不同的值
     * 当前只有 type = V2TIM_GROUP_INFO_CHANGE_TYPE_DEFAULT_PERMISSIONS 时有效
     */
    uint64Value: number;
}
/**
 * 群tips，成员变更信息
 */
export declare class V2TIMGroupMemberChangeInfo {
    /**
     * 变更用户
     */
    userID: string;
    /**
     * 禁言时间（秒，表示还剩多少秒可以发言）
     */
    muteTime: number;
}
/**
 * 群 @ 信息
 */
export declare class V2TIMGroupAtInfo {
    /**
     * 消息序列号，即带有 “@我” 或者 “@所有人” 标记的消息的序列号
     */
    seq?: number;
    /**
     * @ 提醒类型，分成 “@我” 、“@所有人” 以及 “@我并@所有人” 三类
     */
    atType?: V2TIMGroupAtType;
}
/**
 * 群资料
 */
export declare class V2TIMGroupInfo {
    /**
     * 群组 ID
     * 自定义群组 ID 必须为可打印 ASCII 字符（0x20-0x7e），最长 48 个字节，且前缀不能为
     * @TGS#（避免与默认分配的群组 ID 混淆）
     */
    groupID: string;
    /**
     * 群类型
     */
    groupType: string;
    /**
     * 社群是否支持创建话题，只在群类型为 Community 时有效
     */
    isSupportTopic: boolean;
    /**
     * 群名称
     * 群名称最长100字节
     */
    groupName: string;
    /**
     * 群公告
     * 群公告最长400字节
     */
    notification: string;
    /**
     * 群简介
     * 群简介最长400字节
     */
    introduction: string;
    /**
     * 群头像
     * 群头像 URL 最长500字节
     */
    faceURL: string;
    /**
     * 是否全员禁言
     */
    allMuted: boolean;
    /**
     * 设置群自定义字段需要两个步骤：
     * 1.在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 群自定义字段)
     * 配置群自定义字段的 key 值，Key 为 string 类型，长度不超过 16 字节。 2.调用 SetGroupInfo
     * 接口设置该字段，value 为 V2TIMSBuffer 数据，长度不超过 512 字节。
     */
    customInfo: Map<string, ArrayBuffer>;
    /**
     * 群创建人/管理员
     */
    owner: string;
    /**
     * 创建群组的 UTC 时间戳
     */
    createTime: number;
    /**
     * 申请进群是否需要管理员审批：工作群（Work）默认值为 V2TIM_GROUP_ADD_FORBID，即默认不允许申请入群，您可以修改该字段打开申请入群方式。
     */
    groupAddOpt: V2TIMGroupAddOpt;
    /**
     * 邀请进群是否需要管理员审批 （从 7.1 版本开始支持）
     * - 除工作群（Work）之外的其他群类型默认值都为 V2TIM_GROUP_ADD_FORBID，即默认不允许邀请入群，您可以修改该字段打开邀请入群方式。
     * - 直播群、社群和话题默认不允许邀请入群，也不支持修改。
     */
    groupApproveOpt: V2TIMGroupAddOpt;
    /**
     * 上次修改群信息的 UTC 时间戳
     */
    lastInfoTime: number;
    /**
     * 群最近一次发消息时间
     */
    lastMessageTime: number;
    /**
     * 已加入的群成员数量
     */
    memberCount: number;
    /**
     * 在线的群成员数量（待废弃字段，请使用 getGroupOnlineMemberCount 接口获取群在线人数）
     */
    onlineCount: number;
    /**
     * 最多允许加入的群成员数量
     * 各类群成员人数限制详见:
     * https://cloud.tencent.com/document/product/269/1502#.E7.BE.A4.E7.BB.84.E9.99.90.E5.88.B6.E5.B7.AE.E5.BC.82
     */
    memberMaxCount: number;
    /**
     * 当前用户在此群组中的角色，切换角色请调用 setGroupMemberRole 接口
     */
    role: number;
    /**
     * 当前用户在此群组中的消息接收选项,修改群消息接收选项请调用 SetGroupReceiveMessageOpt 接口
     */
    recvOpt: V2TIMReceiveMessageOpt;
    /**
     * 当前用户加入此群的 UTC 时间戳，不支持设置，系统自动生成
     */
    joinTime: number;
    /**
     * 是否开启权限组功能，仅支持社群，7.8 版本开始支持
     * 开启后，管理员角色的权限失效，用群权限、话题权限和权限组能力来对社群、话题进行管理。
     */
    enablePermissionGroup: boolean;
    /**
     * 群默认权限，仅支持社群，7.8 版本开始支持
     * 群成员在没有加入任何权限组时的默认权限，仅在 enablePermissionGroup = true 打开权限组之后生效
     */
    defaultPermissions: number;
    /**
     * @hidden
     * 群资料修改标记位
     * 枚举 V2TIMGroupInfoModifyFlag 列出哪些字段支持修改，如果您修改群资料，请设置这个字段值
     * 如果您同时修改多个字段，多个枚举值按位或 | 组合，例如，同时修改群名称和头像
     * info.groupName = "new group name";
     * info.faceURL = "new face url";
     * info.modifyFlag = V2TIM_GROUP_INFO_MODIFY_FLAG_GROUP_NAME |
     * V2TIM_GROUP_INFO_MODIFY_FLAG_FACE_URL;
     */
    modifyFlag?: number;
}
/**
 * 群资料
 */
export interface V2TIMCreateGroupInfo {
    /**
     * 群类型
     */
    groupType: string;
    /**
     * 群名称
     * 群名称最长30字节
     */
    groupName: string;
    /**
     * 群组 ID
     * 自定义群组 ID 必须为可打印 ASCII 字符（0x20-0x7e），最长48个字节，且前缀不能为
     * @TGS#（避免与默认分配的群组 ID 混淆）
     */
    groupID?: string;
    /**
     * 群公告
     * 群公告最长300字节
     */
    notification?: string;
    /**
     * 群简介
     * 群简介最长240字节
     */
    introduction?: string;
    /**
     * 群头像
     * 群头像 URL 最长100字节
     */
    faceURL?: string;
    /**
     * 申请进群是否需要管理员审批：工作群（Work）默认值为 V2TIM_GROUP_ADD_FORBID，即默认不允许申请入群，您可以修改该字段打开申请入群方式。
     */
    groupAddOpt?: V2TIMGroupAddOpt;
    /**
     * 邀请进群是否需要管理员审批 （从 7.1 版本开始支持）
     * - 除工作群（Work）之外的其他群类型默认值都为 V2TIM_GROUP_ADD_FORBID，即默认不允许邀请入群，您可以修改该字段打开邀请入群方式。
     * - 直播群、社群和话题默认不允许邀请入群，也不支持修改。
     */
    groupApproveOpt?: V2TIMGroupAddOpt;
}
/**
 * 群资料
 */
export interface V2TIMSetGroupInfoParam {
    /**
     * 群组 ID
     * 自定义群组 ID 必须为可打印 ASCII 字符（0x20-0x7e），最长48个字节，且前缀不能为
     * @TGS#（避免与默认分配的群组 ID 混淆）
     */
    groupID: string;
    /**
     * 群名称
     * 群名称最长30字节
     */
    groupName?: string;
    /**
     * 群公告
     * 群公告最长300字节
     */
    notification?: string;
    /**
     * 群简介
     * 群简介最长240字节
     */
    introduction?: string;
    /**
     * 群头像
     * 群头像 URL 最长100字节
     */
    faceURL?: string;
    /**
     * 是否全员禁言
     */
    allMuted?: boolean;
    /**
     * 设置群自定义字段需要两个步骤：
     * 1.在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 群自定义字段)
     * 配置群自定义字段的 key 值，Key 为 string 类型，长度不超过 16 字节。 2.调用 SetGroupInfo
     * 接口设置该字段，value 为 V2TIMSBuffer 数据，长度不超过 512 字节。
     */
    customInfo?: Map<string, ArrayBuffer>;
    /**
     * 申请进群是否需要管理员审批：工作群（Work）默认值为 V2TIM_GROUP_ADD_FORBID，即默认不允许申请入群，您可以修改该字段打开申请入群方式。
     */
    groupAddOpt?: V2TIMGroupAddOpt;
    /**
     * 邀请进群是否需要管理员审批 （从 7.1 版本开始支持）
     * - 除工作群（Work）之外的其他群类型默认值都为 V2TIM_GROUP_ADD_FORBID，即默认不允许邀请入群，您可以修改该字段打开邀请入群方式。
     * - 直播群、社群和话题默认不允许邀请入群，也不支持修改。
     */
    groupApproveOpt?: V2TIMGroupAddOpt;
}
/**
 * 获取群组资料结果
 */
export declare class V2TIMGroupInfoResult {
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
    info: V2TIMGroupInfo;
}
/**
 * 群申请信息
 */
export declare class V2TIMGroupApplication {
    /**
     * 群组 ID
     */
    groupID: string;
    /**
     * 请求者 userID
     */
    fromUser: string;
    /**
     * 请求者昵称
     */
    fromUserNickName: string;
    /**
     * 请求者头像
     */
    fromUserFaceUrl: string;
    /**
     * 判决者id，有人请求加群:0，邀请其他人加群:被邀请人用户 ID
     */
    toUser: string;
    /**
     * 申请时间
     */
    addTime: number;
    /**
     * 申请或邀请附加信息
     */
    requestMsg: string;
    /**
     * 审批信息：同意或拒绝信息
     */
    handledMsg: string;
    /**
     * 请求类型
     */
    applicationType: V2TIMGroupApplicationType;
    /**
     * 处理标志
     */
    handleStatus: V2TIMGroupApplicationHandleStatus;
    /**
     * 处理结果
     */
    handleResult: V2TIMGroupApplicationHandleResult;
}
/**
 * 邀请其他人入群的操作结果
 */
export declare class V2TIMGroupMemberOperationResult {
    /**
     * 被操作成员
     */
    userID: string;
    /**
     * 返回状态
     */
    result: V2TIMGroupMemberResult;
}
/**
 * 创建群时指定群成员
 */
export interface V2TIMCreateGroupMemberInfo {
    /**
     * 被操作成员
     */
    userID: string;
    /**
     * 群成员类型，需要注意一下事项：
     * 1. role 不设置或则设置为 V2TIM_GROUP_MEMBER_UNDEFINED，进群后默认为群成员。
     * 2. 工作群（Work）不支持设置 role 为管理员。
     * 3. 所有的群都不支持设置 role 为群主。
     */
    role?: number;
}
/**
 * 加群申请列表
 */
export declare class V2TIMGroupApplicationResult {
    /**
     * 未读的申请数量
     */
    unreadCount: number;
    /**
     * 加群申请的列表
     */
    applicationList: V2TIMGroupApplication[];
}
/**
 * 群搜索的参数
 */
export interface V2TIMGroupSearchParam {
    /**
     * 搜索关键字列表，最多支持5个。
     * 如果是本地搜索，您需主动设置 keyword 是否匹配群 ID、群名称。
     * 如果是云端搜索，keyword 会自动匹配群 ID、群名称。
     */
    keywordList?: string[];
    /**
     * 设置是否搜索群 ID（仅本地搜索有效）
     */
    isSearchGroupID?: boolean;
    /**
     * 设置是否搜索群名称（仅本地搜索有效）
     */
    isSearchGroupName?: boolean;
    /**
     * 指定关键字列表匹配类型，可设置为“或”关系搜索或者“与”关系搜索（仅云端搜索有效）
     * 取值分别为 V2TIM_KEYWORD_LIST_MATCH_TYPE_OR 和 V2TIM_KEYWORD_LIST_MATCH_TYPE_AND，默认为“或”关系搜索。
     */
    keywordListMatchType?: V2TIMKeywordListMatchType;
    /**
     * 每次云端搜索返回结果的条数（必须大于 0，最大支持 100，默认 20，仅云端搜索有效）
     */
    searchCount?: number;
    /**
     * 每次云端搜索的起始位置。第一次填空字符串，续拉时填写 V2TIMGroupSearchResult 中的返回值（仅云端搜索有效）
     */
    searchCursor?: string;
}
/**
 * 群搜索结果的参数
 */
export declare class V2TIMGroupSearchResult {
    /**
     * 满足搜索条件的群列表是否已经全部返回
     */
    isFinished?: boolean;
    /**
     * 满足搜索条件的群总数量
     */
    totalCount?: number;
    /**
     * 下一次云端搜索的起始位置
     */
    nextCursor?: string;
    /**
     * 当前一次云端搜索返回的群列表
     */
    groupList?: [V2TIMGroupInfo];
}
/**
 * 搜索群成员的参数
 */
export interface V2TIMGroupMemberSearchParam {
    /**
     * 搜索关键字列表，最多支持5个
     * 如果是本地搜索，您需主动设置 keyword 是否匹配群成员 ID、昵称、备注、群名片。
     * 如果是云端搜索，keyword 会自动匹配群成员 ID、昵称、群名片。
     */
    keywordList?: string[];
    /**
     * 指定群 ID 列表，若为空的 string[] 则搜索全部群中的群成员
     */
    groupIDList?: string[];
    /**
     * 设置是否搜索群成员 userID（仅本地搜索有效）
     */
    isSearchMemberUserID?: boolean;
    /**
     * 设置是否搜索群成员昵称（仅本地搜索有效）
     */
    isSearchMemberNickName?: boolean;
    /**
     * 设置是否搜索群成员备注（仅本地搜索有效）
     */
    isSearchMemberRemark?: boolean;
    /**
     * 设置是否搜索群成员名片（仅本地搜索有效）
     */
    isSearchMemberNameCard?: boolean;
    /**
     * 指定关键字列表匹配类型，可设置为“或”关系搜索或者“与”关系搜索（仅云端搜索有效）
     * 取值分别为 V2TIM_KEYWORD_LIST_MATCH_TYPE_OR 和 V2TIM_KEYWORD_LIST_MATCH_TYPE_AND，默认为“或”关系搜索。
     */
    keywordListMatchType?: V2TIMKeywordListMatchType;
    /**
     * 每次云端搜索返回结果的条数（必须大于 0，最大支持 100，默认 20，仅云端搜索有效）
     */
    searchCount?: number;
    /**
     * 每次云端搜索的起始位置。第一次填空字符串，续拉时填写 V2TIMGroupMemberSearchResult 中的返回值（仅云端搜索有效）
     */
    searchCursor?: string;
}
/**
 * 群成员搜索结果的参数
 */
export declare class V2TIMGroupMemberSearchResult {
    /**
     * 满足搜索条件的群成员列表是否已经全部返回
     */
    isFinished?: boolean;
    /**
     * 满足搜索条件的群成员总数量
     */
    totalCount?: number;
    /**
     * 下一次云端搜索的起始位置
     */
    nextCursor?: string;
    /**
     * 当前一次云端搜索返回的群成员列表
     */
    memberList?: Map<string, V2TIMGroupMemberFullInfo[]>;
}
