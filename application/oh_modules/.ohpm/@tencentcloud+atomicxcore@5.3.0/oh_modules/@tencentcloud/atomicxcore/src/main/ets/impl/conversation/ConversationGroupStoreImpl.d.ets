import { V2TIMConversation, V2TIMConversationListener } from '@tencentcloud/imsdk';
import { ConversationGroupStore } from '../../api/conversation/ConversationGroupStore';
import { CompletionHandler } from '../../api/Define';
@Observed
export declare class ConversationGroupStoreImpl extends ConversationGroupStore implements V2TIMConversationListener {
    private static _instance?;
    static get shared(): ConversationGroupStoreImpl;
    private weakConversationListener?;
    private isListenerRegistered;
    private loginEventSubscription?;
    private lastLoginStatus;
    private constructor();
    private addConversationListener;
    private observeLoginStatus;
    loadGroups(completion?: CompletionHandler): void;
    createGroup(groupName: string, conversationIDList: string[], completion?: CompletionHandler): void;
    deleteGroup(groupName: string, completion?: CompletionHandler): void;
    renameGroup(oldName: string, newName: string, completion?: CompletionHandler): void;
    addConversationsToGroup(groupName: string, conversationIDList: string[], completion?: CompletionHandler): void;
    deleteConversationsFromGroup(groupName: string, conversationIDList: string[], completion?: CompletionHandler): void;
    private completeWithOperationResult;
    onConversationGroupCreated(groupName: string, _conversationList: V2TIMConversation[]): void;
    onConversationGroupDeleted(groupName: string): void;
    onConversationGroupNameChanged(oldName: string, newName: string): void;
    private addGroupIfNeeded;
}
