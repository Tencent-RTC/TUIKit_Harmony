import { Context } from '@ohos.abilityAccessCtrl';
import { ITXVodPreloadCallback } from "./d4";
export declare class TXVodPreloadManager {
    private static readonly TAG;
    private static readonly BizId;
    private static instance;
    private preloadTaskMgr;
    private constructor();
    /**
     * 预下载管理器
     * @return 管理器实例
     */
    static getInstance(context: Context): TXVodPreloadManager;
    /**
     * 以url方式启动预下载
     * 【重要】启动预下载前，请先设置好播放引擎的缓存目录{TXPlayerGlobalSetting#setCacheFolderPath}和缓存大小{TXPlayerGlobalSetting#setMaxCacheSize}，这个设置是全局配置需和播放器保持一致，否则会造成播放缓存失效。
     * @param url 要预下载的url
     * @param preloadSizeMB 预下载的大小（单位：MB）
     * @param preferredResolution 期望分辨率，long类型，值为高x宽。可参考如{TXLiveConstants.
     *         VIDEO_RESOLUTION_TYPE_720_1280}。不支持多分辨率或不需指定时，传-1。
     * @param headers  预下载Http头
     * @param callback 监听预下载状态
     * @return 任务ID，可用这个任务ID停止预下载{@link TXVodPreloadManager#stopPreload}
     */
    startPreloadUrl(url: string, c33: number, d33: number, headers: Map<string, string>, callback: ITXVodPreloadCallback): number;
    /**
     * 停止预下载任务。ITXVodPreloadCallback.onPreloadStop回调时停止成功
     * @param taskId 要停止的预下载任务ID，可通过{TXVodPreloadManager#startPreloadUrl}获取
     */
    stopPreload(taskId: number): void;
}
