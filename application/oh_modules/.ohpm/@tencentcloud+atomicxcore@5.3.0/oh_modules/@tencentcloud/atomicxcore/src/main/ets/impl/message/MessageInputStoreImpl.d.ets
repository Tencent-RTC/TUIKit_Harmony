import { CompletionHandler } from '../../api/Define';
import { MessageInputStore, SendMessageOption, SendMessagePayload } from '../../api/message/MessageInputStore';
import { MessageInfo, MessageQuoteInfo } from '../../api/message/MessageListStore';
export declare enum MessageSendNotifyKey {
    ON_MESSAGE_SEND_BEGIN = "onMessageSendBegin",
    ON_MESSAGE_SEND_PROGRESS = "onMessageSendProgress",
    ON_MESSAGE_SEND_SUCCESS = "onMessageSendSuccess",
    ON_MESSAGE_SEND_FAILED = "onMessageSendFailed"
}
export declare enum MessageInsertNotifyKey {
    ON_MESSAGE_INSERTED = "onMessageInserted"
}
export declare class QuoteMessageStub {
    private static quoteInfoMap;
    static setQuoteInfo(messageID: string, quoteInfo: MessageQuoteInfo): void;
    static getQuoteInfo(messageID?: string): MessageQuoteInfo | undefined;
}
@Observed
export declare class MessageInputStoreImpl extends MessageInputStore {
    private conversationID;
    constructor(conversationID: string);
    sendMessage(payload: SendMessagePayload, option?: SendMessageOption, completion?: CompletionHandler): void;
    insertLocalMessage(payload: SendMessagePayload, sender?: string, completion?: CompletionHandler): void;
    sendPreparedMessage(message: MessageInfo, completion?: CompletionHandler): void;
    private convertPayloadToMessageInfo;
    private toLocalQuoteInfo;
    private sendMessageInternal;
    private copyMessageInfo;
    private createIMMessage;
    private createQuoteMessageIfNeeded;
    private convertToOfflinePushInfo;
    private static asString;
    private static asNumber;
    private static asBoolean;
    private stringToArrayBuffer;
}
