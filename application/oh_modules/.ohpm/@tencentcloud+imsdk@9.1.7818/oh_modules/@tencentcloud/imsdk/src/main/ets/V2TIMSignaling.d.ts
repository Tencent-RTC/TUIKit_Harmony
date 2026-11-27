/**
* Copyright (c) 2023 Tencent. All rights reserved.
*/
/**
 * （一）枚举值定义
 */
/**
 * 操作类型
 */
export declare enum V2TIMSignalingActionType {
    /**
     * 邀请方发起邀请
     */
    SignalingActionType_Invite = 1,
    /**
     * 邀请方取消邀请
     */
    SignalingActionType_Cancel_Invite = 2,
    /**
     * 被邀请方接受邀请
     */
    SignalingActionType_Accept_Invite = 3,
    /**
     * 被邀请方拒绝邀请
     */
    SignalingActionType_Reject_Invite = 4,
    /**
     * 邀请超时
     */
    SignalingActionType_Invite_Timeout = 5
}
/**
 * （二）结构体定义
 */
export declare class V2TIMSignalingInfo {
    /**
     * 信令ID
     */
    inviteID: string;
    /**
     * 如果是群组信令，groupID 为会话群组ID，否则为空
     */
    groupID: string;
    /**
     * 邀请方的ID
     */
    inviter: string;
    /**
     * 被邀请方列表
     */
    inviteeList: string[];
    /**
     * 信令内容
     */
    data: string;
    /**
     * 信令操作类型
     */
    actionType: V2TIMSignalingActionType;
    /**
     * 信令超时时间
     */
    timeout: number;
}
