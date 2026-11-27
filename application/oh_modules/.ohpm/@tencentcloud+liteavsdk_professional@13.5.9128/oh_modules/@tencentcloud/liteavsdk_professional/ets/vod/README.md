## 点播播放器集成

### 前提条件

- DevEco Studio 5.0.3.900及以上版本。
- API Version 12 的 HarmonyOS-NEXT-DB2 或以上版本。
- 已通过授权的华为开发者账号。可在华为开发者联盟注册账号。
- 建议使⽤ HUAWEI Mate 60 Pro 及更⾼性能的设备，设备系统软件版本建议NEXT0.0.72及以上版本。

### 创建项⽬

1. 参考构建第⼀个ArkTS应⽤, 创建⼀个新⼯程。
2. 在entry的 module.json5 的module模块中，声明所需权限：
```json5
"requestPermissions":[
    {
        "name" : "ohos.permission.INTERNET",
        "reason": need internet,
        "usedScene": {
            "abilities": [
            "FormAbility"
            ],
            "when":"always"
        }
    },
    {
        "name" : "ohos.permission.GET_NETWORK_INFO",
        "reason": need internet,
        "usedScene": {
            "abilities": [
            "FormAbility"
            ],
            "when":"always"
        }
    },
    {
        "name" : "ohos.permission.SET_NETWORK_INFO",
        "reason": need internet,
        "usedScene": {
            "abilities": [
            "FormAbility"
            ],
            "when":"always"
        }
    }
]
```

### 集成鸿蒙 LiteAVSDK Professional SDK
1. 将LiteAVSDK_Professional_xxxxxx.har(“xxxxxx“对应具体对版本信息)⽂件复制到entry->libs⽬录下。

```json5
dependencies": {
    "liteavsdk": "file:libs/LiteAVSDK_Professional_xxxxxx.har" 
}
```
2. 在entry下的 oh-package.json5 ⽂件中添加依赖,如下所示。然后点击Sync同步配置。

### 播放器包含如下能⼒：
- ⽀持 MP4 及 HLS 多种播放格式，⽀持 url 和 fileId 两种播放⽅式。
- ⽀持开始/暂停/恢复/停⽌播放。
- ⽀持seek。
- 可以⼿动切换不同的清晰度。
- 可以指定不同倍速播放。
- ⽀持循环播放。
- 支持本地文件播放。
- 支持HLS多码流自适应播放。
- 支持播放缓存及设置最大缓存大小。
- ⽀持 MP4 及 HLS 资源下载和离线播放。
- 支持URL预下载。

### 全局初始化配置[TXVodGlobalSetting]
<table>
<tr>
<td rowspan="1" colSpan="1" >API(初始化时调用)</td>
<td rowspan="1" colSpan="1" >描述</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setCacheFolderPath</td>
<td rowspan="1" colSpan="1" >设置播放引擎的cache目录。设置后，预下载，播放器，离线下载等统一从此目录读取和存储。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setMaxCacheSize</td>
<td rowspan="1" colSpan="1" >设置播放引擎的最大缓存大小。设置后会根据设定值自动清理Cache目录的文件。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setPlayCGIHosts</td>
<td rowspan="1" colSpan="1" >设置腾讯云PlayCGI主机地址列表。如果服务器没有特别情况，一般不用配置使用默认列表。</td>
</tr>
</table>


### 实现流程[TXVodGlobalSetting]
1. 导⼊ liteavsdk 组件 打开pages/Index.ets ⽂件，导⼊ liteavsdk 组件。
```typescript
import { TXVodGlobalSetting } from 'liteavsdk';
```
2. 初始化时全局配置
```typescript
private init() {
    ......
    // 设置缓存路径，设置后，预下载，播放器，离线下载等统一用这个地址缓存或下载
    TXVodGlobalSetting.setCacheFolderPath(getContext().filesDir); 
    // 最大缓存大小（单位：MB）
		TXVodGlobalSetting.setMaxCacheSize(100);   
}
```

### 设置产品License
1. 导⼊ liteavsdk 组件 打开pages/Index.ets ⽂件，导⼊ liteavsdk 组件。
```typescript
import { getV2TXLivePremierShareInstance } from 'liteavsdk';
```
2. 初始化时设置License，避免启播失败
```typescript
  private init() {
    // 参数为产品license对应的url和key。正式版 License 需 [购买]。
    getV2TXLivePremierShareInstance(context).setLicence(Constants.LICENSE_URL, 	           Constants.LICENSE_KEY);
    ......
  }
```

### 播放基础接⼝[TXVodPlayer]
<table>
<tr>
<td rowspan="1" colSpan="1" >API</td>
<td rowspan="1" colSpan="1" >描述</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setVideoRenderTarget</td>
<td rowspan="1" colSpan="1" >设置⽤于视频渲染的⽬标。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setAutoPlay</td>
<td rowspan="1" colSpan="1" >设置VOD在startPlay后是否⾃动开始播放，默认为true⾃动播放。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setVodPlayCallback</td>
<td rowspan="1" colSpan="1" >设置播放器的回调函数。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >startVodPlay</td>
<td rowspan="1" colSpan="1" >使⽤fileId或url开始播放。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >pause</td>
<td rowspan="1" colSpan="1" >暂停播放，停⽌获取流数据，并保持最后⼀帧图像。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >resume</td>
<td rowspan="1" colSpan="1" >从暂停位置恢复播放，重新获取流数据。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >stopPlay</td>
<td rowspan="1" colSpan="1" >停⽌播放，会销毁播放器实例。须调⽤startVodPlay接⼝重新启播。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >seek</td>
<td rowspan="1" colSpan="1" >跳转到视频流指定时间点。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >getSupportedBitrates</td>
<td rowspan="1" colSpan="1" >如果播放地址是主播放ArrayList，则返回⽀持的码率（清晰度）。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setBitrateIndex</td>
<td rowspan="1" colSpan="1" >设置当前播放视频的码率索引(启播后，通过getSupportedBitrates获取)，⽆缝切换清晰度。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setRate</td>
<td rowspan="1" colSpan="1" >设置VOD的播放速率。默认1.0。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setLoop</td>
<td rowspan="1" colSpan="1" >设置是否循环播放。</td>
</tr> 
</table>

### 实现流程[TXVodPlayer]
1. 导⼊ liteavsdk 组件 打开pages/Index.ets ⽂件，导⼊ liteavsdk 组件。
```typescript
import { TXVodPlayer, TXVodConstants, TXVodDef, ITXVodPlayCallback } from 'liteavsdk';
```
2. 创建播放器实例并设置渲染surfaceId
```typescript
this.player = new TXVodPlayer(getContext());
this.xComponentController.setXComponentSurfaceRect({ surfaceWidth:
this.surfaceSize.width, surfaceHeight: this.surfaceSize.height });
this.surfaceId = this.xComponentController.getXComponentSurfaceId();
/**
 * 设置用于视频渲染的目标。
 * 设置render target之后，底层在条件满足的情况下，会开始输出视频帧。因此，在设置之前，必须确保跟该target
 * 已经根据视频流信息设置了正确的宽高，否则有可能导致前面显示若干帧宽高不正确。
 *
 * @param surfaceId surface实例的标识
 * @return
 */
setVideoRenderTarget(this.surfaceId);
```
3. 设置播放器回调并开始播放
```typescript
let player = this.player as TXVodPlayer;
// URL 播放
let playInfoParams: TXVodDef.TXPlayInfoParams =
TXVodDef.TXPlayInfoParams.createWithUrl('https://1500005830.vod2.myqcloud.com/43843ec0v
    odtranscq1500005830/09d5b1bf387702299773851453/adp.10.m3u8');
// 使用fileId 播放
// let playInfoParams: TXVodDef.TXPlayInfoParams =
// TXVodDef.TXPlayInfoParams.createWithFileId(1500005830, '243791578431393746',
//'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6MTUwMDAwNTgzMCwiZmlsZUlkIjoiMjQzNzkxN
// Tc4NDMxMzkzNzQ2IiwiY3VycmVudFRpbWVTdGFtcCI6MTY3MzQyNjIyNywiY29udGVudEluZm8iOnsiYXVkaW9W
// aWRlb1R5cGUiOiJQcm90ZWN0ZWRBZGFwdGl2ZSIsImRybUFkYXB0aXZlSW5mbyI6eyJwcml2YXRlRW5jcnlwdGl
// vbkRlZmluaXRpb24iOjEyfX0sInVybEFjY2Vzc0luZm8iOnsiZG9tYWluIjoiMTUwMDAwNTgzMC52b2QyLm15cW
// Nsb3VkLmNvbSIsInNjaGVtZSI6IkhUVFBTIn19.q34pq7Bl0ryKDwUHGyzfXKP-CDI8vrm0k_y-IaxgF_U');
this.setupPlayerCallbacks();
/**
* 使⽤fileId或url开始播放。
*
* @param playInfoParams 与fileId或url相关的播放信息参数
*/
player.startVodPlay(playInfoParams);
```
配置播放回调
```typescript
private setupPlayerCallbacks() {
let vodPlayer = this.player as TXVodPlayer;
vodPlayer.setVodPlayCallback({
onPlayEvent: (vodPlayer: TXVodPlayer, event: number, eventData?: Map<string,
TXVodDef.ParamType>): void => {
    switch (event) {
        case TXVodConstants.VOD_PLAY_EVT_PLAY_BEGIN:
        let durationMs: number = vodPlayer.getDuration() * 1000;
        this.playerController.setDurationMs(durationMs);
        this.playerController.changePlayButtonToState(true)
        this.startProgressTimer();
        break;
        case TXVodConstants.VOD_PLAY_EVT_PLAY_PROGRESS:
        let currentPositionMs = eventData?.get(TXVodConstants.EVT_PLAY_PROGRESS_MS) as
        number;;
        let availablePositionMs =
        eventData?.get(TXVodConstants.EVT_PLAYABLE_DURATION_MS) as number;
        durationMs = eventData?.get(TXVodConstants.EVT_PLAY_DURATION_MS) as number;
        // to update progress
        break;
        case TXVodConstants.VOD_PLAY_EVT_PLAY_END:
        this.stopProgressTimer();
        break;
        default:
        break;
    }
},
onNetStatus: (player: TXVodPlayer, statusData: Map<string, TXVodDef.ParamType>):
    void => {
        let width = statusData.get(TXVodConstants.NET_STATUS_VIDEO_WIDTH) as number;
        let height = statusData.get(TXVodConstants.NET_STATUS_VIDEO_HEIGHT) as number;
        let bitrate = statusData.get(TXVodConstants.NET_STATUS_VIDEO_BITRATE) as number;
        let fps = statusData.get(TXVodConstants.NET_STATUS_VIDEO_FPS) as number;
        let status = statusData.get(TXVodConstants.NET_STATUS_NET_SPEED) as number;
        // to update network status
        },
    });
}
```
4. 暂停播放
```typescript
private pausePlay() {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 暂停播放，停⽌获取流数据，并保持最后⼀帧图像。
    */
    vodPlayer.pause();
    // 自己实现播放进度条timer
    this.stopProgressTimer();  
}
```
5. 恢复播放
```typescript
private resumePlay() {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 恢复播放，重新获取流数据。
    *
    * 从暂停位置开始播放
    */
    vodPlayer.resume();
  	// 自己实现播放进度条timer
    this.startProgressTimer();   
}
```
6. 停⽌播放
```typescript
private stopPlay(isNeedClearLastImg: boolean) {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 停⽌播放。
    *
    * @param isNeedClearLastImg 是否清除最后⼀帧图像
    * -- true: 清除最后⼀帧图像。正常停⽌播放时建议清除
    * -- false: 保留最后⼀帧图像。异常停⽌播放（如⽹络异常导致播放被强制停⽌）且SDK⽤户
    希望重新连接服务器继续播放时建议保留。
    */
    vodPlayer.stopPlay(isNeedClearLastImg);
  	// 自己实现播放进度条timer
    this.stopProgressTimer();   
}
```
7. seek操作
```typescript
private seek(positionS: number, isAccurateSeek?: boolean) {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 跳转到视频流指定时间点
    *
    * @param timeInSeconds 视频流时间点,单位秒(s),⼩数点后精确到3位
    * @param isAccurateSeek 是否精准 Seek。不设置默认true
    * -- true: 表示精确 Seek，必须寻找到当前时间点，这个会⽐较耗时
    * -- false：表示⾮精准 Seek，也就是寻找前⼀个I帧
    */
    vodPlayer.seek(positionS, isAccurateSeek);
}
```
8. 启播后获取清晰度列表
```typescript
private getSupportedBitrates() {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 如果播放地址是主播放ArrayList，则返回⽀持的码率（清晰度）
    *
    * 只有在接收到PLAY_EVT_PLAY_BEGIN事件后才能正确返回结果
    * @return 码率ArrayList；如果没有多码率⽀持，则为空数组
    */
    let bitrateItems: TXVodDef.TXBitrateItem[] = vodPlayer.getSupportedBitrates();
}
```
9. 基于获取的清晰度列表，切换不同清晰度
```typescript
private setBitrateIndex(index: number) {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 设置当前播放的码率索引，⽆缝切换清晰度
    * 清晰度切换可能需要短暂的时间。腾讯云⽀持多码率HLS切⽚对⻬以确保最佳体验。
    *
    * @param index 码率索引，index > 0 {@link TXVodPlayer#getSupportedBitrates()}，表示
    ⼿动切换到对应清晰度的码率; index = TXVodConstants.INDEX_AUTO, 切换到多码流自适应播放模式； 
    * @see TXBitrateItem#index
    */
    vodPlayer.setBitrateIndex(index);
}
```
10. 设置倍速播放
```typescript
private setRate(rate: number) {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 设置VOD的播放速率。默认1.0
    *
    * @param rate
    */
    vodPlayer.setRate(number);
}
```
11. 设置循环播放
```typescript
private setLoop(loop: boolean) {
    let vodPlayer = this.player as TXVodPlayer;
    /**
    * 设置是否循环播放
    *
    * @param loop 是否开启循环播放
    */
    vodPlayer.setLoop(loop);
}
```

### 播放配置[TXVodPlayConfig]
<table>
<tr>
<td rowspan="1" colSpan="1" >配置属性(初始化时调用)</td>
<td rowspan="1" colSpan="1" >描述</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >connectRetryCount: number</td>
<td rowspan="1" colSpan="1" >播放器连接失败重试次数，默认3次。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >connectRetryInterval: number</td>
<td rowspan="1" colSpan="1" >播放器连接失败重试间隔，默认3秒。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >timeout: number</td>
<td rowspan="1" colSpan="1" >播放器连接超时时间，默认10秒。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >headers: Map<string, string></td>
<td rowspan="1" colSpan="1" >自定义http headers。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >connectRetryCount: number</td>
<td rowspan="1" colSpan="1" >播放器连接失败重试次数，默认3次。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >enableAccurateSeek: boolean</td>
<td rowspan="1" colSpan="1" >是否精确seek，默认true。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >smoothSwitchBitrate: boolean</td>
<td rowspan="1" colSpan="1" >平滑切换多码率HLS，默认true</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >progressInterval: number</td>
<td rowspan="1" colSpan="1" >进度回调间隔，单位毫秒，默认间隔500毫秒。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >maxBufferSize: number</td>
<td rowspan="1" colSpan="1" >最大播放缓冲大小，单位MB。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >maxPreloadSize: number。</td>
<td rowspan="1" colSpan="1" >预加载最大缓冲大小，单位MB</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >preferredResolution: number</td>
<td rowspan="1" colSpan="1" >偏好分辨率，width * height</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >mediaType: number</td>
<td rowspan="1" colSpan="1" >媒资类型，默认auto类型，建议指定具体HLS点播/mp4点播类型,可以提升启播速度</td>
</tr>
</table>

### 启播之前先设置播放参数，不设置使用默认值[TXVodPlayConfig]
1. 导⼊ liteavsdk 组件 打开pages/Index.ets ⽂件，导⼊ liteavsdk 组件。
```typescript
import { TXVodPlayer, TXVodConstants, TXVodPlayConfig } from 'liteavsdk';
```
2. 启播前设置播放配置
```typescript
private setConfig() {
    let player = this.player as TXVodPlayer;
    let config: TXVodPlayConfig = new TXVodPlayConfig();
  	// HLS多码流视频平滑切换码流，若设为false则为不平滑切换，可能存在loading情况
    config.smoothSwitchBitrate = false;
  	// HLS多码流视频偏好启播码流分辨率，向下兼容（若匹配不上，实际播放清晰度<preferredResolution)
    config.preferredResolution = 720 * 1280;
  	// 最大播放缓冲大小为5M
    config.maxBufferSize = 5;  
  	// 最大预加载缓冲大小为5M
    config.maxPreloadSize = 5;
  	// 待播放的是HLS格式点播视频源，推荐配置，可提升启播效率
    config.mediaType = TXVodConstants.MEDIA_TYPE_HLS_VOD;
  	// 待播放的是MP4格式点播视频源，推荐配置，可提升启播效率
    config.mediaType = TXVodConstants.MEDIA_TYPE_FILE_VOD; 
    player.setConfig(config);
}
```

### 下载基础接⼝[TXVodDownloadManager]
<table>
<tr>
<td rowspan="1" colSpan="1" >API</td>
<td rowspan="1" colSpan="1" >描述</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >getInstance</td>
<td rowspan="1" colSpan="1" >获取下载管理器实例。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setHeaders</td>
<td rowspan="1" colSpan="1" >设置下载Http头。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >setDownloadCallback</td>
<td rowspan="1" colSpan="1" >设置下载回调方法。下载前必须设好。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >startDownloadUrl<string, string></td>
<td rowspan="1" colSpan="1" >以url方式开始下载。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >startDownloadDataSource</td>
<td rowspan="1" colSpan="1" >以fileId方式开始下载。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >stopDownload</td>
<td rowspan="1" colSpan="1" >停止下载。ITXVodDownloadCallback.onDownloadStop回调时停止成功。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >deleteDownloadMediaInfo</td>
<td rowspan="1" colSpan="1" >删除下载信息。不支持删除正在下载的任务。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >syncGetDownloadMediaInfoList</td>
<td rowspan="1" colSpan="1" >同步获取所有下载列表信息。耗时操作, 建议worker线程中调用。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >syncGetDownloadMediaInfoByFileId</td>
<td rowspan="1" colSpan="1" >通过fileId同步获取下载信息。耗时操作, 建议worker线程中调用。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >syncGetDownloadMediaInfoByUrl</td>
<td rowspan="1" colSpan="1" >通过url同步获取下载信息。耗时操作, 建议worker线程中调用。</td>
</tr>
</table>

### 实现流程[TXVodDownloadManager]
1. 导⼊ liteavsdk 组件 打开pages/Index.ets ⽂件，导⼊ liteavsdk 组件。
```typescript
import { TXVodDownloadManager, TXVodDownloadDataSource, TXVodDownloadMediaInfo， ITXVodDownloadCallback } from 'liteavsdk';
```
2. 下载实现流程
```typescript
export class VideoDownloadModel {
    public appId: number = 0;
    public fileId: string = "";
    public pSign: string = "";
    public quality: number = 0;
    public url: string = "";
    public preferredResolution: number = 720*1280;
}

/**
 * Download callback
 *
 * 下载回调
 */
export interface VideoDownloadListener {
    /**
     * Download event listener
     * Main thread callback
     *
     * 下载事件监听
     * 主线程回调
     *
     * @param event Event
     *              事件
     * @param mediaInfo Download information
     *                  下载信息
     */
    onDownloadEvent(event: number, mediaInfo: TXVodDownloadMediaInfo): void;

    /**
     * Download failure event
     * Main thread callback
     *
     * 下载失败事件
     * 主线程回调
     *
     * @param mediaInfo Download information
     *                  下载信息
     * @param errorCode Error code
     *                  错误码
     * @param errorMsg Error message
     *                 错误信息
     */
    onDownloadError(mediaInfo: TXVodDownloadMediaInfo, errorCode: number, errorMsg: string): void;
}

export class VideoDownloadCenter {
    private static TAG: string = "VideoDownloadCenter";
    public static DOWNLOAD_EVENT_START: number = 1;
    public static DOWNLOAD_EVENT_PROGRESS: number = 2;
    public static DOWNLOAD_EVENT_STOP: number = 3;
    public static DOWNLOAD_EVENT_FINISH: number = 4;
    private downloadManager?: TXVodDownloadManager;
    private mediaInfoListeners: Map<TXVodDownloadMediaInfo, VideoDownloadListener> = new Map();
    private allMediaListeners: VideoDownloadListener[] = [];
    private static instance: VideoDownloadCenter;

    public static getInstance(): VideoDownloadCenter {
        if (!VideoDownloadCenter.instance) {
            VideoDownloadCenter.instance = new VideoDownloadCenter(getContext());
        }
        return VideoDownloadCenter.instance;
    }

    constructor(context: Context) {
        /**
         * 下载管理器
         * @return 管理器实例
         */
        this.downloadManager = TXVodDownloadManager.getInstance(context);
        /**
         * 设置下载回调方法。下载前必须设好
         * @param callback
         */
        this.downloadManager.setDownloadCallback(new CacheCenterDownloadListener(this));
    }

    // 同步获取所有下载列表信息。耗时操作, 建议worker线程中调用
    public getDownloadList(): TXVodDownloadMediaInfo[] {
        /**
         * 同步获取所有下载列表信息。耗时操作, 建议worker线程中调用
         * 调用此接口要确保之前通过{@link TXVodDownloadDataSource(int, String, int, String, String)}创建下载任务参数或者
         * 调用{@link this#startDownloadUrl}下载
         * @return 下载列表
         */
        return this.downloadManager!.syncGetDownloadMediaInfoList();
    }

    // 通过url同步获取下载信息。耗时操作, 建议worker线程中调用
    public getDownloadMediaInfoByUrl(url: string, preferredResolution?: number): TXVodDownloadMediaInfo | null {
        /**
         * 通过url同步获取下载信息。耗时操作, 建议worker线程中调用
         * 调用此接口要确保之前调用{@link this#startDownloadUrl(String, long, String)}下载的
         *
         * @param url 下载链接
         * @param preferredResolution 须与下载时传入的偏好清晰度值相同,若下载时未传入，这里不传入
         * @return
         */
        return this.downloadManager!.syncGetDownloadMediaInfoByUrl(url, preferredResolution);
    }

    // 通过fileId同步获取下载信息。耗时操作, 建议worker线程中调用
    public getDownloadMediaInfoByFileId(appId: number, fileId: string, qualityId: number): TXVodDownloadMediaInfo | null {
        /**
         * 通过fileId同步获取下载信息。耗时操作, 建议worker线程中调用
         * 调用此接口要确保之前通过{@link TXVodDownloadDataSource(int, String, int, String, String)}创建下载任务参数
         * @param appId  腾讯云视频appId
         * @param fileId 腾讯云视频文件Id
         * @param qualityId 视频画质Id具体参考{@link TXVodDownloadDataSource#QUALITY_720P 定义的常量值}
         * @return
         */
        return this.downloadManager!.syncGetDownloadMediaInfoByFileId(appId, fileId, qualityId);
    }

    public registerDownloadListener(listener: VideoDownloadListener): void {
        if (this.allMediaListeners.indexOf(listener) < 0) {
            this.allMediaListeners.push(listener);
        }
    }

    public registerDownloadListenerWithInfo(mediaInfo: TXVodDownloadMediaInfo, listener: VideoDownloadListener): void {
        if (this.mapContainsValue(this.mediaInfoListeners, listener)) {
            this.mediaInfoListeners.set(mediaInfo, listener);
        }
    }

    public unRegisterDownloadListener(listener: VideoDownloadListener): void {
        while (this.mapContainsValue(this.mediaInfoListeners, listener)) {
            this.mapRemoveByValue(this.mediaInfoListeners, listener)
        }
        const index = this.allMediaListeners.indexOf(listener);
        if (index !== -1) {
            this.allMediaListeners.splice(index, 1);
        }
    }

    // 启动下载
    public startDownload(downloadModel: VideoDownloadModel): TXVodDownloadMediaInfo {
        let downloadDataSource: TXVodDownloadDataSource | null = null;
        if (downloadModel.fileId) {
            downloadDataSource =
            new TXVodDownloadDataSource(downloadModel.appId!, downloadModel.fileId!, downloadModel.quality!,
                downloadModel.pSign);
        }
        if (downloadDataSource) {
            /**
             * 以fileId方式开始下载
             * @param dataSource fileId数据
             * @return
             */
            return this.downloadManager!.startDownloadDataSource(downloadDataSource);
        } else {
            /**
             * 以url方式开始下载
             * @param url  下载地址
             * @param preferredResolution 下载分辨率, 默认720*1280切不存在时向下匹配
             * @return
             */
            return this.downloadManager!.startDownloadUrl(downloadModel.url!, downloadModel.preferredResolution);
        }
    }

    // 停止下载
    public stopDownload(mediaInfo: TXVodDownloadMediaInfo): void {
        /**
         * 停止下载。ITXVodDownloadCallback.onDownloadStop回调时停止成功
         * @param dinfo
         */
        this.downloadManager?.stopDownload(mediaInfo);
    }

    // 恢复下载
    public resumeDownload(mediaInfo: TXVodDownloadMediaInfo): void {
        let dataSource: TXVodDownloadDataSource = mediaInfo.getDataSource();
        if (dataSource) {
            /**
             * 以fileId方式开始下载
             * @param dataSource fileId数据
             * @return
             */
            this.downloadManager?.startDownloadDataSource(dataSource);
        } else {
            /**
             * 以url方式开始下载
             * @param url  下载地址
             * @param preferredResolution 下载分辨率, 默认720*1280切不存在时向下匹配
             * @return
             */
            this.downloadManager?.startDownloadUrl(mediaInfo.getUrl(), mediaInfo.getPreferredResolution());
        }
    }

    // 删除下载信息
    public deleteDownloadMediaInfo(mediaInfo: TXVodDownloadMediaInfo): boolean {
        /**
         * 删除下载信息。不支持删除正在下载的任务
         * @param downloadMediaInfo
         */
        return this.downloadManager!.deleteDownloadMediaInfo(mediaInfo);
    }

    // 设置下载Http头
    public setHeaders(headers: Map<string, string>): void {
        /**
         * 设置下载Http头
         * @param headers
         */
        this.downloadManager?.setHeaders(headers);
    }

    public updateDownloadEvent(event: number, txVodDownloadMediaInfo: TXVodDownloadMediaInfo): void {
        for (const listener of this.allMediaListeners) {
        listener.onDownloadEvent(event, txVodDownloadMediaInfo);
        }
        this.mediaInfoListeners.forEach((listener, mediaInfo) => {
        if (mediaInfo.getDataSource() && txVodDownloadMediaInfo.dataSource) {
            let dataSource: TXVodDownloadDataSource = txVodDownloadMediaInfo.getDataSource();
            let tempDataSource: TXVodDownloadDataSource = mediaInfo.getDataSource();
            if (dataSource.getAppId() == tempDataSource.getAppId()
            && dataSource.getFileId() == tempDataSource.getFileId()
            && dataSource.getQuality() == tempDataSource.getQuality()) {
            this.mediaInfoListeners.get(mediaInfo)?.onDownloadEvent(event, txVodDownloadMediaInfo);
            }
        } else if (mediaInfo.getUrl() == txVodDownloadMediaInfo.getUrl()) {
            this.mediaInfoListeners.get(mediaInfo)?.onDownloadEvent(event, txVodDownloadMediaInfo);
        }
        });
    }

    public updateDownloadError(txVodDownloadMediaInfo: TXVodDownloadMediaInfo, errorCode: number,
        errorMsg: string): void {
        for (const listener of this.allMediaListeners) {
        listener.onDownloadError(txVodDownloadMediaInfo, errorCode, errorMsg);
        }
        this.mediaInfoListeners.forEach((listener, mediaInfo) => {
        if (this.mediaInfoListeners.has(txVodDownloadMediaInfo)) {
            listener.onDownloadError(txVodDownloadMediaInfo, errorCode, errorMsg);
        }
        });
    }

    private mapContainsValue(map: Map<TXVodDownloadMediaInfo, VideoDownloadListener>,
        value: VideoDownloadListener): boolean {
        return Array.from(map.values()).includes(value);
    }

    private mapRemoveByValue(map: Map<TXVodDownloadMediaInfo, VideoDownloadListener>,
        value: VideoDownloadListener): void {
        const keysToRemove: TXVodDownloadMediaInfo[] = [];
        map.forEach((val, key) => {
            if (val === value) {
                keysToRemove.push(key);
            }
        });
        keysToRemove.forEach((key) => {
            map.delete(key);
        });
    }
}

class CacheCenterDownloadListener implements ITXVodDownloadCallback {
    private downloadCenter: VideoDownloadCenter;

    constructor(downloadCenter: VideoDownloadCenter) {
        this.downloadCenter = downloadCenter;
    }

    onDownloadStart(mediaInfo: TXVodDownloadMediaInfo): void {
        this.downloadCenter.updateDownloadEvent(VideoDownloadCenter.DOWNLOAD_EVENT_START, mediaInfo);
    }

    onDownloadProgress(mediaInfo: TXVodDownloadMediaInfo): void {
        this.downloadCenter.updateDownloadEvent(VideoDownloadCenter.DOWNLOAD_EVENT_PROGRESS, mediaInfo);
    }

    onDownloadStop(mediaInfo: TXVodDownloadMediaInfo): void {
        this.downloadCenter.updateDownloadEvent(VideoDownloadCenter.DOWNLOAD_EVENT_STOP, mediaInfo);
    }

    onDownloadFinish(mediaInfo: TXVodDownloadMediaInfo): void {
        this.downloadCenter.updateDownloadEvent(VideoDownloadCenter.DOWNLOAD_EVENT_FINISH, mediaInfo);
    }

    onDownloadError(mediaInfo: TXVodDownloadMediaInfo, error: number, reason: string): void {
        this.downloadCenter.updateDownloadError(mediaInfo, error, reason);
    }
}
```

### 预下载基础接⼝[TXVodPreloadManager]
<table>
<tr>
<td rowspan="1" colSpan="1" >API</td>
<td rowspan="1" colSpan="1" >描述</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >getInstance</td>
<td rowspan="1" colSpan="1" >获取预下载管理器实例。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >startPreloadUrl<string, string></td>
<td rowspan="1" colSpan="1" >以url方式启动预下载。</td>
</tr>
<tr>
<td rowspan="1" colSpan="1" >stopPreload<string, string></td>
<td rowspan="1" colSpan="1" >以url方式启动预下载。</td>
</tr>
</table>

### 实现流程[TXVodPreloadManager]
1. 导⼊ liteavsdk 组件 打开pages/Index.ets ⽂件，导⼊ liteavsdk 组件。
```typescript
import { TXVodPreloadManager, ITXVodPreloadCallback } from 'liteavsdk';
```
2. 预下载实现流程
```typescript
/**
 * 预下载管理器
 * @return 管理器实例
 */
this.preloadManager = TXVodPreloadManager.getInstance(context);  

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
this. taskId = this.preloadManager.startPreloadUrl(this.url, this.preloadSizeMB, this.preferredResolution,  this.headers, {
    onComplete: (taskId: number, url: string) => {
    console.log("preload complete! taskId:" + taskId + " url: " + url);
    },
    onError: (taskId: number, url: string, code: number, msg: string) : void => {
    console.log("preload error! taskId: " + taskId + " url: " + url + " errorcode: " + code +  " errmsg: " + msg);
    }
});

/**
 * 停止预下载任务。ITXVodPreloadCallback.onPreloadStop回调时停止成功
 * @param taskId 要停止的预下载任务ID，可通过{TXVodPreloadManager#startPreloadUrl}获取
 */
this.preloadManager.stopPreload(this.taskId);
```
