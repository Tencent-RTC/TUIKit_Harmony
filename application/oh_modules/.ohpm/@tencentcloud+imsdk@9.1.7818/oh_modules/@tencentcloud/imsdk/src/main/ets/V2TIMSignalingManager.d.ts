/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 */
import { V2TIMSignalingListener, V2TIMOfflinePushInfo, V2TIMMessage, V2TIMSignalingInfo } from "../../../Index";
/**
 * 腾讯云通信服务 IMSDK
 *
 * 消息高级接口，里面包含了所有高级消息的创建、收发逻辑
 */
export declare class V2TIMSignalingManager {
    /**
     * 添加信令监听
     */
    addSignalingListener(listener: V2TIMSignalingListener): void;
    /**
     * 移除信令监听
     */
    removeSignalingListener(listener: V2TIMSignalingListener): void;
    /**
     * 邀请某个人
     *
     * @param invitee 被邀请人用户 ID
     * @param data 自定义数据
     * @param onlineUserOnly 是否只有在线用户才能收到邀请，如果设置为 true，只有在线用户才能收到，
     *                     并且 Invite 操作也不会产生历史消息（针对该次 Invite 的后续
     * Cancel、Accept、Reject、Timeout 操作也同样不会产生历史消息）。
     * @param offlinePushInfo 离线推送信息，其中 desc 为必填字段，推送的时候会默认展示 desc 信息。
     * @param timeout 超时时间，单位秒，如果设置为 0，SDK 不会做超时检测，也不会触发
     * onInvitationTimeout 回调
     * @return inviteID 邀请 ID，如果邀请失败，返回空字符串
     */
    invite(invitee: string, data: string, onlineUserOnly: boolean, offlinePushInfo: V2TIMOfflinePushInfo, timeout: number): {
        inviteID: string;
        promise: Promise<void>;
    };
    /**
     * 邀请群内的某些人
     *
     * @param groupID   发起邀请所在群组
     * @param inviteeList 被邀请人列表，inviteeList 必须已经在 groupID 群里，否则邀请无效
     * @param onlineUserOnly 是否只有在线用户才能收到邀请，如果设置为 true，只有在线用户才能收到，
     *                     并且 Invite 操作也不会产生历史消息（针对该次 Invite 的后续
     * Cancel、Accept、Reject、Timeout 操作也同样不会产生历史消息）。
     * @param timeout 超时时间，单位秒，如果设置为 0，SDK 不会做超时检测，也不会触发
     * onInvitationTimeout 回调
     * @return inviteID 邀请 ID，如果邀请失败，返回空字符串
     *
     * @note
     * 群邀请暂不支持离线推送，如果您需要离线推送，可以针对被邀请的用户单独发离线推送自定义消息，
     * 详细代码请参考 TRTCAVCallImpl -> sendOnlineMessageWithOfflinePushInfo 函数。
     */
    inviteInGroup(groupID: string, inviteeList: string[], data: string, onlineUserOnly: boolean, timeout: number): {
        inviteID: string;
        promise: Promise<void>;
    };
    /**
     * 邀请方取消邀请
     *
     * @param inviteID 邀请 ID
     *
     * @note 如果所有被邀请人都已经处理了当前邀请（包含超时），不能再取消当前邀请。
     */
    cancel(inviteID: string, data: string): Promise<void>;
    /**
     * 接收方接收邀请
     *
     * @note 不能接受不是针对自己的邀请，请在收到 OnReceiveNewInvitation 回调的时候先判断
     * inviteeList 有没有自己，如果没有自己，不能 Accept 邀请。
     */
    accept(inviteID: string, data: string): Promise<void>;
    /**
     * 接收方拒绝邀请
     *
     * @note 不能拒绝不是针对自己的邀请，请在收到 OnReceiveNewInvitation 回调的时候先判断
     * inviteeList 有没有自己，如果没有自己，不能 Reject 邀请。
     */
    reject(inviteID: string, data: string): Promise<void>;
    /**
     * 获取信令信息
     *
     * 如果 Invite 设置 onlineUserOnly 为 false，每次信令操作（包括
     * Invite、Cancel、Accept、Reject、Timeout）都会产生一条自定义消息， 该消息会通过
     * V2TIMAdvancedMsgListener -> onRecvNewMessage
     * 抛给用户，用户也可以通过历史消息拉取，如果需要根据信令信息做自定义化文本展示，可以调用下面接口获取信令信息。
     *
     * @param msg 消息对象
     * @return V2TIMSignalingInfo 信令信息，如果为 undefined，则 msg 不是一条信令消息。
     */
    getSignalingInfo(msg: V2TIMMessage): V2TIMSignalingInfo;
    /**
     * 修改邀请信令（6.7 及其以上版本支持）
     *
     * @note 仅支持修改邀请信令的自定义字段 data。只有在线用户才能收到的邀请信令不能被修改。
     */
    modifyInvitation(inviteID: string, data: string): Promise<void>;
}
