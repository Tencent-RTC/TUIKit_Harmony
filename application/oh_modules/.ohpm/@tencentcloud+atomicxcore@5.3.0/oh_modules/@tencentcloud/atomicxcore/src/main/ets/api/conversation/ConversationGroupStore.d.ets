import { CompletionHandler } from '../Define';
@Observed
export declare class ConversationGroupState {
    groupList: string[];
}
@Observed
export declare abstract class ConversationGroupStore {
    protected internalState: ConversationGroupState;
    static get shared(): ConversationGroupStore;
    get state(): ConversationGroupState;
    abstract loadGroups(completion?: CompletionHandler): void;
    abstract createGroup(groupName: string, conversationIDList: string[], completion?: CompletionHandler): void;
    abstract deleteGroup(groupName: string, completion?: CompletionHandler): void;
    abstract renameGroup(oldName: string, newName: string, completion?: CompletionHandler): void;
    abstract addConversationsToGroup(groupName: string, conversationIDList: string[], completion?: CompletionHandler): void;
    abstract deleteConversationsFromGroup(groupName: string, conversationIDList: string[], completion?: CompletionHandler): void;
}
