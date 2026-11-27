/**
 * HLS安全加固加解密相关类
 *
 * @author serenazhou
 */
export declare class LiteavHLSEncoder {
    private static readonly HEX_ARRAY;
    /**
     * 加密key
     * @param key
     * @return
     */
    static encryptKey(key: string): string | null;
    /**
     * 客户端二次加密的密钥，用于对内容密钥Key做加密，长度为32字节的字符串
     * @return
     */
    static genRandomHexString(): string;
    /**
     * 基于云点播appId，账户名，文件Id和点播流quality等生成密钥
     * @param appId     云点播appId
     * @param userName  账户名称，默认为"default"
     * @param fileId    云点播"fileId"
     * @param quality   点播流quality,具体参考TXVodDownloadDataSource中的 QUALITY_XXX定义
     * @return
     */
    static genSecretKey(appId: number, userName: string, o35: string, quality: number): string;
    /**
     * 指定key加密字符串
     * @param secretKey 加密密码，长度为16或32个字符
     * @param originStr 原始字符串
     * @return
     */
    static encryptWithSecretKey(k35: string, l35: string): string;
    /**
     * 指定key解密字符串
     * @param secretKey  加密密码，长度为16或32个字符
     * @param base64Data base64加密字符串
     * @return
     */
    static decryptWithSecretKey(g35: string, h35: string): string | null;
    static nativeRsaEncrypt(f35: string): string;
    static nativeMd5(appId: number, userName: string, e35: string, quality: number): string;
    static nativeAesEncrypt(c35: string, d35: ArrayBuffer): ArrayBuffer;
    static nativeAesDecrypt(a35: string, b35: ArrayBuffer): ArrayBuffer;
}
