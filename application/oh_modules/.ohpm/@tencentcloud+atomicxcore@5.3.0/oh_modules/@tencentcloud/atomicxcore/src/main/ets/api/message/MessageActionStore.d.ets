import { CompletionHandler } from '../Define';
import { MessageInfo, MessageExtension } from './MessageListStore';
import { UserProfile } from '../login/LoginStore';
import { GroupMember } from '../group/GroupMemberStore';
export declare enum MediaQuality {
    THUMBNAIL = 0,
    STANDARD = 1,
    ORIGINAL = 2
}
@Observed
export declare class MessageActionState {
    readMemberList: GroupMember[];
    hasMoreReadMembers: boolean;
    unreadMemberList: GroupMember[];
    hasMoreUnreadMembers: boolean;
    reactionUserList: UserProfile[];
    hasMoreReactionUsers: boolean;
}
@Observed
export declare abstract class MessageActionStore {
    protected message: MessageInfo;
    protected actionState: MessageActionState;
    constructor(message: MessageInfo);
    static create(message: MessageInfo): MessageActionStore;
    get state(): Readonly<MessageActionState>;
    abstract revoke(completion?: CompletionHandler): void;
    abstract delete(completion?: CompletionHandler): void;
    abstract pin(isPinned: boolean, completion?: CompletionHandler): void;
    abstract loadReadMembers(count: number, completion?: CompletionHandler): void;
    abstract loadUnreadMembers(count: number, completion?: CompletionHandler): void;
    abstract loadMoreMembers(isRead: boolean, completion?: CompletionHandler): void;
    abstract addReaction(reactionID: string, completion?: CompletionHandler): void;
    abstract removeReaction(reactionID: string, completion?: CompletionHandler): void;
    abstract loadReactionUsers(reactionID: string, count: number, completion?: CompletionHandler): void;
    abstract loadMoreReactionUsers(completion?: CompletionHandler): void;
    abstract setExtensions(extensions: MessageExtension[], completion?: CompletionHandler): void;
    abstract deleteExtensions(keys?: string[], completion?: CompletionHandler): void;
    abstract translateText(sourceTextList: string[], sourceLanguage: string | undefined, targetLanguage: string, completion?: CompletionHandler): void;
    abstract convertVoiceToText(language: string, completion?: CompletionHandler): void;
    abstract downloadMedia(quality?: MediaQuality, completion?: CompletionHandler): void;
    abstract downloadMergedMessageList(completion: MergedMessageListCompletionHandler): void;
}
export interface MergedMessageListCompletionHandler {
    onSuccess(messageList: MessageInfo[]): void;
    onFailure(code: number, desc: string): void;
}
