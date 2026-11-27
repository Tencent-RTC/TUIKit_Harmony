/**
 * 1.1 混响特效
 *
 * 混响特效可以作用于人声之上，通过声学算法对声音进行叠加处理，模拟出各种不同环境下的临场感受，目前支持如下几种混响效果：
 * 0：关闭；1：KTV；2：小房间；3：大会堂；4：低沉；5：洪亮；6：金属声；7：磁性；8：空灵；9：录音棚；10：悠扬；11：录音棚2；
 */
export declare enum TXVoiceReverbType {
    TXLiveVoiceReverbType_0 = 0,
    TXLiveVoiceReverbType_1 = 1,
    TXLiveVoiceReverbType_2 = 2,
    TXLiveVoiceReverbType_3 = 3,
    TXLiveVoiceReverbType_4 = 4,
    TXLiveVoiceReverbType_5 = 5,
    TXLiveVoiceReverbType_6 = 6,
    TXLiveVoiceReverbType_7 = 7,
    TXLiveVoiceReverbType_8 = 8,
    TXLiveVoiceReverbType_9 = 9,
    TXLiveVoiceReverbType_10 = 10,
    TXLiveVoiceReverbType_11 = 11
}
/**
 * 1.2 变声特效
 *
 * 变声特效可以作用于人声之上，通过声学算法对人声进行二次处理，以获得与原始声音所不同的音色，目前支持如下几种变声特效：
 * 0：关闭；1：熊孩子；2：萝莉；3：大叔；4：重金属；5：感冒；6：外语腔；7：困兽；8：肥宅；9：强电流；10：重机械；11：空灵；12：猪八戒；13：绿巨人；
 */
export declare enum TXVoiceChangerType {
    TXVoiceChangerType_0 = 0,
    TXVoiceChangerType_1 = 1,
    TXVoiceChangerType_2 = 2,
    TXVoiceChangerType_3 = 3,
    TXVoiceChangerType_4 = 4,
    TXVoiceChangerType_5 = 5,
    TXVoiceChangerType_6 = 6,
    TXVoiceChangerType_7 = 7,
    TXVoiceChangerType_8 = 8,
    TXVoiceChangerType_9 = 9,
    TXVoiceChangerType_10 = 10,
    TXVoiceChangerType_11 = 11,
    TXVoiceChangerType_12 = 12,
    TXVoiceChangerType_13 = 13
}
export interface TXMusicPreloadObserver {
    /**
     * 背景音乐预加载进度
     */
    onLoadProgress?: (id: number, progress: number) => void;
    /**
     * 背景音乐预加载出错
     * @param errorCode -4001:打开文件失败，如音频数据无效，FFMPEG 协议未找到等；-4002:解码失败，如音频文件损坏，网络音频文件服务器无法访问等；-4003:预加载数量超上限，请先调用 stopPlayMusic
     *     释放无用的预加载；-4005:非法路径导致打开文件失败，请检查您传入的路径参数是否指向一个合法的音乐文件；-4006:非法URL导致打开文件失败，请用浏览器检查您传入的 URL
     *     地址是否可以下载到期望的音乐文件；-4007:无音频流导致打开文件失败，请确认您传入的文件是否是合法的音频文件，以及文件是否被损坏；-4008:格式不支持导致打开文件失败，请确认您传入的文件格式是否是支持的文件格式，移动端支持【mp3，aac，m4a，wav，ogg，mp4，mkv】，桌面端支持
     *     【mp3，aac，m4a，wav，mp4，mkv】。
     */
    onLoadError?: (id: number, errorCode: number) => void;
}
export interface TXMusicPlayObserver {
    /**
     * 背景音乐开始播放
     *
     * 在背景音乐开始播放成功或者失败时调用。
     * @param id 音乐 ID。
     * @param errCode 错误码。0: 开始播放成功；-4001:打开文件失败，如音频数据无效，FFMPEG 协议未找到等；-4005:非法路径导致打开文件失败，请检查您传入的路径参数是否指向一个合法的音乐文件；-4006:非法URL导致打开文件失败，请用浏览器检查您传入的 URL
     *     地址是否可以下载到期望的音乐文件，如果操作系统为 iOS 或 MacOS 请确保使用 https
     *     链接；-4007:无音频流导致打开文件失败，请确认您传入的文件是否是合法的音频文件，以及文件是否被损坏；-4008:格式不支持导致打开文件失败，请确认您传入的文件格式是否是支持的文件格式，移动端支持【mp3，aac，m4a，wav，ogg，mp4，mkv】，桌面端支持
     *     【mp3，aac，m4a，wav，mp4，mkv】；-4009:同时播放 bgm 数量超过限定值，如当前同时播放 bgm 数量超过 10 后提示该错误，请检查并发播放 bgm 数量。
     */
    onStart?: (id: number, errCode: number) => void;
    /**
     * 背景音乐的播放进度
     */
    onPlayProgress?: (id: number, curPtsMS: number, duratioinMS: number) => void;
    /**
     * 背景音乐已经播放完毕
     *
     * 在背景音乐播放完毕或播放错误时调用。
     * @param id 音乐 ID。
     * @param errCode 错误码。0: 播放结束；-4002: 解码失败，如音频文件损坏，网络音频文件服务器无法访问等。
     */
    onComplete?: (id: number, errCode: number) => void;
}
/**
 * 背景音乐的播放控制信息
 *
 * 该信息用于在接口 {@link startPlayMusic} 中指定背景音乐的相关信息，包括播放 ID、文件路径和循环次数等：
 * 1. 如果要多次播放同一首背景音乐，请不要每次播放都分配一个新的 ID，我们推荐使用相同的 ID。
 * 2. 若您希望同时播放多首不同的音乐，请为不同的音乐分配不同的 ID 进行播放。
 * 3. 如果使用同一个 ID 播放不同音乐，SDK 会先停止播放旧的音乐，再播放新的音乐。
 */
export declare class AudioMusicParam {
    id: number;
    path: string;
    loopCount: number;
    publish: boolean;
    isShortFile: boolean;
    startTimeMS: number;
    endTimeMS: number;
    constructor(id?: number, path?: string);
}
export interface TXAudioEffectManager {
    /**
     * 1.1 开启耳返。
     *
     * 主播开启耳返后，可以在耳机里听到麦克风采集到的自己发出的声音，该特效适用于主播唱歌的应用场景中。
     * 需要您注意的是，由于蓝牙耳机的硬件延迟非常高，所以在主播佩戴蓝牙耳机时无法开启此特效，请尽量在用户界面上提示主播佩戴有线耳机。
     * 同时也需要注意，并非所有的手机开启此特效后都能达到优秀的耳返效果，我们已经对部分耳返效果不佳的手机屏蔽了该特效。
     * @param enable true：开启；false：关闭。
     * @note 仅在主播佩戴耳机时才能开启此特效，同时请您提示主播佩戴有线耳机。
     */
    enableVoiceEarMonitor(enable: boolean): void;
    /**
     * 1.2 设置耳返音量。
     *
     * 通过该接口您可以设置耳返特效中声音的音量大小。
     * @param volume 音量大小，取值范围为 [0, 150]，默认值：100。
     * @note 耳返的音量大小是影响用户耳返体验的重要因素之一，考虑到不同用户对音量的敏感度不同，强烈建议您在 UI 界面上开放耳返音量的调节滑杆，调节范围建议在 0~150 之间，其中 100~150 的增益效果对于部分采集音量较小的 Android 手机很有帮助。
     */
    setVoiceEarMonitorVolume(volume: number): void;
    /**
     * 1.3 设置人声的混响效果。
     *
     * 通过该接口您可以设置人声的混响效果，具体特效请参见枚举定义 {@link TXVoiceReverbType}。
     * @note 设置的效果在退出房间后会自动失效，如果下次进房还需要对应特效，需要调用此接口再次进行设置。
     */
    setVoiceReverbType(type: TXVoiceReverbType): void;
    /**
     * 1.4 设置人声的变声特效。
     *
     * 通过该接口您可以设置人声的变声特效，具体特效请参见枚举定义 {@link TXVoiceChangeType}。
     * @note 设置的效果在退出房间后会自动失效，如果下次进房还需要对应特效，需要调用此接口再次进行设置。
     */
    setVoiceChangerType(type: TXVoiceChangerType): void;
    /**
     * 1.5 设置语音音量。
     *
     * 该接口可以设置语音音量的大小，一般配合音乐音量的设置接口 {@link setAllMusicVolume} 协同使用，用于调谐语音和音乐在混音前各自的音量占比。
     * @param volume 音量大小，取值范围为 [0 - 150]，默认值：100。
     * @note 如果将 volume 设置成 100 之后感觉音量还是太小，可以将 volume 最大设置成 150，但超过 100 的 volume 会有爆音的风险，请谨慎操作。
     */
    setVoiceCaptureVolume(volume: number): void;
    /**
     * 1.6 设置语音音调。
     *
     * 该接口可以设置语音音调，用于实现变调不变速的目的。
     * @param pitch 音调，取值范围[-1.0f, 1.0f]，默认值：0.0f。
     */
    setVoicePitch(pitch: number): void;
    /**
     * 2.0 设置背景音乐的事件回调接口。
     *
     * 请在播放背景音乐之前使用该接口设置播放事件回调，以便感知背景音乐的播放进度。
     * @param musicId   音乐 ID。
     * @param observer  具体参考 {@link TXMusicPlayObserver} 中定义接口。
     * @note
     * 1. 如果该 ID 不需要使用，observer 可设置为 NULL 彻底释放。
     */
    setMusicObserver(musicId: number, observer: TXMusicPlayObserver): void;
    /**
     * 2.1 开始播放背景音乐。
     *
     * 每个音乐都需要您指定具体的 ID，您可以通过该 ID 对音乐的开始、停止、音量等进行设置。
     * @param musicParam 音乐参数。
     * @note
     * 1. 如果要多次播放同一首背景音乐，请不要每次播放都分配一个新的 ID，我们推荐使用相同的 ID。
     * 2. 若您希望同时播放多首不同的音乐，请为不同的音乐分配不同的 ID 进行播放。
     * 3. 如果使用同一个 ID 播放不同音乐，SDK 会先停止播放旧的音乐，再播放新的音乐。
     */
    startPlayMusic(musicParam: AudioMusicParam): void;
    /**
     * 2.2 停止播放背景音乐。
     *
     * @param id  音乐 ID。
     */
    stopPlayMusic(id: number): void;
    /**
     * 2.3 暂停播放背景音乐。
     *
     * @param id  音乐 ID。
     */
    pausePlayMusic(id: number): void;
    /**
     * 2.4 恢复播放背景音乐。
     *
     * @param id  音乐 ID。
     */
    resumePlayMusic(id: number): void;
    /**
     * 2.5 设置所有背景音乐的本地音量和远端音量的大小。
     *
     * 该接口可以设置所有背景音乐的本地音量和远端音量。
     * - 本地音量：即主播本地可以听到的背景音乐的音量大小。
     * - 远端音量：即观众端可以听到的背景音乐的音量大小。
     * @param volume 音量大小，取值范围为 [0, 150]，默认值：60。
     * @note 如果将 volume 设置成 100 之后感觉音量还是太小，可以将 volume 最大设置成 150，但超过 100 的 volume 会有爆音的风险，请谨慎操作。
     */
    setAllMusicVolume(id: number): void;
    /**
     * 2.6 设置某一首背景音乐的远端音量的大小。
     *
     * 该接口可以细粒度地控制每一首背景音乐的远端音量，也就是观众端可听到的背景音乐的音量大小。
     * @param id     音乐 ID。
     * @param volume 音量大小，取值范围为 [0, 150]；默认值：60。
     * @note 如果将 volume 设置成 100 之后感觉音量还是太小，可以将 volume 最大设置成 150，但超过 100 的 volume 会有爆音的风险，请谨慎操作。
     */
    setMusicPublishVolume(id: number, volume: number): void;
    /**
     * 2.7 设置某一首背景音乐的本地音量的大小。
     *
     * 该接口可以细粒度地控制每一首背景音乐的本地音量，也就是主播本地可以听到的背景音乐的音量大小。
     * @param id     音乐 ID。
     * @param volume 音量大小，取值范围为 [0, 150]，默认值：60。
     * @note 如果将 volume 设置成 100 之后感觉音量还是太小，可以将 volume 最大设置成 150，但超过 100 的 volume 会有爆音的风险，请谨慎操作。
     */
    setMusicPlayoutVolume(id: number, volume: number): void;
    /**
     * 2.8 调整背景音乐的音调高低。
     *
     * @param id    音乐 ID。
     * @param pitch 音调，取值范围为 [-1.0f, 1.0f] 之间的浮点数，默认值：0.0f。
     */
    setMusicPitch(id: number, pitch: number): void;
    /**
     * 2.9 调整背景音乐的变速效果。
     *
     * @param id    音乐 ID。
     * @param speedRate 速度，取值范围为 [0.5f, 2.0f] 之间的浮点数，默认值：1.0f。
     */
    setMusicSpeedRate(id: number, speedRate: number): void;
    /**
     * 2.10 获取背景音乐的播放进度（单位：毫秒）。
     *
     * @param id    音乐 ID。
     * @return 成功返回当前播放时间，单位：毫秒，失败返回 -1。
     */
    getMusicCurrentPosInMS(id: number): number;
    /**
     * 2.11 获取背景音乐的总时长（单位：毫秒）。
     *
     * @param path 音乐文件路径。
     * @return 成功返回时长，失败返回 -1。
     */
    getMusicDurationInMS(path: string): number;
    /**
     * 2.12 设置背景音乐的播放进度（单位：毫秒）。
     *
     * @param id  音乐 ID。
     * @param pts 单位: 毫秒。
     * @note 请尽量避免过度频繁地调用该接口，因为该接口可能会再次读写音乐文件，耗时稍高。
     *       因此，当用户拖拽音乐的播放进度条时，请在用户完成拖拽操作后再调用本接口。
     *       因为 UI 上的进度条控件往往会以很高的频率反馈用户的拖拽进度，如不做频率限制，会导致较差的用户体验。
     */
    seekMusicToPosInTime(id: number, pts: number): void;
    /**
     * 2.13 调整搓碟的变速效果。
     *
     * @param id    音乐 ID。
     * @param scratchSpeedRate 搓碟速度，取值范围为 [-12.0, 12.0] 之间的浮点数，默认值是 1.0f，速度值正/负表示方向正/反，绝对值大小表示速度快慢。
     * @note 前置条件 preloadMusic 成功。
     */
    setMusicScratchSpeedRate(id: number, scratchSpeedRate: number): void;
    /**
     * 2.14 设置预加载事件回调。
     *
     * 请在预加载背景音乐之前使用该接口设置回调，以便感知背景音乐的预加载进度。
     * @param observer  具体参考 {@link TXMusicPreloadObserver} 中定义接口。
     */
    setPreloadObserver(observer: TXMusicPreloadObserver): void;
    /**
     * 2.15 预加载背景音乐。
     *
     * 每个音乐都需要您指定具体的 ID，您可以通过该 ID 对音乐的开始、停止、音量等进行设置。
     * @param preloadParam 预加载音乐参数。
     * @note
     * 1. 预先加载最多同时支持2个不同 ID 的预加载，且预加载时长不超过10分钟，使用完需调用 {@link stopPlayMusic}，否则内存不释放。
     * 2. 若该ID对应的音乐正在播放中，预加载会失败，需先调用 {@link stopPlayMusic}。
     * 3. 当 `musicParam` 和传入 {@link startPlayMusic} 的 `musicParam` 完全相同时，预加载有效。
     */
    preloadMusic(preloadParam: AudioMusicParam): void;
    /**
     * 2.16 获取背景音乐的音轨数量。
     *
     * @param id 音乐 ID。
     */
    getMusicTrackCount(id: number): number;
    /**
     * 2.17 指定背景音乐的播放音轨。
     *
     * @param id    音乐 ID。
     * @param index 默认播放第一个音轨。取值范围[0, 音轨总数)。
     * @note 音轨总数量可通过 getMusicTrackCount 接口获取。
     */
    setMusicTrack(id: number, trackIndex: number): void;
}
