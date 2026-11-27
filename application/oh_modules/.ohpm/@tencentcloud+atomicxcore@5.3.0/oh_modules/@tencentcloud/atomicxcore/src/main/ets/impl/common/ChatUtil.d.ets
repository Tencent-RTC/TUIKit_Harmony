import { V2TIMGroupMemberInfo, V2TIMGroupTipsElem, V2TIMMessage, V2TIMMessageExtension, V2TIMMessageReaction, V2TIMMessageReceipt, V2TIMUserFullInfo, V2TIMUserInfo } from '@tencentcloud/imsdk';
import { GroupMember } from '../../api/group/GroupMemberStore';
import { UserProfile } from '../../api/login/LoginStore';
import { MessageExtension, MessageInfo, MessagePayload, MessageReaction, MessageReceipt, MessageStatus, MessageType, GroupTipsInfo } from '../../api/message/MessageListStore';
export interface MediaPathResult {
    filePath: string;
    exists: boolean;
}
export declare class ChatUtil {
    static getHomePath(): string;
    static ensureDirectoryExists(dirPath: string): boolean;
    static getMediaHomePath(messageType: MessageType): string;
    static generateMediaPath(messageType: MessageType, extension?: string): string;
    static getActualMediaPath(messageType: MessageType, mediaPath?: string, uuid?: string, extension?: string): MediaPathResult;
    static formatFilePath(path: string): string;
    static getUserID(conversationID: string): string | null;
    static getGroupID(conversationID: string): string | null;
    static isCommunityGroup(groupID?: string | null): boolean;
    static getMemberShowName(info?: V2TIMGroupMemberInfo): string;
    static getMembersShowName(infoList?: V2TIMGroupMemberInfo[]): string[];
    static getMessageSenderName(message?: MessageInfo): string;
    static convertToUIMessage(imMessage: V2TIMMessage): MessageInfo;
    private static convertToMessageQuoteInfo;
    private static parseQuoteInfoFromCloudCustomData;
    static getMessagePayload(imMessage: V2TIMMessage): MessagePayload | undefined;
    static convertToUIMessageStatus(imMessage: V2TIMMessage): MessageStatus;
    static applyRevokeInfo(messageInfo: MessageInfo, message: V2TIMMessage, operateUser?: V2TIMUserInfo, reason?: string): void;
    static convertToSystemInfoFromGroupTips(tipsElem: V2TIMGroupTipsElem): GroupTipsInfo[];
    static convertSystemMessageListFromGroupInfoChangedInfo(opUser: GroupMember, tips: V2TIMGroupTipsElem): GroupTipsInfo[];
    static convertToMessageReceipt(v2Receipt: V2TIMMessageReceipt): MessageReceipt;
    static convertToGroupMember(v2Member: V2TIMGroupMemberInfo): GroupMember;
    static convertToMessageReactions(v2Reactions: V2TIMMessageReaction[]): MessageReaction[];
    static convertToMessageExtensions(v2Extensions: V2TIMMessageExtension[]): MessageExtension[];
    static convertToUserProfile(v2UserInfo: V2TIMUserInfo): UserProfile;
    static convertToUserFullProfile(v2UserInfo: V2TIMUserFullInfo): UserProfile;
    private static getMessageType;
    private static imagePrefix;
    private static convertToGroupJoinOption;
}
