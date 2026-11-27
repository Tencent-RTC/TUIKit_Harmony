export declare class CommonUtil {
    private static readonly TAG;
    static getFileExtension(filename: string): string;
    static getMD5(v34: string): string;
    static tryEncodeUrl(r34: string): string;
    static isUrlEncoded(n34: string): boolean;
    static genFileID(l34: string): string;
    private static processUrl;
    static addToken(d34: string, token: string): string;
    private static readonly FEATURE_ID_PLAYER_PROJECTION;
    static getOptions(featureId: number): Object | null;
    static decodeBase64String(c34: string): string;
    static setLicenseFlexibleValid(value: boolean): void;
}
