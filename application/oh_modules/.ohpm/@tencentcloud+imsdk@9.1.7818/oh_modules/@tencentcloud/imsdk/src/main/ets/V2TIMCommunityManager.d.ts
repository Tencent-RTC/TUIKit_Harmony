/**
 * Copyright (c) 2024 Tencent. All rights reserved.
 */
import { V2TIMCreateGroupInfo, V2TIMSetTopicInfoParam, V2TIMCreateTopicInCommunityParam, V2TIMCreatePermissionGroupInCommunityParam, V2TIMModifyPermissionGroupInfoInCommunityParam, V2TIMCreateGroupMemberInfo, V2TIMGroupInfo, V2TIMTopicInfoResult, V2TIMTopicOperationResult, V2TIMCommunityListener, V2TIMPermissionGroupOperationResult, V2TIMPermissionGroupInfoResult, V2TIMPermissionGroupMemberOperationResult, V2TIMPermissionGroupMemberInfoResult, V2TIMTopicPermissionResult } from "../../../Index";
/**
 * 腾讯云通信服务 IMSDK
 *
 * 社群接口，里面包含了社群相关的功能，比如创建话题，修改话题等操作接口。
 */
export declare class V2TIMCommunityManager {
    /**
     * 社群监听
     */
    /**
     * 1.1 添加社群监听器
     */
    addCommunityListener(listener: V2TIMCommunityListener): void;
    /**
     * 1.2 移除社群监听器
     */
    removeCommunityListener(listener: V2TIMCommunityListener): void;
    /**
     * 社群接口
     */
    /**
     * 1.1 创建支持话题的社群
     */
    createCommunity(info: V2TIMCreateGroupInfo, memberList: V2TIMCreateGroupMemberInfo[]): Promise<string>;
    /**
     * 1.2 获取当前用户已经加入的支持话题的社群列表
     */
    getJoinedCommunityList(): Promise<V2TIMGroupInfo[]>;
    /**
     * 1.3 创建话题
     *
     * @param groupID 社群 ID，必须以 @TGS#_ 开头。
     */
    createTopicInCommunity(groupID: string, topicInfo: V2TIMCreateTopicInCommunityParam): Promise<string>;
    /**
     * 1.4 删除话题
     */
    deleteTopicFromCommunity(groupID: string, topicIDList: string[]): Promise<V2TIMTopicOperationResult[]>;
    /**
     * 1.5 修改话题信息
     */
    setTopicInfo(topicInfo: V2TIMSetTopicInfoParam): Promise<void>;
    /**
     * 1.6 获取话题列表。
     * @note: topicIDList 传空时，获取此社群下的所有话题列表
     */
    getTopicInfoList(groupID: string, topicIDList: string[]): Promise<V2TIMTopicInfoResult[]>;
    /**
     * 权限组相关的接口
     */
    /**
     * 3.1 创建社群权限组（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    createPermissionGroupInCommunity(info: V2TIMCreatePermissionGroupInCommunityParam): Promise<string>;
    /**
     * 3.2 删除社群权限组（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    deletePermissionGroupFromCommunity(groupID: string, permissionGroupIDList: string[]): Promise<V2TIMPermissionGroupOperationResult[]>;
    /**
     * 3.3 修改社群权限组（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    modifyPermissionGroupInfoInCommunity(info: V2TIMModifyPermissionGroupInfoInCommunityParam): Promise<void>;
    /**
     * 3.4 获取已加入的社群权限组列表（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    getJoinedPermissionGroupListInCommunity(groupID: string): Promise<V2TIMPermissionGroupInfoResult[]>;
    /**
     * 3.5 获取社群权限组列表（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     * - permissionGroupIDList 为空时，获取所有的权限组列表；不为空时，获取指定的权限组列表。
     */
    getPermissionGroupListInCommunity(groupID: string, permissionGroupIDList: string[]): Promise<V2TIMPermissionGroupInfoResult[]>;
    /**
     * 3.6 向社群权限组添加成员（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    addCommunityMembersToPermissionGroup(groupID: string, permissionGroupID: string, memberList: string[]): Promise<V2TIMPermissionGroupMemberOperationResult[]>;
    /**
     * 3.7 从社群权限组删除成员（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    removeCommunityMembersFromPermissionGroup(groupID: string, permissionGroupID: string, memberList: string[]): Promise<V2TIMPermissionGroupMemberOperationResult[]>;
    /**
     * 3.8 获取社群权限组成员列表（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    getCommunityMemberListInPermissionGroup(groupID: string, permissionGroupID: string, nextCursor: string): Promise<V2TIMPermissionGroupMemberInfoResult>;
    /**
     * 3.9 向权限组添加话题权限（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    addTopicPermissionToPermissionGroup(groupID: string, permissionGroupID: string, topicPermissionMap: Map<string, number>): Promise<V2TIMTopicOperationResult[]>;
    /**
     * 3.10 从权限组中删除话题权限（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    deleteTopicPermissionFromPermissionGroup(groupID: string, permissionGroupID: string, topicIDList: string[]): Promise<V2TIMTopicOperationResult[]>;
    /**
     * 3.11 修改权限组中的话题权限（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    modifyTopicPermissionInPermissionGroup(groupID: string, permissionGroupID: string, topicPermissionMap: Map<string, number>): Promise<V2TIMTopicOperationResult[]>;
    /**
     * 3.12 获取权限组中的话题权限（7.8 及其以上版本支持）
     * @note
     * - 该功能为旗舰版功能，需要您购买旗舰版套餐。
     */
    getTopicPermissionInPermissionGroup(groupID: string, permissionGroupID: string, topicIDList: string[]): Promise<V2TIMTopicPermissionResult[]>;
}
