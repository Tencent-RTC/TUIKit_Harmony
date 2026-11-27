/**
 * Copyright (c) 2023 Tencent. All rights reserved.
 * Module: 音速达版权音乐
 * Function: 用于下载音速达版权音乐数据
 * 此功能默认没有打包到 SDK 中，如果想使用此文件中的功能，联系腾讯单独提供 SDK。
 */
import { Context } from '@ohos.abilityAccessCtrl';
/**
 * 版权音乐下载相关的错误码
 */
export declare enum TXCopyrightedError {
    ERR_NONE = 0,
    ERR_CANCEL = -1,
    ERR_TOKEN_OVERDUE = -2,
    ERR_NET_FAILED = -3,
    ERR_INNER_ERROR = -4,
    ERR_LICENSE_FAILED = -5,
    ERR_MUSIC_IS_DOWNLOADING = -6,
    ERR_ACCOMPANIMENT_NOT_EXIST = -7,
    ERR_ORIGIN_NOT_EXIST = -8,
    ERR_LYRIC_NOT_EXIST = -9,
    ERR_MIDI_NOT_EXIST = -10,
    ERR_PREPARE_FAILED = -11,
    ERR_NOT_PREPARE = -12,
    ERR_ORIGIN_CLIMAX_SEGMENT_NOT_EXIST = -13,
    ERR_ACCOMPANIMENT_CLIMAX_SEGMENT_NOT_EXIST = -14,
    ERR_CLIMAX_SEGMENT_TIME_RANGE_NOT_EXIST = -15
}
/**
 * 片段数据结构
 */
export declare class TXClimaxTimeRange {
    startTime: number;
    endTime: number;
}
export interface ITXMusicPreloadCallback {
    /**
     *  版权音乐开始下载
     */
    onPreloadStart?: (musicId: string, bitrateDefinition: string) => void;
    /**
     *  版权音乐下载进度回调
     */
    onPreloadProgress?: (musicId: string, bitrateDefinition: string, progress: number) => void;
    /**
     *  版权音乐下载完成回调
     */
    onPreloadComplete?: (musicId: string, bitrateDefinition: string, errorCode: number, msg: string) => void;
}
export interface TXCopyrightedMedia {
    /**
     * 设置 license
     *
     * @param key
     * @param licenseUrl
     */
    setLicense(context: Context, licenseUrl: string, key: string): void;
    /**
     * 生成音乐
     *
     * URI，App客户端，播放时候调用，传给trtc进行播放。与preloadMusic一一对应
     * @param musicId 歌曲Id
     * @param bgmType 0：原唱，1：伴奏  2:  歌词  3: 音高
     * @param bitrateDefinition 码率，传nil为改音频默认码率
     */
    genMusicURI(musicId: string, bgmType: number, bitrateDefinition: string): string;
    /**
     * 设置预加载回调函数
     *
     * @param callback 回调结束后响应对象
     */
    setMusicPreloadCallback(callback: ITXMusicPreloadCallback): void;
    /**
     * 预加载音乐数据。
     *
     * @param musicId 歌曲Id，通过 AME 后台获取
     * @param playToken 播放Token，通过 AME 后台获取
     * @param bitrateDefinition 码率，传nil为音频默认码率，一般格式为：audio/mi:
     * 32,audio/lo: 64,audio/hi: 128
     */
    preloadMusic(musicId: string, bitrateDefinition: string, playToken: string): void;
    /**
     * 预加载高潮文件数据。
     *
     * @param musicId 歌曲Id，通过 AME 后台获取
     * @param playToken 播放Token，通过 AME 后台获取
     * @param bitrateDefinition 码率，传nil为音频默认码率，一般格式为：audio/mi:
     * 32,audio/lo: 64,audio/hi: 128
     */
    preloadClimaxSegment(musicId: string, bitrateDefinition: string, playToken: string): void;
    /**
     * 预加载打分和歌词文件。
     *
     * @param musicId 歌曲Id，通过 AME 后台获取
     * @param playToken 播放Token，通过 AME 后台获取
     * @param bitrateDefinition 码率，传nil为音频默认码率，一般格式为：audio/mi:
     * 32,audio/lo: 64,audio/hi: 128
     */
    preloadPitchAndLyricFile(musicId: string, bitrateDefinition: string, playToken: string): void;
    /**
     * 获取高潮片段的开始时间和结束时间
     *
     * @param musicId 歌曲Id，通过 AME 后台获取
     * @param bitrateDefinition 码率，传nil为音频默认码率，一般格式为：audio/mi:
     * 32,audio/lo: 64,audio/hi: 128
     * @param bgmType 高潮片段的类型：4：原唱高潮片段 5：伴奏高潮片段
     * @param TXClimaxTimeRange 高潮片段相当于原唱文件的相对时间戳
     * 一般下载下来的高潮片段都是比较短的。如果用高潮片段进行打分。需要将歌词文件和打分文件 seek 到相应的位置。
     * 例如一个原唱文件的高潮开始的位置在 1800ms 到 2800ms 的位置。 那么此时这两个值返回的就是 1800 和 2800。
     * 此时在打分开始的时候，可以将打分和歌词文件 seek 到 1800 的位置。当播放到 2800 的位置时结束打分即可。
     */
    getClimaxSegmentTimeRange(musicId: string, bgmType: number, bitrateDefinition: string): TXClimaxTimeRange;
    /**
     * 取消预加载音乐数据。
     *
     * @param musicId 歌曲Id，通过 AME 后台获取
     * @param bitrateDefinition 码率，传nil为改音频默认码率
     */
    cancelPreloadMusic(musicId: string, bitrateDefinition: string): void;
    /**
     * 检测是否已预加载音乐数据。
     *
     * @param musicId 歌曲Id
     * @param bitrateDefinition 码率，传nil为改音频默认码率
     */
    isMusicPreload(musicId: string, bitrateDefinition: string): boolean;
    /**
     * 清理音乐缓存
     */
    clearMusicCache(): void;
    /**
     * 通过音乐 id 清理音乐缓存。
     *
     * @param musicId 歌曲Id
     * @param bitrateDefinition 码率，传nil为改音频默认码率
     */
    clearMusicCacheByMusicId(musicId: string, bitrateDefinition: string): void;
    /**
     * 设置最大歌曲缓存数目，默认100
     *
     * @param maxCount 歌曲最大数目
     */
    setMusicCacheMaxCount(maxCount: number): void;
    /**
     * 创建打分对象
     *
     * @param sampleRate    音频采样率
     * @param channel       音频通道数
     * @param playToken     打分歌曲的play token 如果此参数为空字符串，那么内部会自动选择一首歌曲的token。
     * @param noteFilePath  打分所需音高文件路径
     * @param lyricFilePath 打分所需歌词文件路径
     */
    createSongScore(musicId: string, sampleRate: number, channel: number, playToken: string, noteFilePath: string, lyricFilePath: string): ITXSongScore;
}
/**
 * 音高数据结构
 */
export declare class TXSongScoreNoteItem {
    startTime: number;
    duration: number;
    pitch: number;
    endTime: number;
}
export interface ITXSongScoreCallback {
    /**
     * 输出每句歌词的分数
     *
     * @param currentScore  这一句的分数
     * @param totalScore    目前总分数
     * @param curIndex      歌词索引下表
     */
    onMIDISCoreUpdate?: (musicId: string, currentScore: number, totalScore: number, curIndex: number) => void;
    /**
     * 输出当前实时音高命中。
     *
     * @param isHit         是否命中
     * @param timeStamp     当前时间
     * @param pitch         在note时间范围内的用户音高
     *                     （数值可与note音高对比, -1表示不在note时间范围，大于-1表示用户音高)
     * @param viewValue     用户的实时音高
     */
    onMIDIGroveAndHint?: (musicId: string, isHit: boolean, timeStamp: number, pitch: number, viewValue: number) => void;
    /**
     * 打分回调结果
     *
     * @param scoreArray    每句歌词的分数集合
     * @param totalScore    总分
     */
    onMIDIScoreFinish?: (musicId: string, scoreArray: Array<number>, totalScore: number) => void;
    /**
     * prepare后回调
     *
     * 表明当前打分模块准备就绪，可以执行process等操作
     */
    onMIDIScorePrepared?: (musicId: string) => void;
    /**
     * 打分模块错误回调
     *
     * @param errCode   见{@link TXCopyrightedError}
     * @param errMsg    提示信息
     */
    onMIDIScoreError?: (musicId: string, errCode: TXCopyrightedError, errMsg: string) => void;
}
export interface ITXSongScore {
    /**
     * 设置打分回调接口
     *
     * @param callback 打分接口回调
     */
    setSongScoreCallback(callback: ITXSongScoreCallback): void;
    /**
     * 初始化打分模块。
     *
     * 成功则在{@link onMIDIScorePrepared}中回调，
     * 错误信息在{@link onMIDIScoreError}回调
     */
    prepare(): void;
    /**
     * 结束打分
     */
    finish(): void;
    /**
     * 销毁
     */
    destroy(): void;
    /**
     * 处理采集的人声
     *
     * @param pcmData       采集到的人声pcm数据
     * @param length        pcmData的数据大小
     * @param timeStamp     时间戳
     */
    process(pcmData: ArrayBuffer, timeStamp: number): void;
    /**
     * 升降调
     *
     * @param shiftKey 升降调的值
     * 通常用于升降音调唱歌，例如用户要提高一个半音唱歌，此时shiftKey = 1。
     * 最高12个半音，最低12个半音。（12个半音=1个八度）
     */
    setKeyShift(shiftKey: number): void;
    /**
     * 计算总分
     *
     * @return 总分
     */
    calculateTotalScore(): number;
    /**
     * 获取所有经过底层调教的Grove
     *
     * @param note_item_array 储存Grove的缓存地址，该地址由调用着提供
     * @param array_size 缓存地址的size
     * @return 实际获取到的ScoreNoteItem的个数
     */
    getAllGrove(): Array<TXSongScoreNoteItem>;
}
/**
 * 创建版权音乐实例
 */
export declare function CreateCopyRightMedia(): TXCopyrightedMedia;
/**
 * 销毁版权音乐实例
 */
export declare function DestroyCopyRightMedia(v27: TXCopyrightedMedia): void;
