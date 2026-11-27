export declare class TXCPlayerGlobalSetting {
    private static cacheFolderPath;
    private static maxCacheSizeMB;
    private static hosts?;
    /**
     * 设置播放引擎的cache目录。设置后，预下载，播放器，离线下载等统一从此目录读取和存储。
     * @param path cache绝对路径
     */
    static setCacheFolderPath(path: string): void;
    /**
     * 设置播放引擎的最大缓存大小。设置后会根据设定值自动清理Cache目录的文件
     * @param sizeMB 最大缓存大小（单位：MB）。
     */
    static setMaxCacheSize(c43: number): void;
    static getCacheFolderPath(): string;
    static getMaxCacheSize(): number;
    /**
     * 设置腾讯云PlayCGI主机地址列表
     * @param hosts 要设置的主机地址列表，例如"playvideo.qcloud.com"。
     *              发起PlayCGI请求时依次使用传入的hosts地址，在某个host请求失败时自动切换到下个host重试请求。
     */
    static setPlayCGIHosts(hosts: string[]): void;
    /**
     * 获取设置的腾讯云PlayCGI主机地址列表
     * @return 设置的腾讯云PlayCGI主机地址列表
     */
    static getPlayCGIHosts(): string[] | undefined;
}
