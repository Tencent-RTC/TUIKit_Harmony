import { TXCPlayImageSpriteInfo, TXCPlayKeyFrameDescInfo, TXCResolutionName } from "./z3";
import { TXPlayInfoStream } from "./m4";
export declare class TXCPlayInfoParserV2 {
    private static TAG;
    private response;
    private playInfoStream?;
    constructor(response: JSON);
    playUrl(): string;
    getDuration(): number;
    getSize(): number;
    private getPlayInfoStream;
    coverUrl(): string;
    getSource(): TXPlayInfoStream | null;
    getDefaultVideoClassificationDefinitionList(): number[];
    getDefaultVideoClassification(): string | null;
    getVideoClassification(): VideoClassification[];
    getStreamList(): TXPlayInfoStream[];
    getMasterPlayList(): TXPlayInfoStream | null;
    name(): string | null;
    description(): string;
    getImageSpriteInfo(): TXCPlayImageSpriteInfo;
    private parseImageSpriteInfo;
    getKeyFrameDescInfo(): TXCPlayKeyFrameDescInfo[];
    private parseKeyFrameDescInfo;
    getTranscodeStreamForDefinition(z35: string, format: string): TXPlayInfoStream | null;
    getTranscodeStreamForTemplate(templateName: string, format: string): TXPlayInfoStream | null;
    getResolutionNameList(): TXCResolutionName[];
}
export declare class VideoClassification {
    classificationId?: string;
    classificationName?: string;
    definitionList?: number[];
}
