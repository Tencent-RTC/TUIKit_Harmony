import { UIContext } from '@ohos.arkui.UIContext';
import { Context } from '@ohos.abilityAccessCtrl';
import { TXCVodPlayer } from "../m3/k4";
import { ITXVodPlayCallback } from "./g4";
import { TXBitrateItem, TXPlayInfoParams, TXTrackInfo } from "./x3";
import { TXVodPlayConfig } from "./j4";
/**
 * 点播播放器接口类
 */
export declare class TXVodPlayer {
    TAG: string;
    vodPlayer: TXCVodPlayer;
    /**
     * 构造一个TXVodPlayer对象.
     *
     * @param context 用于系统函数调用，内部会转成ApplicationContext保存.
     */
    constructor(context: Context);
    /**
     * 设置播放器配置信息.
     * 推荐在启动播放前设置配置信息.
     *
     * @param config 播放器配置信息.配置信息请参考 {@link com.tencent.rtmp.TXVodPlayConfig
     *     TXVodPlayConfig}.
     */
    setConfig(config: TXVodPlayConfig): void;
    /**
     * 设置用于视频渲染的目标。
     * 设置render
     * target之后，底层在条件满足的情况下，会开始输出视频帧。因此，在设置之前，必须确保跟该target
     * 已经根据视频流信息设置了正确的宽高，否则有可能导致前面显示若干帧宽高不正确。
     *
     * @param surfaceId surface实例的标识
     * @return
     */
    setVideoRenderTarget(surfaceId: string): void;
    /**
     * 选择轨道
     * @param trackIndex 轨道index，通过{@link TXTrackInfo#getTrackIndex()} 获取
     */
    selectTrack(b34: number): void;
    /**
     * 取消选定的轨道
     * @param trackIndex 轨道索引，通过{@link TXTrackInfo#getTrackIndex()}获得
     */
    deselectTrack(a34: number): void;
    /**
     * 返回字幕轨道信息数组列表
     * @return 字幕轨道信息数组列表
     */
    getSubtitleTrackInfo(): TXTrackInfo[];
    /**
     * 返回音频轨道信息数组列表
     * @return 音频轨道信息数组列表
     */
    getAudioTrackInfo(): TXTrackInfo[];
    /**
     * 使用fileId或url开始播放。
     *
     * @param playInfoParams 与fileId或url相关的播放信息参数
     */
    startVodPlay(z33: TXPlayInfoParams): void;
    /**
     * 停止播放。
     *
     * @param isNeedClearLastImg 是否清除最后一帧图像。true:
     *     清除最后一帧图像。正常停止播放时建议清除。false:
     *     保留最后一帧图像。异常停止播放（如网络异常导致播放被强制停止）且SDK用户希望重新连接服务器继续播放时建议保留。
     * @return 是否成功停止播放。0: 成功。非0: 失败。
     */
    stopPlay(y33: boolean): number;
    /**
     * 是否正在播放。
     *
     * @return 是否正在播放。true: 正在播放。false: 未播放。
     */
    isPlaying(): boolean;
    /**
     * 暂停播放，停止获取流数据，并保持最后一帧图像。
     */
    pause(): void;
    /**
     * 恢复播放，重新获取流数据。
     * <p>
     * <p> 点播从暂停位置开始播放，直播从当前位置开始播放实时图像。
     */
    resume(): void;
    /**
     *
     * 跳转到视频流指定时间点
     * @param timeInSeconds 视频流时间点,单位秒(s),小数点后精确到3位
     * @param isAccurateSeek 是否精准 Seek 默认true
     *                      -- true: 表示精确 Seek，必须寻找到当前时间点，这个会比较耗时
     *                      -- false：表示非精准 Seek，也就是寻找前一个I帧
     */
    seek(time: number, x33?: boolean): void;
    /**
     * 获取当前播放位置
     *
     * @return 单位秒
     */
    getCurrentPlaybackTime(): number;
    /**
     * 获取缓存时长
     * @return 单位秒
     */
    getBufferDuration(): number;
    /**
     * 获取总时长
     *
     * @return 单位秒
     */
    getDuration(): number;
    /**
     * 获取可播放时长
     *
     * @return 单位秒
     */
    getPlayableDuration(): number;
    /**
     * 获取视频宽度
     *
     * @return 视频宽度
     */
    getWidth(): number;
    /**
     * 获取视频高度
     *
     * @return 视频高度
     */
    getHeight(): number;
    /**
     * 设置播放器的回调函数。
     *
     * @param vodCallback 播放器回调。请参考{@link ITXVodPlayCallback}
     */
    setVodPlayCallback(w33: ITXVodPlayCallback): void;
    /**
     * 设置是否静音播放。
     *
     * @param mute 是否静音播放。true: 静音播放。false: 不静音播放。
     */
    setMute(mute: boolean): void;
    /**
     * 设置音量大小
     *
     * @param volume 音量大小。范围：0 ~ 100。
     */
    setAudioPlayoutVolume(volume: number): void;
    /**
     * 设置VOD在startPlay后是否自动开始播放，默认为自动播放
     *
     * @param autoPlay
     */
    setAutoPlay(autoPlay: boolean): void;
    /**
     * 设置VOD的播放速率。默认1.0
     *
     * @param rate
     */
    setRate(rate: number): void;
    /**
     * 返回当前播放的码率索引
     *
     * @return
     */
    getBitrateIndex(): number;
    /**
     * 设置当前播放的码率索引，无缝切换清晰度
     * 清晰度切换可能需要短暂的时间。腾讯云支持多码率HLS切片对齐以确保最佳体验。
     *
     * @param index 码率索引，index == -1，表示启用HLS流自适应；
     *              index > 0 {@link
     * TXVodPlayer#getSupportedBitrates()}，表示手动切换到对应清晰度的码率
     * @see TXBitrateItem#index
     */
    setBitrateIndex(index: number): void;
    /**
     * 如果播放地址是主播放ArrayList，则返回支持的码率（清晰度）
     * <p>
     * <p>只有在接收到PLAY_EVT_PLAY_BEGIN事件后才能正确返回结果
     *
     * @return 码率ArrayList；如果没有多码率支持，则为空数组
     */
    getSupportedBitrates(): TXBitrateItem[];
    /**
     * 设置播放的起始时间。
     * <p>
     * <p>在调用startPlay之前设置以修改播放的起始位置
     *
     * @param pos 视频流时间点，单位为秒（s），精确到小数点后三位
     */
    setStartTime(pos: number): void;
    /**
     * 设置是否循环播放
     *
     * @param loop 是否开启循环播放
     */
    setLoop(loop: boolean): void;
    isLoop(): boolean;
    /**
     * 设置自适应播放时能切换的最高码率
     * @param autoMaxBitrate 自适应播放时能切换的最高码率
     */
    setAutoMaxBitrate(v33: number): void;
    /**
     * 异步截图，通过onSnapshotComplete回调方法返回结果
     * @param uiContext
     * @param nativeXComponentID
     */
    snapshotAsync(uiContext: UIContext, u33: string): void;
    /**
     * 添加外挂字幕
     * @param url 字幕地址
     * @param name
     *     字幕的名字。如果添加多个字幕，字幕名称请设置为不同的名字，用于区分与其他添加的字幕，否则可能会导致字幕选择错误。
     * @param mimeType 字幕类型，仅支持VVT和SRT格式 {@link
     *     TXVodConstants#VOD_PLAY_MIMETYPE_TEXT_SRT}, {@link
     *     TXVodConstants#VOD_PLAY_MIMETYPE_TEXT_VTT}
     *  后面可以通过{@link #getSubtitleTrackInfo()}中的{@link TXTrackInfo#getName()}获取对应的名字
     */
    addSubtitleSource(url: string, name: string, mimeType: string): void;
    /**
     * 添加外挂音轨
     * @param url 外挂音轨的url
     * @param name
     *     外挂音轨的名字。如果添加多个音轨，音轨名称请设置为不同的名字，用于区分与其他添加的音轨，否则可能会导致音轨选择错误。
     *  后面可以通过{@link #getAudioTrackInfo()}中的{@link TXTrackInfo#getName()}获取对应的名字
     */
    addAudioTrackSource(url: string, name: string): void;
    /**
     * 启用或禁用视频硬解码。
     * 推荐在调用 startVodPlay 之前设置；运行中切换会重新应用解码器配置。
     *
     * @param enable true: 启用视频硬解码（默认）。false: 禁用，使用软解码。
     * @return 是否成功设置。
     */
    enableHardwareDecode(enable: boolean): boolean;
    /**
     * 挂接 TRTC 云服务，用于将点播画面/音频通过 TRTC 通道推送出去，实现"播片"场景。
     * 建议在启动播放前调用；调用 {@link #detachTRTC()} 可解除挂接。
     *
     * @param trtcCloud TRTC 云服务实例，由上层业务创建后传入
     */
    attachTRTC(t33: Object): void;
    /**
     * 解除对 TRTC 云服务的挂接，同时会自动取消音视频的推流发布。
     */
    detachTRTC(): void;
    /**
     * 将当前播放的视频画面发布到 TRTC 网络。
     * 需要先调用 {@link #attachTRTC(Object)} 完成挂接。
     */
    publishVideo(): void;
    /**
     * 停止将当前播放的视频画面发布到 TRTC 网络。
     */
    unpublishVideo(): void;
    /**
     * 将当前播放的音频发布到 TRTC 网络。
     * 需要先调用 {@link #attachTRTC(Object)} 完成挂接。
     */
    publishAudio(): void;
    /**
     * 停止将当前播放的音频发布到 TRTC 网络。
     */
    unpublishAudio(): void;
    private innerLogI;
}
