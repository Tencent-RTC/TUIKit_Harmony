import { MessageInfo } from '../message/MessageListStore';
import { V2TIMConversation } from '@tencentcloud/imsdk';
import { GroupType } from '../group/GroupStore';
import { CompletionHandler } from '../Define';
import BasicData from '../common/BasicData';
import BasicDataSource from '../common/BasicDataSource';
export declare enum ConversationGroup {
    C2C = "_c2c_",
    GROUP = "_group_",
    HAS_UNREAD_COUNT = "_hasUnreadCount_",
    HAS_GROUP_AT_INFO = "_hasGroupAtInfo_"
}
export declare enum ConversationType {
    UNKNOWN = 0,
    C2C = 1,
    GROUP = 2
}
export declare namespace ConversationType {
    function parse(value: number): ConversationType;
}
export declare class ConversationMarkType {
    readonly rawValue: number;
    constructor(rawValue: number);
    get isEmpty(): boolean;
    or(other: ConversationMarkType): ConversationMarkType;
    contains(other: ConversationMarkType): boolean;
    static readonly star: ConversationMarkType;
    static readonly unread: ConversationMarkType;
    static readonly fold: ConversationMarkType;
    static readonly hide: ConversationMarkType;
    static parseList(sdkMarkList: number[]): ConversationMarkType[];
}
export declare enum GroupAtType {
    AT_ME = 1,
    AT_ALL = 2,
    AT_ALL_AT_ME = 3
}
export declare namespace GroupAtType {
    function parse(value: number): GroupAtType;
}
export declare class GroupAtInfo {
    msgSeq: number;
    atType: GroupAtType;
    constructor(msgSeq: number, atType: GroupAtType);
}
export declare enum ReceiveMessageOption {
    RECEIVE = 0,
    NOT_RECEIVE = 1,
    NOT_NOTIFY = 2,
    NOT_NOTIFY_EXCEPT_MENTION = 3,
    NOT_RECEIVE_EXCEPT_MENTION = 4
}
export declare namespace ReceiveMessageOption {
    function parse(value: number): ReceiveMessageOption;
}
@Observed
export declare class ConversationInfo extends BasicData {
    conversationID: string;
    type?: ConversationType;
    groupType?: GroupType;
    avatarURL?: string;
    title?: string;
    lastMessage?: MessageInfo;
    draft?: string;
    unreadCount: number;
    isPinned: boolean;
    receiveOption: ReceiveMessageOption;
    groupAtInfoList?: GroupAtInfo[];
    conversationMarkList: ConversationMarkType[];
    conversationGroupList: string[];
    rawConversation?: V2TIMConversation;
}
export declare class ConversationLoadOption {
    count: number;
    markType?: ConversationMarkType;
    constructor(count?: number, markType?: ConversationMarkType);
}
@Observed
export declare class ConversationListState {
    conversationList: BasicDataSource<ConversationInfo>;
    hasMoreConversations: boolean;
    totalUnreadCount: number;
}
@Observed
export declare abstract class ConversationListStore {
    protected internalState: ConversationListState;
    get state(): ConversationListState;
    static create(conversationGroup?: string): ConversationListStore;
    abstract loadConversations(option?: ConversationLoadOption, completion?: CompletionHandler): void;
    abstract loadMoreConversations(completion?: CompletionHandler): void;
    abstract getConversationInfo(conversationID: string, completion: GetConversationInfoCompletionHandler): void;
    abstract pinConversation(conversationID: string, pin: boolean, completion?: CompletionHandler): void;
    abstract setReceiveMessageOpt(conversationID: string, opt: ReceiveMessageOption, completion?: CompletionHandler): void;
    abstract deleteConversation(conversationID: string, completion?: CompletionHandler): void;
    abstract setConversationDraft(conversationID: string, draft?: string, completion?: CompletionHandler): void;
    abstract clearConversationMessages(conversationID: string, completion?: CompletionHandler): void;
    abstract clearConversationUnreadCount(conversationID: string, completion?: CompletionHandler): void;
    abstract markConversation(conversationIDList: string[], markType: ConversationMarkType, enable: boolean, completion?: CompletionHandler): void;
}
export interface GetConversationInfoCompletionHandler {
    onSuccess(conversationInfo: ConversationInfo): void;
    onFailure(code: number, desc: string): void;
}
