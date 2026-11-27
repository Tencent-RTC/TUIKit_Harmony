/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module: 合唱音乐播放器
 * Function: 用于实现 TRTC 房间内多人合唱功能
 */
import { TRTCParams } from "./y2";
import { TRTCCloud } from "./w2";
/**
 * 合唱角色
 */
export declare enum TXChorusRole {
    LeadSinger = 1,
    BackSinger = 2,
    Anchor = 3,
    Audience = 4
}
/**
 * 音轨类型
 */
export declare enum TXChorusMusicTrack {
    Accompaniment = 1,
    OriginalSong = 2
}
/**
 * 合唱错误码
 */
export declare enum TXChorusError {
    InvalidParameters = 1,
    TrtcCloudNotFound = 2,
    RestrictedToLeadSinger = 3,
    MusicPreloadRequired = 4,
    MusicLoadFailed = 5,
    MusicDecodeFailed = 6,
    EnterRoomFailed = 7,
    RoomDisconnected = 8,
    TrtcError = 9
}
/**
 * 合唱停止原因
 */
export declare enum TXChorusStopReason {
    Stopped = 1,
    Completed = 2,
    Error = 3,
    LeaderSingerDisconnected = 4
}
/**
 * 合唱版权音乐参数
 */
export declare class TXChorusCopyrightedMusicParams {
    musicId: string;
    playToken: string;
    copyrightedLicenseKey: string;
    copyrightedLicenseUrl: string;
}
/**
 * 外部音乐参数
 */
export declare class TXChorusExternalMusicParams {
    musicId: string;
    musicUrl: string;
    accompanyUrl: string;
    isEncrypted: boolean;
    encryptBlockLength: number;
}
/**
 * 音速达音乐参数
 */
export declare class TXChorusYsdMusicParams {
    musicId: string;
    userId: string;
    userToken: string;
    deviceId: string;
    appId: string;
    appKey: string;
    isChargedOnce: boolean;
}
/**
 * 歌词字符
 */
export declare class TXChorusLyricCharacter {
    startTimeMs: number;
    durationMs: number;
    utf8Character: string;
}
/**
 * 歌词行
 */
export declare class TXLyricLine {
    startTimeMs: number;
    durationMs: number;
    characterArray: Array<TXChorusLyricCharacter>;
}
/**
 * 合唱音乐参考音高
 */
export declare class TXReferencePitch {
    startTimeMs: number;
    durationMs: number;
    referencePitch: number;
}
/**
 * 合唱播放器事件回调接口
 */
export interface ITXChorusPlayerEventCallback {
    /**
     * 合唱错误回调
     *
     * @param errCode 错误码
     * @param errMsg 错误信息
     */
    onChorusError?: (errCode: TXChorusError, errMsg: string) => void;
    /**
     * 网络质量更新回调
     *
     * @param quality 网络质量
     * @param rtt 往返时延（毫秒）
     * @param loss 丢包率（0-100）
     */
    onNetworkQualityUpdated?: (quality: number, rtt: number, loss: number) => void;
    /**
     * 需要加载音乐回调
     *
     * @param musicId 音乐 ID
     */
    onChorusRequireLoadMusic?: (musicId: string) => void;
    /**
     * 音乐加载进度回调
     *
     * @param musicId 音乐 ID
     * @param progress 加载进度（0.0-1.0）
     */
    onChorusMusicLoadProgress?: (musicId: string, progress: number) => void;
    /**
     * 音乐加载成功回调
     *
     * @param musicId 音乐 ID
     * @param lyricList 歌词列表
     * @param pitchList 音高列表
     */
    onChorusMusicLoadSucceed?: (musicId: string, lyricList: Array<TXLyricLine>, pitchList: Array<TXReferencePitch>) => void;
    /**
     * 合唱开始回调
     */
    onChorusStarted?: () => void;
    /**
     * 合唱暂停回调
     */
    onChorusPaused?: () => void;
    /**
     * 合唱恢复回调
     */
    onChorusResumed?: () => void;
    /**
     * 合唱停止回调
     *
     * @param reason 停止原因
     */
    onChorusStopped?: (reason: TXChorusStopReason) => void;
    /**
     * 音乐播放进度更新回调
     *
     * @param progressMs 当前播放进度（毫秒）
     * @param durationMs 音乐总时长（毫秒）
     */
    onMusicProgressUpdated?: (progressMs: number, durationMs: number) => void;
    /**
     * 人声音高更新回调
     *
     * @param pitch 音高
     * @param hasVoice 是否有人声
     * @param progressMs 当前播放进度（毫秒）
     */
    onVoicePitchUpdated?: (pitch: number, hasVoice: boolean, progressMs: number) => void;
    /**
     * 人声评分更新回调
     *
     * @param currentScore 当前分数
     * @param averageScore 平均分数
     * @param currentLine 当前歌词行
     */
    onVoiceScoreUpdated?: (currentScore: number, averageScore: number, currentLine: number) => void;
    /**
     * 音频数据解密回调
     *
     * @param data 需要解密的音频数据
     */
    shouldDecryptAudioData?: (data: ArrayBuffer) => void;
}
/**
 * 合唱音乐播放器接口
 */
export interface ITXChorusMusicPlayer {
    /**
     * 设置合唱角色
     *
     * @param role 合唱角色
     * @param trtcParamsForPlayer 播放器使用的 TRTC 参数
     */
    setChorusRole(role: TXChorusRole, trtcParamsForPlayer: TRTCParams): void;
    /**
     * 加载外部音乐
     *
     * @param params 外部音乐参数
     */
    loadExternalMusic(params: TXChorusExternalMusicParams): void;
    /**
     * 开始播放
     */
    start(): void;
    /**
     * 停止播放
     */
    stop(): void;
    /**
     * 暂停播放
     */
    pause(): void;
    /**
     * 恢复播放
     */
    resume(): void;
    /**
     * 跳转到指定位置
     *
     * @param timestampMs 目标时间戳（毫秒）
     */
    seek(timestampMs: number): void;
    /**
     * 切换音乐音轨
     *
     * @param track 音轨类型
     */
    switchMusicTrack(track: TXChorusMusicTrack): void;
    /**
     * 设置本地播放音量
     *
     * @param volume 音量大小，取值范围 0-100，默认 100
     */
    setPlayoutVolume(volume: number): void;
    /**
     * 设置远端播放音量
     *
     * @param volume 音量大小，取值范围 0-100，默认 100
     */
    setPublishVolume(volume: number): void;
    /**
     * 设置音乐音调
     *
     * @param pitch 音调，默认值是 0.0f，范围是：[-1, 1] 之间的浮点数
     */
    setMusicPitch(pitch: number): void;
    /**
     * 调用隐藏接口
     *
     * @param jsonStr 隐藏接口参数
     */
    callExperimentalAPI(jsonStr: string): void;
    /**
     * 释放播放器资源
     */
    destroy(): void;
}
/**
 * 创建合唱音乐播放器实例
 *
 * @param cloud TRTCCloud 实例
 * @param roomId 房间 ID
 * @param callback 合唱事件回调
 * @returns 合唱音乐播放器实例，如果获取 cloudPtr 失败则返回 null
 */
export declare function CreateChorusMusicPlayer(j27: TRTCCloud, k27: string, callback: ITXChorusPlayerEventCallback): ITXChorusMusicPlayer | null;
