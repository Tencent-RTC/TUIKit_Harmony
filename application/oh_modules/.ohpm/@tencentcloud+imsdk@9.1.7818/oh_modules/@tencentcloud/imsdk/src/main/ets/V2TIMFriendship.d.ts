/**
* Copyright (c) 2023 Tencent. All rights reserved.
*/
import { V2TIMKeywordListMatchType } from "../../../Index";
/**
 * （一）枚举值定义
 */
/**
 * 用户状态类型
 */
export declare enum V2TIMUserStatusType {
    /**
     * 未知状态
     */
    V2TIM_USER_STATUS_UNKNOWN = 0,
    /**
     * 在线状态
     */
    V2TIM_USER_STATUS_ONLINE = 1,
    /**
     * 离线状态
     */
    V2TIM_USER_STATUS_OFFLINE = 2,
    /**
     * 未登录（如主动调用 logout 接口，或者账号注册后还未登录）
     */
    V2TIM_USER_STATUS_UNLOGINED = 3
}
/**
 * 性别
 */
export declare enum V2TIMGender {
    /**
     * 未知性别
     */
    V2TIM_GENDER_UNKNOWN = 0,
    /**
     * 男性
     */
    V2TIM_GENDER_MALE = 1,
    /**
     * 女性
     */
    V2TIM_GENDER_FEMALE = 2
}
/**
 * 好友验证方式
 */
export declare enum V2TIMFriendAllowType {
    /**
     * 同意任何用户加好友
     */
    V2TIM_FRIEND_ALLOW_ANY = 0,
    /**
     * 需要验证
     */
    V2TIM_FRIEND_NEED_CONFIRM = 1,
    /**
     * 拒绝任何人加好友
     */
    V2TIM_FRIEND_DENY_ANY = 2
}
/**
 * 好友申请类型
 */
export declare enum V2TIMFriendApplicationType {
    /**
     * 别人发给我的
     */
    V2TIM_FRIEND_APPLICATION_COME_IN = 1,
    /**
     * 我发给别人的
     */
    V2TIM_FRIEND_APPLICATION_SEND_OUT = 2,
    /**
     * 别人发给我的 和 我发给别人的。仅拉取时有效
     */
    V2TIM_FRIEND_APPLICATION_BOTH = 3
}
/**
 * 好友类型
 */
export declare enum V2TIMFriendType {
    /**
     * 单向好友
     */
    V2TIM_FRIEND_TYPE_SINGLE = 1,
    /**
     * 双向好友
     */
    V2TIM_FRIEND_TYPE_BOTH = 2
}
/**
 * 好友关系类型
 */
export declare enum V2TIMFriendRelationType {
    /**
     * 不是好友
     */
    V2TIM_FRIEND_RELATION_TYPE_NONE = 0,
    /**
     * 对方在我的好友列表中
     */
    V2TIM_FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST = 1,
    /**
     * 我在对方的好友列表中
     */
    V2TIM_FRIEND_RELATION_TYPE_IN_OTHER_FRIEND_LIST = 2,
    /**
     * 互为好友
     */
    V2TIM_FRIEND_RELATION_TYPE_BOTH_WAY = 3
}
/**
 * 好友申请接受类型
 */
export declare enum V2TIMFriendAcceptType {
    /**
     * 接受加好友（建立单向好友）
     */
    V2TIM_FRIEND_ACCEPT_AGREE = 0,
    /**
     * 接受加好友并加对方为好友（建立双向好友）
     */
    V2TIM_FRIEND_ACCEPT_AGREE_AND_ADD = 1
}
/**
 * 用户资料修改标记
 */
export declare enum V2TIMUserInfoModifyFlag {
    /**
     * 未定义
     */
    V2TIM_USER_INFO_MODIFY_FLAG_UNKNOWN = 0,
    /**
     * 昵称
     */
    V2TIM_USER_INFO_MODIFY_FLAG_NICK = 1,
    /**
     * 头像
     */
    V2TIM_USER_INFO_MODIFY_FLAG_FACE_URL = 2,
    /**
     * 性别
     */
    V2TIM_USER_INFO_MODIFY_FLAG_GENDER = 3,
    /**
     * 生日
     */
    V2TIM_USER_INFO_MODIFY_FLAG_BIRTHDAY = 4,
    /**
     * 修改签名
     */
    V2TIM_USER_INFO_MODIFY_FLAG_SELF_SIGNATURE = 7,
    /**
     * 等级
     */
    V2TIM_USER_INFO_MODIFY_FLAG_LEVEL = 8,
    /**
     * 角色
     */
    V2TIM_USER_INFO_MODIFY_FLAG_ROLE = 9,
    /**
     * 好友验证方式
     */
    V2TIM_USER_INFO_MODIFY_FLAG_ALLOW_TYPE = 10,
    /**
     * 自定义字段
     */
    V2TIM_USER_INFO_MODIFY_FLAG_CUSTOM = 11
}
/**
 * 好友资料修改标记
 */
export declare enum V2TIMFriendInfoModifyFlag {
    /**
     * 未定义
     */
    V2TIM_FRIEND_INFO_MODIFY_FLAG_UNKNOWN = 0,
    /**
     * 好友备注
     */
    V2TIM_FRIEND_INFO_MODIFY_FLAG_REMARK = 1,
    /**
     * 好友自定义字段
     */
    V2TIM_FRIEND_INFO_MODIFY_FLAG_CUSTOM = 2
}
/**
 * 好友资料修改标记
 */
declare enum V2TIMFollowType {
    /**
     * 无任何关注关系
     */
    V2TIM_FOLLOW_TYPE_NONE = 0,
    /**
     * 对方在我的关注列表中
     */
    V2TIM_FOLLOW_TYPE_IN_MY_FOLLOWING_LIST = 1,
    /**
     * 对方在我的粉丝列表中
     */
    V2TIM_FOLLOW_TYPE_IN_MY_FOLLOWERS_LIST = 2,
    /**
     * 对方与我互相关注
     */
    V2TIM_FOLLOW_TYPE_IN_BOTH_FOLLOWERS_LIST = 3
}
/**
 * （二）结构体定义
 */
/**
 * 用户基本资料
 */
export declare class V2TIMUserInfo {
    /**
     * 用户 ID
     */
    userID: string;
    /**
     * 用户昵称
     */
    nickName: string;
    /**
     * 用户头像
     */
    faceURL: string;
}
/**
 * 用户详细资料
 */
export declare class V2TIMUserFullInfo extends V2TIMUserInfo {
    /**
     * 用户签名
     */
    selfSignature: string;
    /**
     * 用户性别
     */
    gender: V2TIMGender;
    /**
     * 用户角色
     */
    role: number;
    /**
     * 用户等级
     */
    level: number;
    /**
     * 出生日期
     */
    birthday: number;
    /**
     * 用户好友验证方式
     */
    allowType: V2TIMFriendAllowType;
    /**
     * 用户自定义字段
     * 首先要在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 用户自定义字段)
     * 配置用户自定义字段，然后再调用该接口进行设置，key 值不需要加 Tag_Profile_Custom_ 前缀。
     */
    customInfo: Map<string, ArrayBuffer>;
}
/**
 * 用户详细资料
 */
export interface V2TIMSetSelfInfoParam {
    /**
     * 用户昵称
     */
    nickName?: string;
    /**
     * 用户头像
     */
    faceURL?: string;
    /**
     * 用户签名
     */
    selfSignature?: string;
    /**
     * 用户性别
     */
    gender?: V2TIMGender;
    /**
     * 用户角色
     */
    role?: number;
    /**
     * 用户等级
     */
    level?: number;
    /**
     * 出生日期
     */
    birthday?: number;
    /**
     * 用户好友验证方式
     */
    allowType?: V2TIMFriendAllowType;
    /**
     * 用户自定义字段
     * 首先要在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 用户自定义字段)
     * 配置用户自定义字段，然后再调用该接口进行设置，key 值不需要加 Tag_Profile_Custom_ 前缀。
     */
    customInfo?: Map<string, ArrayBuffer>;
}
/**
 * 用户搜索的参数
 */
export interface V2TIMUserSearchParam {
    /**
     * 搜索的关键字列表，关键字列表最多支持 5 个，keyword 会自动匹配用户 ID、昵称。
     */
    keywordList?: string[];
    /**
     * 指定关键字列表匹配类型，可设置为“或”关系搜索或者“与”关系搜索
     * 取值分别为 V2TIM_KEYWORD_LIST_MATCH_TYPE_OR 和 V2TIM_KEYWORD_LIST_MATCH_TYPE_AND，默认为“或”关系搜索。
     */
    keywordListMatchType?: V2TIMKeywordListMatchType;
    /**
     * 用户性别（如果不设置，默认男性和女性都会返回）
     */
    gender?: V2TIMGender;
    /**
     * 用户最小生日（如果不设置，默认值为 0）
     */
    minBirthday?: number;
    /**
     * 用户最大生日（如果不设置，默认 birthday >= minBirthday 的用户都会返回）
     */
    maxBirthday?: number;
    /**
     * 每次云端搜索返回结果的条数（必须大于 0，最大支持 100）
     */
    searchCount?: number;
    /**
     * 每次云端搜索的起始位置。第一次填空字符串，续拉时填写 V2TIMUserSearchResult 中的返回值。
     */
    searchCursor?: string;
}
/**
 * 用户搜索结果的参数
 */
export declare class V2TIMUserSearchResult {
    /**
     * 是否已经返回全部满足搜索条件的用户列表
     */
    isFinished?: boolean;
    /**
     * 满足搜索条件的用户总数量
     */
    totalCount?: number;
    /**
     * 下一次云端搜索的起始位置
     */
    nextCursor?: string;
    /**
     * 当前一次云端搜索返回的用户列表
     */
    userList?: [V2TIMUserInfo];
}
/**
 * 用户状态
 */
export declare class V2TIMUserStatus {
    /**
     * 用户的 ID
     */
    userID: string;
    /**
     * 用户的状态
     */
    statusType: V2TIMUserStatusType;
    /**
     * 用户的自定义状态, 最大 100 字节
     */
    customStatus: string;
    /**
     * 在线终端列表
     */
    onlineDevices: string[];
}
/**
 * 用户状态
 */
export interface V2TIMSetSelfStatusParam {
    /**
     * 用户的状态
     */
    statusType?: V2TIMUserStatusType;
    /**
     * 用户的自定义状态, 最大 100 字节
     */
    customStatus?: string;
}
/**
 * 好友资料
 */
export declare class V2TIMFriendInfo {
    /**
     * 好友 ID
     */
    userID: string;
    /**
     * 好友备注
     * 备注长度最长不得超过 96 个字节;
     * 字段描述详见
     * [控制台](https://cloud.tencent.com/document/product/269/1501#.E6.A0.87.E9.85.8D.E5.A5.BD.E5.8F.8B.E5.AD.97.E6.AE.B5)。
     */
    friendRemark: string;
    /**
     * 添加好友的 UTC 时间戳
     */
    friendAddTime: number;
    /**
    * 好友自定义字段
    * 首先要在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 好友自定义字段)
    * 配置好友自定义字段，然后再调用该接口进行设置，key 值不需要加 Tag_SNS_Custom_ 前缀。
    friendCustomInfo: Map<string, ArrayBuffer>;
    * 好友所在分组列表
    * - 最多支持 32 个分组；
    * - 不允许分组名为空；
    * - 分组名长度不得超过 30 个字节；
    * - 同一个好友可以有多个不同的分组。
    * - 字段描述详见
    * [控制台](https://cloud.tencent.com/document/product/269/1501#.E6.A0.87.E9.85.8D.E5.A5.BD.E5.8F.8B.E5.AD.97.E6.AE.B5)。
  */
    friendGroups: string[];
    /**
     * 好友个人资料
     */
    userFullInfo: V2TIMUserFullInfo;
}
/**
 * 好友资料
 */
export interface V2TIMSetFriendInfoParam {
    /**
     * 好友 ID
     */
    userID: string;
    /**
     * 好友备注
     * 备注长度最长不得超过 96 个字节;
     * 字段描述详见
     * [控制台](https://cloud.tencent.com/document/product/269/1501#.E6.A0.87.E9.85.8D.E5.A5.BD.E5.8F.8B.E5.AD.97.E6.AE.B5)。
     */
    friendRemark?: string;
    /**
     * 好友自定义字段
     * 首先要在 [控制台](https://console.cloud.tencent.com/im) (功能配置 -> 好友自定义字段)
     * 配置好友自定义字段，然后再调用该接口进行设置，key 值不需要加 Tag_SNS_Custom_ 前缀。
     */
    friendCustomInfo?: Map<string, ArrayBuffer>;
}
/**
 * 好友资料获取结果
 */
export declare class V2TIMFriendInfoResult {
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回结果表述
     */
    resultInfo: string;
    /**
     * 好友类型
     */
    relation: V2TIMFriendRelationType;
    /**
     * 好友个人资料，如果不是好友，除了 userID 字段，其他字段都为空
     */
    friendInfo: V2TIMFriendInfo;
}
/**
 * 加好友
 */
export interface V2TIMFriendAddApplication {
    /**
     * 用户 userID（必填）
     */
    userID: string;
    /**
     * 备注（备注最大96字节）
     */
    friendRemark?: string;
    /**
     * 预分组名（最大96字节）
     */
    friendGroup?: string;
    /**
     * 请求说明（最大120字节）
     */
    addWording?: string;
    /**
     * 添加来源
     */
    addSource?: string;
    /**
     * 加好友方式
     */
    addType?: V2TIMFriendType;
}
/**
 * 好友申请
 */
export declare class V2TIMFriendApplication {
    /**
     * 用户标识
     */
    userID: string;
    /**
     * 用户昵称
     */
    nickName: string;
    /**
     * 用户头像
     */
    faceUrl: string;
    /**
     * 添加好友的 UTC 时间戳
     */
    addTime: number;
    /**
     * 来源
     */
    addSource: string;
    /**
     * 加好友附言
     */
    addWording: string;
    /**
     * 好友申请类型
     */
    type: V2TIMFriendApplicationType;
}
/**
 * 好友申请列表
 */
export declare class V2TIMFriendApplicationResult {
    /**
     * 好友申请未读数量
     */
    unreadCount: number;
    /**
     * 好友申请列表
     */
    applicationList: V2TIMFriendApplication[];
}
/**
 * 好友关系链检查结果
 */
export declare class V2TIMFriendCheckResult {
    /**
     * 用户id
     */
    userID: string;
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 检查结果
     */
    relationType: V2TIMFriendRelationType;
}
/**
 * 好友操作结果（添加、删除、加黑名单、添加分组等）
 */
export declare class V2TIMFriendOperationResult {
    /**
     * 用户Id
     */
    userID: string;
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
}
/**
 * 好友分组
 */
export declare class V2TIMFriendGroup {
    /**
     * 好友分组名称
     */
    groupName: string;
    /**
     * 分组成员数量
     */
    userCount: number;
    /**
     * 分组成员列表
     */
    friendList: string[];
}
/**
 * 好友搜索
 */
export interface V2TIMFriendSearchParam {
    /**
     * 搜索的关键字列表，关键字列表最多支持 5 个
     */
    keywordList?: string[];
    /**
     * 设置是否搜索 userID
     */
    isSearchUserID?: boolean;
    /**
     * 是否设置搜索昵称
     */
    isSearchNickName?: boolean;
    /**
     * 是否设置搜索备注
     */
    isSearchRemark?: boolean;
}
/**
 * 公众号资料
 */
export declare class V2TIMOfficialAccountInfo {
    /**
     * 公众号 ID
     */
    officialAccountID: string;
    /**
     * 公众号名称
     */
    officialAccountName: string;
    /**
     * 公众号头像
     */
    faceUrl: string;
    /**
     * 公众号所有者
     */
    ownerUserID: string;
    /**
     * 公众号组织
     */
    organization: string;
    /**
     * 公众号简介
     */
    introduction: string;
    /**
     * 公众号自定义数据
     */
    customData: string;
    /**
     * 公众号创建时间，单位：秒
     */
    createTime: number;
    /**
     * 公众号订阅者数量
     */
    subscriberCount: number;
    /**
     * 订阅公众号的时间，单位：秒
     */
    subscribeTime: number;
}
/**
 * 公众号资料获取结果
 */
export declare class V2TIMOfficialAccountInfoResult {
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 返回信息
     */
    accountInfo: V2TIMOfficialAccountInfo;
}
/**
 * 关注/取关用户的操作结果
 */
export declare class V2TIMFollowOperationResult {
    /**
     * 用户ID
     */
    userID: string;
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
}
/**
 * 获取 关注/粉丝/互关 列表的结果
 * 获取 关注/粉丝/互关 列表的结果
 */
export declare class V2TIMUserInfoResult {
    /**
     * 获取分页拉取的 cursor。如果为 "" 表示拉取结束
     */
    nextCursor: string;
    /**
     * 用户信息列表
     */
    userInfoList: V2TIMUserFullInfo[];
}
/**
 * 用户关注数量信息获取结果
 */
export declare class V2TIMFollowInfo {
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 用户ID
     */
    userID: string;
    /**
     * 用户的关注数量
     */
    followingCount: number;
    /**
     * 用户的粉丝数量
     */
    followersCount: number;
    /**
     * 用户的互关数量
     */
    mutualFollowersCount: number;
}
/**
 * 用户的关注类型检查结果
 */
export declare class V2TIMFollowTypeCheckResult {
    /**
     * 用户ID
     */
    userID: string;
    /**
     * 返回码
     */
    resultCode: number;
    /**
     * 返回信息
     */
    resultInfo: string;
    /**
     * 关注类型
     */
    followType: V2TIMFollowType;
}
export {};
