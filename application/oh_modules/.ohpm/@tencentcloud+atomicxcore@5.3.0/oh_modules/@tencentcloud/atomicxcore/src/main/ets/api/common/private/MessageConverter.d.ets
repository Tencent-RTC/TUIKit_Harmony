import { V2TIMGroupMemberInfo, V2TIMGroupTipsElem, V2TIMMessage, V2TIMMessageExtension, V2TIMMessageReaction, V2TIMMessageReceipt, V2TIMReceiveMessageOpt, V2TIMUserFullInfo, V2TIMUserInfo } from '@tencentcloud/imsdk';
import { GroupMember } from '../../group/GroupMemberStore';
import { UserProfile } from '../../login/LoginStore';
import { GroupTipsInfo, MessageExtension, MessageInfo, MessagePayload, MessageReaction, MessageReceipt } from '../../message/MessageListStore';
import { ReceiveMessageOption } from '../../conversation/ConversationListStore';
export declare class MessageConverter {
    static convertToUIMessage(imMessage: V2TIMMessage): MessageInfo;
    static getMessageBody(imMessage: V2TIMMessage): MessagePayload | undefined;
    static convertToSystemInfoFromGroupTips(tipsElem: V2TIMGroupTipsElem): GroupTipsInfo[];
    static convertToSystemInfoFromGroupInfoChangedList(_opUser: string, _userList: string[], tipsElem: V2TIMGroupTipsElem): GroupTipsInfo[];
    static convertToSystemInfoFromRecall(message: V2TIMMessage, operateUser?: V2TIMUserInfo, reason?: string): MessageInfo;
    static getMemberShowName(info?: V2TIMGroupMemberInfo): string;
    static getMemberShowNameFromTips(tips?: V2TIMGroupTipsElem, userId?: string): string;
    static getMembersShowName(infoList?: V2TIMGroupMemberInfo[]): string[];
    static getMessageSenderName(message?: MessageInfo): string;
    static parseCustomMessageData(data?: ArrayBuffer): Record<string, string | number | boolean | object> | null;
    static getUserID(conversationID: string): string | null;
    static getGroupID(conversationID: string): string | null;
    static convertToMessageReceipt(v2Receipt: V2TIMMessageReceipt): MessageReceipt;
    static convertToGroupMember(v2Member: V2TIMGroupMemberInfo): GroupMember;
    static convertToMessageReactions(v2Reactions: V2TIMMessageReaction[]): MessageReaction[];
    static convertToMessageExtensions(v2Extensions: V2TIMMessageExtension[]): MessageExtension[];
    static convertToUserProfile(v2UserInfo: V2TIMUserInfo): UserProfile;
    static convertToUserFullProfile(v2UserInfo: V2TIMUserFullInfo): UserProfile;
    static convertToV2TIMReceiveMessageOpt(opt: ReceiveMessageOption): V2TIMReceiveMessageOpt;
    static convertToUIReceiveMessageOpt(v2Opt?: V2TIMReceiveMessageOpt): ReceiveMessageOption;
}
