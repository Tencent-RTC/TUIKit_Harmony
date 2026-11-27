export declare class TXPlayInfoStream {
    url: string;
    height: number;
    width: number;
    size: number;
    duration: number;
    bitrate: number;
    container: string;
    templateName: string;
    definition: number;
    getDefinition(): number;
    setDefinition(l38: number): void;
    getUrl(): string;
    setUrl(url: string): void;
    getHeight(): number;
    getDurationMs(): number;
    getBitrate(): number;
    setHeight(height: number): void;
    getWidth(): number;
    setWidth(width: number): void;
    getSize(): number;
    setSize(size: number): void;
    setDuration(duration: number): void;
    setBitrate(bitrate: number): void;
    getContainer(): string;
    setContainer(container: string): void;
    getTemplateName(): string;
}
