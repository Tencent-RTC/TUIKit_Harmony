import { CompletionHandler } from '../Define';
import { MessageInfo, OfflinePushInfo } from './MessageListStore';
export declare abstract class SendMessagePayload {
}
export declare class TextSendMessagePayload extends SendMessagePayload {
    text: string;
    constructor(text: string);
}
export declare class CustomSendMessagePayload extends SendMessagePayload {
    customData: string;
    description?: string;
    extensionInfo?: string;
    constructor(customData: string, description?: string, extensionInfo?: string);
}
export declare class ImageSendMessagePayload extends SendMessagePayload {
    imagePath: string;
    imageWidth: number;
    imageHeight: number;
    constructor(imagePath: string, imageWidth?: number, imageHeight?: number);
}
export declare class AudioSendMessagePayload extends SendMessagePayload {
    audioFilePath: string;
    duration: number;
    constructor(audioFilePath: string, duration: number);
}
export declare class VideoSendMessagePayload extends SendMessagePayload {
    videoFilePath: string;
    videoType: string;
    duration: number;
    snapshotPath: string;
    snapshotWidth: number;
    snapshotHeight: number;
    constructor(videoFilePath: string, videoType: string, duration: number, snapshotPath: string, snapshotWidth?: number, snapshotHeight?: number);
}
export declare class FileSendMessagePayload extends SendMessagePayload {
    filePath: string;
    fileName: string;
    fileSize: number;
    constructor(filePath: string, fileName: string, fileSize?: number);
}
export declare class FaceSendMessagePayload extends SendMessagePayload {
    index: number;
    data: string;
    constructor(index: number, data: string);
}
@Observed
export declare class SendMessageOption {
    atUserList?: string[];
    quotedMessage?: MessageInfo;
    needReadReceipt: boolean;
    isExtensionEnabled: boolean;
    onlineUserOnly: boolean;
    offlinePushInfo?: OfflinePushInfo;
}
@Observed
export declare abstract class MessageInputStore {
    static create(conversationID: string): MessageInputStore;
    abstract sendMessage(payload: SendMessagePayload, option?: SendMessageOption, completion?: CompletionHandler): void;
    abstract insertLocalMessage(payload: SendMessagePayload, sender?: string, completion?: CompletionHandler): void;
}
