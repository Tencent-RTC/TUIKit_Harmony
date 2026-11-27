import { MessageType } from '../../message/MessageListStore';
interface MediaPathResult {
    filePath: string;
    exists: boolean;
}
export declare class MediaPathManager {
    static getHomePath(): string;
    static ensureDirectoryExists(dirPath: string): boolean;
    static getMediaHomePath(messageType: MessageType): string;
    static generateMediaPath(messageType: MessageType, extension?: string): string;
    static getActualMediaPath(messageType: MessageType, mediaPath?: string, uuid?: string, extension?: string): MediaPathResult;
    static formatFilePath(path: string): string;
}
export { MediaPathResult };
