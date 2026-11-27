import { V2TIMConversation, V2TIMConversationListener, V2TIMConversationListFilter, V2TIMConversationType, V2TIMFriendInfo, V2TIMFriendshipListener, V2TIMReceiveMessageOpt } from '@tencentcloud/imsdk';
import { ConversationInfo, ConversationListStore, ConversationLoadOption, ConversationMarkType, ConversationType, GetConversationInfoCompletionHandler, ReceiveMessageOption } from '../../api/conversation/ConversationListStore';
import { CompletionHandler } from '../../api/Define';
export declare enum ConversationNotifyKey {
    ON_CHAT_HISTORY_CLEARED = "onConversationHistoryMessageCleared",
    ON_CONVERSATION_MUTED_CHANGED = "onConversationMutedChanged"
}
export declare enum MarkedConversationNotifyKey {
    ON_CACHE_UPDATED = "onMarkedConversationCacheUpdated"
}
@Observed
export declare class ConversationListStoreImpl extends ConversationListStore implements V2TIMConversationListener, V2TIMFriendshipListener {
    private option?;
    private conversationGroup?;
    private hasLoadedConversationList;
    private nextSeq;
    private weakConversationListener;
    private weakFriendshipListener;
    private sdkTotalUnreadCount;
    private currentSubscribedFilter?;
    private currentSubscribedConversationGroup?;
    private currentSubscribedMarkType?;
    private isCalculationScheduled;
    private calculateTimeoutId;
    constructor(conversationGroup?: string);
    private initTotalUnreadCount;
    loadConversations(option?: ConversationLoadOption, completion?: CompletionHandler): void;
    loadMoreConversations(completion?: CompletionHandler): void;
    getConversationInfo(conversationID: string, completion: GetConversationInfoCompletionHandler): void;
    pinConversation(conversationID: string, pin: boolean, completion?: CompletionHandler): void;
    setReceiveMessageOpt(conversationID: string, opt: ReceiveMessageOption, completion?: CompletionHandler): void;
    deleteConversation(conversationID: string, completion?: CompletionHandler): void;
    setConversationDraft(conversationID: string, draft?: string, completion?: CompletionHandler): void;
    clearConversationMessages(conversationID: string, completion?: CompletionHandler): void;
    clearConversationUnreadCount(conversationID: string, completion?: CompletionHandler): void;
    markConversation(conversationIDList: string[], markType: ConversationMarkType, enable: boolean, completion?: CompletionHandler): void;
    onConversationChanged(conversationList: V2TIMConversation[]): void;
    onNewConversation(conversationList: V2TIMConversation[]): void;
    onConversationDeleted(conversationIDList: string[]): void;
    onTotalUnreadMessageCountChanged(totalUnreadCount: number): void;
    onUnreadMessageCountChangedByFilter(filter: V2TIMConversationListFilter, totalUnreadCount: number): void;
    onFriendListDeleted(_userIDList: string[]): void;
    onFriendInfoChanged(infoList: V2TIMFriendInfo[]): void;
    private buildV2TIMFilter;
    private convertToV2TIMReceiveOpt;
    private postConversationMutedChangedNotification;
    private postChatHistoryClearedNotification;
    private scheduleTotalUnreadCountCalculation;
    private calculateTotalUnreadCount;
    private convertToConversationList;
}
export declare class ConversationConverter {
    static convertToConversation(imConversation: V2TIMConversation): ConversationInfo;
    static convertToSortedConversationList(v2List: V2TIMConversation[]): ConversationInfo[];
    static convertToConversationType(v2Type: V2TIMConversationType): ConversationType;
    static convertToReceiveMessageOption(opt?: V2TIMReceiveMessageOpt): ReceiveMessageOption;
    private static convertToGroupAtType;
}
