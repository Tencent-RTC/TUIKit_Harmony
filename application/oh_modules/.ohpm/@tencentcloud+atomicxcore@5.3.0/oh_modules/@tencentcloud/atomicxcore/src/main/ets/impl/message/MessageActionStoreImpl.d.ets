import { CompletionHandler } from '../../api/Define';
import { MediaQuality, MergedMessageListCompletionHandler, MessageActionState, MessageActionStore } from '../../api/message/MessageActionStore';
import { MessageExtension, MessageInfo, MessagePayload } from '../../api/message/MessageListStore';
export declare enum MessageActionNotifyKey {
    ON_MESSAGE_DELETED = "onMessageDeleted",
    ON_MESSAGE_RECALLED = "onMessageRecalled",
    ON_MESSAGE_EDITED = "onMessageEdited",
    ON_MESSAGE_PINNED = "onMessagePinned",
    ON_MESSAGE_TRANSLATED = "onMessageTranslated",
    ON_VOICE_CONVERTED = "onVoiceConvertedToText",
    ON_MESSAGE_MEDIA_DOWNLOAD = "onMessageMediaDownload",
    ON_MESSAGE_MEDIA_DOWNLOAD_PROGRESS = "onMessageMediaDownloadProgress",
    ON_CHAT_HISTORY_CLEARED = "onChatHistoryMessageCleared"
}
export declare class MessageMediaDownloadEventData {
    messageID: string;
    quality?: MediaQuality;
    messagePayload: MessagePayload;
    constructor(messageID: string, quality: MediaQuality | undefined, messagePayload: MessagePayload);
}
export declare class MessageMediaDownloadProgressEventData {
    messageID: string;
    downloadMediaProgress: number;
    constructor(messageID: string, downloadMediaProgress: number);
}
@Observed
export declare class MessageActionStoreImpl extends MessageActionStore {
    private static inFlightDownloads;
    private nextSeqOfReadMembers;
    private nextSeqOfUnreadMembers;
    private countOfReadMembers;
    private countOfUnreadMembers;
    private currentReactionID;
    private nextSeqOfReactionUsers;
    private countOfReactionUsers;
    private hasReported;
    constructor(message: MessageInfo);
    private buildDownloadDedupKey;
    private beginDownload;
    private endDownload;
    get state(): Readonly<MessageActionState>;
    revoke(completion?: CompletionHandler): void;
    delete(completion?: CompletionHandler): void;
    pin(isPinned: boolean, completion?: CompletionHandler): void;
    loadReadMembers(count: number, completion?: CompletionHandler): void;
    loadUnreadMembers(count: number, completion?: CompletionHandler): void;
    loadMoreMembers(isRead: boolean, completion?: CompletionHandler): void;
    addReaction(reactionID: string, completion?: CompletionHandler): void;
    removeReaction(reactionID: string, completion?: CompletionHandler): void;
    loadReactionUsers(reactionID: string, count: number, completion?: CompletionHandler): void;
    loadMoreReactionUsers(completion?: CompletionHandler): void;
    setExtensions(extensions: MessageExtension[], completion?: CompletionHandler): void;
    deleteExtensions(keys?: string[], completion?: CompletionHandler): void;
    translateText(sourceTextList: string[], sourceLanguage: string | undefined, targetLanguage: string, completion?: CompletionHandler): void;
    convertVoiceToText(language: string, completion?: CompletionHandler): void;
    downloadMedia(quality?: MediaQuality, completion?: CompletionHandler): void;
    downloadMergedMessageList(completion: MergedMessageListCompletionHandler): void;
    private downloadImageMedia;
    private downloadVideoMedia;
    private downloadVideoSnapshot;
    private downloadVideoFile;
    private downloadSoundMedia;
    private downloadFileMedia;
    private buildImagePayload;
    private buildVideoSnapshotPayload;
    private buildVideoFilePayload;
    private applyVideoSnapshotPathToMessage;
    private applyVideoFilePathToMessage;
    private applyAudioPathToMessage;
    private applyFilePathToMessage;
    private buildAudioPayload;
    private buildFilePayload;
    private postMessageMediaDownload;
    private updateDownloadProgress;
    private postMessageMediaDownloadProgress;
    private imagePrefix;
    private isMessageValid;
    private reportAtomicMetricsIfNeeded;
}
