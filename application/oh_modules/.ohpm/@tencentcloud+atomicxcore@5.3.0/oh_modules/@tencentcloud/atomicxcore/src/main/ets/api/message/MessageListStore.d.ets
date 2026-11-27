import { V2TIMMessage } from '@tencentcloud/imsdk';
import { CompletionHandler } from '../Define';
import BasicData from '../common/BasicData';
import { EventEmitter } from '../common/EventEmitter';
import { ConversationType } from '../conversation/ConversationListStore';
import { GroupInviteOption, GroupJoinOption } from '../group/GroupStore';
import { GroupMember } from '../group/GroupMemberStore';
import { UserProfile } from '../login/LoginStore';
import { SendMessageOption } from './MessageInputStore';
export declare abstract class MessageEvent {
}
export declare class OnReceiveNewMessage extends MessageEvent {
    message: MessageInfo;
    constructor(message: MessageInfo);
}
export declare class OnMessageReactionUpdated extends MessageEvent {
    message: MessageInfo;
    constructor(message: MessageInfo);
}
export declare class OnMessageRevoked extends MessageEvent {
    messageID: string;
    constructor(messageID: string);
}
export declare class OnMessageDeleted extends MessageEvent {
    messageIDList: string[];
    constructor(messageIDList: string[]);
}
export declare enum MessageStatus {
    INIT = 0,
    SENDING = 1,
    SEND_SUCCESS = 2,
    SEND_FAIL = 3,
    REVOKED = 4,
    DELETED = 5,
    LOCAL_IMPORTED = 6,
    VIOLATION = 7
}
export declare enum MessageType {
    UNKNOWN = 0,
    TEXT = 1,
    IMAGE = 2,
    VIDEO = 3,
    AUDIO = 4,
    FILE = 5,
    FACE = 6,
    TIPS = 7,
    CUSTOM = 8,
    MERGED = 9,
    STREAM = 10
}
export declare enum MessageListType {
    HISTORY = 0,
    PINNED = 1
}
export declare enum MessageLoadDirection {
    OLDER = 0,
    NEWER = 1,
    BOTH = 2
}
export declare enum MessageForwardType {
    SEPARATE = 0,
    MERGED = 1
}
@Observed
export declare class MessageSenderInfo {
    userID: string;
    avatarURL?: string;
    nickname?: string;
    friendRemark?: string;
    nameCard?: string;
    constructor(userID?: string, avatarURL?: string, nickname?: string, friendRemark?: string, nameCard?: string);
}
@Observed
export declare class MessagePayload {
}
@Observed
export declare class TextMessagePayload extends MessagePayload {
    text: string;
    translateLanguage?: string;
    translatedText?: Map<string, string>;
    constructor(text?: string, translateLanguage?: string, translatedText?: Map<string, string>);
}
@Observed
export declare class ImageMessagePayload extends MessagePayload {
    originalImageWidth: number;
    originalImageHeight: number;
    originalImageSize: number;
    originalImagePath?: string;
    originalImageURL?: string;
    largeImagePath?: string;
    largeImageURL?: string;
    thumbImagePath?: string;
    thumbImageURL?: string;
}
@Observed
export declare class VideoMessagePayload extends MessagePayload {
    videoSnapshotWidth: number;
    videoSnapshotHeight: number;
    videoSnapshotPath?: string;
    videoSnapshotURL?: string;
    videoType?: string;
    videoSize: number;
    videoDuration: number;
    videoPath?: string;
    videoURL?: string;
}
@Observed
export declare class AudioMessagePayload extends MessagePayload {
    audioSize: number;
    audioDuration: number;
    audioPath?: string;
    audioURL?: string;
    asrLanguage?: string;
    asrText?: string;
}
@Observed
export declare class FileMessagePayload extends MessagePayload {
    fileName?: string;
    fileSize: number;
    filePath?: string;
    fileURL?: string;
}
@Observed
export declare class FaceMessagePayload extends MessagePayload {
    faceIndex: number;
    faceData?: string;
}
@Observed
export declare class TipsMessagePayload extends MessagePayload {
    groupTips?: GroupTipsInfo[];
}
@Observed
export declare class CustomMessagePayload extends MessagePayload {
    customData: string;
    description?: string;
    extensionInfo?: string;
}
@Observed
export declare class MergedMessagePayload extends MessagePayload {
    title: string;
    abstractList?: string[];
}
@Observed
export declare class StreamMessagePayload extends MessagePayload {
    markdown: string;
    data: string;
    isStreamEnded: boolean;
}
export declare abstract class GroupTipsInfo {
}
export declare class Unknown extends GroupTipsInfo {
}
export declare class JoinGroup extends GroupTipsInfo {
    joinMember: GroupMember;
    constructor(joinMember: GroupMember);
}
export declare class InviteToGroup extends GroupTipsInfo {
    inviter: GroupMember;
    invitees: GroupMember[];
    constructor(inviter: GroupMember, invitees?: GroupMember[]);
}
export declare class QuitGroup extends GroupTipsInfo {
    quitMember: GroupMember;
    constructor(quitMember: GroupMember);
}
export declare class KickedFromGroup extends GroupTipsInfo {
    opUser: GroupMember;
    kickedMembers: GroupMember[];
    constructor(opUser: GroupMember, kickedMembers?: GroupMember[]);
}
export declare class SetGroupAdmin extends GroupTipsInfo {
    opUser: GroupMember;
    setAdminMembers: GroupMember[];
    constructor(opUser: GroupMember, setAdminMembers?: GroupMember[]);
}
export declare class CancelGroupAdmin extends GroupTipsInfo {
    opUser: GroupMember;
    cancelAdminMembers: GroupMember[];
    constructor(opUser: GroupMember, cancelAdminMembers?: GroupMember[]);
}
export declare class ChangeGroupName extends GroupTipsInfo {
    opUser: GroupMember;
    groupName: string;
    constructor(opUser: GroupMember, groupName: string);
}
export declare class ChangeGroupAvatar extends GroupTipsInfo {
    opUser: GroupMember;
    groupAvatar: string;
    constructor(opUser: GroupMember, groupAvatar: string);
}
export declare class ChangeGroupNotification extends GroupTipsInfo {
    opUser: GroupMember;
    groupNotification: string;
    constructor(opUser: GroupMember, groupNotification: string);
}
export declare class ChangeGroupIntroduction extends GroupTipsInfo {
    opUser: GroupMember;
    groupIntroduction: string;
    constructor(opUser: GroupMember, groupIntroduction: string);
}
export declare class ChangeGroupOwner extends GroupTipsInfo {
    opUser: GroupMember;
    groupOwner: string;
    constructor(opUser: GroupMember, groupOwner: string);
}
export declare class ChangeGroupMuteAll extends GroupTipsInfo {
    opUser: GroupMember;
    isMuteAll: boolean;
    constructor(opUser: GroupMember, isMuteAll: boolean);
}
export declare class ChangeJoinGroupApproval extends GroupTipsInfo {
    opUser: GroupMember;
    groupJoinOption: GroupJoinOption;
    constructor(opUser: GroupMember, groupJoinOption: GroupJoinOption);
}
export declare class ChangeInviteToGroupApproval extends GroupTipsInfo {
    opUser: GroupMember;
    groupInviteOption: GroupInviteOption;
    constructor(opUser: GroupMember, groupInviteOption: GroupInviteOption);
}
export declare class MuteGroupMember extends GroupTipsInfo {
    opUser: GroupMember;
    isSelfMuted: boolean;
    mutedGroupMembers: GroupMember[];
    muteTime: number;
    constructor(opUser: GroupMember, isSelfMuted: boolean, mutedGroupMembers: GroupMember[], muteTime: number);
}
export declare class PinGroupMessage extends GroupTipsInfo {
    opUser: GroupMember;
    constructor(opUser: GroupMember);
}
export declare class UnpinGroupMessage extends GroupTipsInfo {
    opUser: GroupMember;
    constructor(opUser: GroupMember);
}
@Observed
export declare class MessageReceipt {
    isPeerRead: boolean;
    readCount: number;
    unreadCount: number;
}
@Observed
export declare class MessageReaction {
    reactionID: string;
    totalUserCount: number;
    partialUserList: UserProfile[];
    reactedByMyself: boolean;
    constructor(reactionID?: string, totalUserCount?: number, partialUserList?: UserProfile[], reactedByMyself?: boolean);
}
@Observed
export declare class MessageExtension {
    extensionKey?: string;
    extensionValue?: string;
}
@Observed
export declare class OfflinePushInfo {
    title: string;
    description: string;
    extensionInfo: Map<string, Object>;
}
@Observed
export declare class MessageQuoteInfo {
    msgID: string;
    status: MessageStatus;
    timestamp: number;
    sequence: number;
    sender: MessageSenderInfo;
    messageType: MessageType;
    messagePayload?: MessagePayload;
}
@Observed
export declare class MessageInfo extends BasicData {
    private innerMsgID;
    get msgID(): string;
    set msgID(value: string);
    status: MessageStatus;
    timestamp?: number;
    sequence?: number;
    from: MessageSenderInfo;
    to: string;
    isSentBySelf: boolean;
    conversationType: ConversationType;
    messageType: MessageType;
    messagePayload?: MessagePayload;
    uploadMediaProgress: number;
    downloadMediaProgress: number;
    atUserList: string[];
    quoteInfo?: MessageQuoteInfo;
    isPinned: boolean;
    needReadReceipt: boolean;
    readReceiptInfo?: MessageReceipt;
    isExtensionEnabled: boolean;
    extensionList: MessageExtension[];
    reactionList: MessageReaction[];
    revokerInfo?: UserProfile;
    revokeReason?: string;
    offlinePushInfo?: OfflinePushInfo;
    rawMessage?: V2TIMMessage;
}
@Observed
export declare class MessageLoadOption {
    messageListType: MessageListType;
    cursor?: MessageInfo;
    direction: MessageLoadDirection;
    pageCount: number;
    messageTypeList: MessageType[];
}
@Observed
export declare class MergedForwardInfo {
    title: string;
    abstractList?: string[];
    compatibleText: string;
}
@Observed
export declare class ForwardMessageOption {
    forwardType: MessageForwardType;
    mergedForwardInfo?: MergedForwardInfo;
    sendMessageOption?: SendMessageOption;
}
@Observed
export declare class MessageListState {
    messageList: MessageInfo[];
    hasOlderMessages: boolean;
    hasNewerMessages: boolean;
    pinnedMessageList: MessageInfo[];
}
@Observed
export declare abstract class MessageListStore {
    static create(conversationID: string): MessageListStore;
    abstract get state(): Readonly<MessageListState>;
    abstract get messageEventFlow(): EventEmitter<MessageEvent>;
    abstract loadMessages(option?: MessageLoadOption, completion?: CompletionHandler): void;
    abstract loadOlderMessages(completion?: CompletionHandler): void;
    abstract loadNewerMessages(completion?: CompletionHandler): void;
    abstract sendMessageReadReceipts(messageList: MessageInfo[], completion?: CompletionHandler): void;
    abstract deleteMessages(messageList: MessageInfo[], completion?: CompletionHandler): void;
    abstract forwardMessages(messageList: MessageInfo[], option: ForwardMessageOption, conversationID: string, completion?: CompletionHandler): void;
}
