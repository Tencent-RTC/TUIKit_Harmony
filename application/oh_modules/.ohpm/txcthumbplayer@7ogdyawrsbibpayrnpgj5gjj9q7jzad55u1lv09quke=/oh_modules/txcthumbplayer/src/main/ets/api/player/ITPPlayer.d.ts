/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

import { ITPPlayerProxy } from "../common/ITPPlayerProxy";
import { TPOnInfoParam } from '../common/TPOnInfoParam'
import { TPAudioFrameBuffer } from '../common/TPAudioFrameBuffer'
import { TPOnInfoID } from '../common/TPOnInfoID'
import { TPPlayerCoreType } from '../common/TPPlayerCoreType'
import { TPPlayerState } from '../common/TPPlayerState'
import { TPError } from '../common/TPError'
import { TPDebugTrackingInfo } from '../common/TPDebugTrackingInfo'
import { TPVideoFrameBuffer } from '../common/TPVideoFrameBuffer'
import { ITPMediaAssetRequest } from './ITPMediaAssetRequest'
import { TPOptionalParam } from '../optionalparam/TPOptionalParam'
import { ITPMediaAsset } from '../asset/ITPMediaAsset'
import { TPResult } from '../common/TPResult'
import { TPSeekMode } from '../common/TPSeekMode'
import { TPVideoGravity } from '../common/TPVideoGravity'
import { TPSwitchDataSourceMode } from '../common/TPSwitchDataSourceMode'
import { TPPropertyID } from '../common/TPPropertyID'
import { TPPlayerConstructParams } from './TPPlayerConstructParams'
import { TPProgramInfo } from '../common/TPProgramInfo'
import { TPTrackInfo } from '../common/TPTrackInfo'
import { TPSubtitleData } from "../common/TPSubtitleData";

/**
 * 播放器接口
 *
 * @author colinyzhang
 * @date 2024/3/11
 */

/**
 * loopback的start position的默认值，默认为0，在 setLoopback:loopStartPositionMs:loopEndPositionMs: 中使用
 */
export const TP_PLAYER_LOOPBACK_START_POSITION_DEFAULT_MS = 0;

/**
 * loopback的end position的默认值，默认从视频尾部轮播，在 setLoopback:loopStartPositionMs:loopEndPositionMs: 中使用
 */
export const TP_PLAYER_LOOPBACK_END_POSITION_DEFAULT_MS = -1;

/**
 * 默认opaque值，比如调用 SeekToAsync: 时，外面不传opaque，
 * 则默认外面传的opaque为TPPlayerDefaultOpaque
 */
export const TP_PLAYER_DEFAULT_OPAQUE = -1;

/**
 * 获取播放器时长失败的非法值定义，在 ITPPlayer#durationMs 中使用
 */
export const TP_PLAYER_INVALID_DURATION_VALUE = -1;


/**
 * 创建播放器
 * 注意: 如果创建播放器失败返回null
 *
 * @param constructParams 可选参数
 * @return ITPPlayer播放器实例
 */
export function createTPPlayer(constructParams?: TPPlayerConstructParams): ITPPlayer | null;

/**
 * 设置播放器实例的全局代理
 * 业务方可通过设置该代理实现对createTPPlayer创建的所有播放实例进行代理
 * 可用于hook播放器接口的调用，获取播放器的运行态信息
 * 注意: 该全局方法被多次或多业务方调用时，仅会保存最后一次设置的代理，之前的设置会被覆盖掉
 *
 * @param playerProxy 播放器实例代理
 */
export function setTPPlayerProxy(playerProxy?: ITPPlayerProxy);

export interface ITPPlayer {

  /**
   * 添加播放过程中的可选参数
   * optionalParam key来源于TPOptionalID
   * 传递给传输组件的TPOptionalParam key来源于 TaskOptionalConfigParam
   *
   * @param optional_param 可选参数
   */
  addOptionalParam(optionalParam: TPOptionalParam): void;

  /**
   * 设置prepared回调
   *
   * @param callback 参考IOnPreparedCallback
   */
  setOnPreparedCallback(callback: IOnPreparedCallback | null): void;

  /**
   * 设置播放结束回调
   *
   * @param callback 参考IOnCompletionCallback
   */
  setOnCompletionCallback(callback: IOnCompletionCallback | null): void;

  /**
   * 设置播放info回调
   *
   * @param callback 参考IOnInfoCallback
   */
  setOnInfoCallback(callback: IOnInfoCallback | null): void;

  /**
   * 设置播放错误回调
   *
   * @param callback 参考IOnErrorCallback
   */
  setOnErrorCallback(callback: IOnErrorCallback | null): void;

  /**
   * 设置播放seek结束回调
   *
   * @param callback 参考IOnSeekCompleteCallback
   */
  setOnSeekCompleteCallback(callback: IOnSeekCompleteCallback | null): void;

  /**
   * 设置视频size改变的回调
   *
   * @param callback 参考IOnVideoSizeChangedCallback
   */
  setOnVideoSizeChangedCallback(callback: IOnVideoSizeChangedCallback | null): void;

  /**
   * 设置视频帧回调
   *
   * @param callback 参考IOnVideoFrameOutCallback
   */
  setOnVideoFrameOutCallback(callback: IOnVideoFrameOutCallback | null): void;

  /**
   * 设置音频帧回调
   *
   * @param callback 参考IOnAudioFrameOutCallback
   * 必须在prepare之前设置，否则不会输出音频
   */
  setOnAudioFrameOutCallback(callback: IOnAudioFrameOutCallback | null): void;

  /**
   * 设置字幕帧回调
   *
   * @param callback 参考IOnSubtitleDataOutCallback
   */
  setOnSubtitleDataOutCallback(callback: IOnSubtitleDataOutCallback | null): void;

  /**
   * 设置播放器状态改变的回调
   *
   * @param callback 参考IOnStateChangedCallback
   */
  setOnStateChangedCallback(callback: IOnStateChangedCallback | null): void;

  /**
   * 设置播放器异步停止完成的回调
   *
   * @param callback 参考IOnStopAsyncCompleteCallback
   */
  setOnStopAsyncCompleteCallback(callback: IOnStopAsyncCompleteCallback | null): void;

  /**
   * 设置播放器运行过程中的一些细节信息回调
   *
   * @param callback 参考IOnDebugTrackingInfoCallback
   */
  setOnDebugTrackingInfoCallback(callback: IOnDebugTrackingInfoCallback | null): void;

  setOnMediaAssetExpireCallback(callback: IOnMediaAssetExpireCallback | null): void;

  /**
   * 设置获取播放开始剩余时间的callback，用于内部做数据下载策略，比如正片播放前，先播广告的场景，可以返回广告还有多长时间播完
   *
   * @param callback 参考IOnGetRemainTimeBeforePlayCallback
   */
  setOnGetRemainTimeBeforePlayCallback(callback: IOnGetRemainTimeBeforePlayCallback | null): void;

  /**
   * 设置用于视频渲染的目标。
   * 设置render target之后，底层在条件满足的情况下，会开始输出视频帧。因此，在设置之前，必须确保跟该target
   * 已经根据视频流信息设置了正确的宽高，否则有可能导致前面显示若干帧宽高不正确。
   *
   * @param surfaceId surface实例的标识
   * @return 成功返回TPResult.Ok，否则，返回相应错误码。
   */
  setVideoRenderTarget(surfaceId: string | number): TPResult;

  /**
   * 设置播放源，必须在prepare之前设置
   *
   * @param mediaAsset
   * 播放源，是一个实现ITPMediaAsset的对象，支持ITPUrlMediaAsset、
   * ITPMultiMediaAsset、ITPDrmMediaAsset
   * @return 成功返回TPResult.Ok，否则，返回相应错误码。
   */
  setDataSource(mediaAsset: ITPMediaAsset): TPResult;

  /**
   * 添加外挂字幕轨，添加的轨道信息可通过 getTrackInfo() 获取
   *
   * @param subtitleAsset 字幕资源。目前仅支持支持ITPUrlMediaAsset，后续支持其他asset后再放开限制
   * @param name 该外挂字幕轨名字
   * @return 成功返回TPResult.Ok，否则返回相应的错误码
   */
  addSubtitleTrackSource(subtitleAsset: ITPMediaAsset, name: string): TPResult;

  /**
   * 添加外挂音轨，添加的轨道信息可通过 getTrackInfo() 获取
   *
   * @param audioAsset 音频资源。目前仅支持支持ITPUrlMediaAsset，后续支持其他asset后再放开限制
   * @param name 该外挂音轨名字
   * @return 成功返回TPResult.Ok，否则返回相应的错误码
   */
  addAudioTrackSource(audioAsset: ITPMediaAsset, name: string): TPResult;

  /**
   * 移除轨道
   *
   * @param trackIndex 轨道的索引，需要配合 getTrackInfo() 使用，使用其返回的索引作为参数
   * @return 成功返回TPResult.Ok，否则返回相应的错误码
   */
  removeTrack(trackIndex: number): TPResult;

  /**
   * 选择轨道
   *
   * @param trackIndex 轨道的索引，需要配合getTrackInfo()使用，使用其返回的索引作为参数
   * @param opaque 调用者自定义的一个值，底层不理解它的含义，在IOnInfoCallback.onInfo回调
   * TPOnInfoID.LONG1_SELECT_TRACK_SUCCESS 和
   * TPOnInfoID.LONG1_OBJ_SELECT_TRACK_ERROR消息时，会把这个值带回给调用者。
   */
  selectTrackAsync(trackIndex: number, opaque?: number): void;

  /**
   * 取消选择轨道，目前仅支持字幕
   *
   * @param trackIndex 轨道的索引，需要配合getTrackInfo()使用，使用其返回的索引作为参数
   * @param opaque 调用者自定义的一个值，底层不理解它的含义，在IOnInfoCallback.onInfo回调
   * TPOnInfoID.LONG1_DESELECT_TRACK_SUCCESS 和
   * TPOnInfoID.LONG1_OBJ_DESELECT_TRACK_ERROR消息时，会把这个值带回给调用者。
   */
  deselectTrackAsync(trackIndex: number, opaque?: number): void;

  /**
   * 选择一路节目，仅用于HLS，比如选择HLS中某一种码率对应的节目
   *
   * @param programIndex 要选择的节目的index。该index是指 getProgramInfo()
   * 返回的TPProgram的数组下标。
   * @param opaque 调用者自定义的一个值，底层不理解它的含义，在IOnInfoCallback.onInfo回调
   * TPOnInfoID.LONG1_SELECT_PROGRAM_SUCCESS 和
   * TPOnInfoID.LONG1_OBJ_SELECT_PROGRAM_ERROR消息时，会把这个值带回给调用者。
   */
  selectProgramAsync(programIndex: number, opaque?: number): void;

  /**
   * 获取节目信息列表，用于hls嵌套m3u8的情况，嵌套m3u8可以包含多路视频轨、多路音频轨和多路字幕轨，每路视频轨可以有各自的分辨率、带宽等，
   * 而音频轨可以是不同语言的音频，字幕轨可以是不同语言的字幕。一个节目是一个“一路视频轨+多路音频轨+多路字幕轨”的组合，即stream变体。
   * 请参考 https://www.rfc-editor.org/rfc/rfc8216.html#page-25。
   * 该方法返回所有的节目信息，请注意与getTrackInfo()的不同。
   * 返回的节目可以通过 selectProgram(programIndex: number, opaque: number): void 进行选择
   *
   * @return 返回program节目信息列表
   */
  getProgramInfo(): TPProgramInfo[];

  /**
   * prepare播放器，异步调用，需要等到IOnPreparedCallback.onPrepared回调之后才能调用start
   *
   * @return 接口调用成功返回TPResult.Ok，否则返回相应的错误码。
   *         注意，返回OK不代表prepare完成，prepare完成需等IOnPreparedCallback.onPrepared回调
   */
  prepareAsync(): TPResult;

  /**
   * 启动播放器，视频prepared之后才能调用
   *
   * @return 成功返回TPResult.Ok，否则返回相应的错误码
   */
  start(): TPResult;

  /**
   * 暂停播放器，该方法只暂停播放，但不会暂停数据的下载，如果同时需要暂停数据下载，请同时调用pause()和pauseDownload()
   *
   * @return 成功返回TPResult.Ok，否则返回相应的错误码
   */
  pause(): TPResult;

  /**
   * 停止播放器
   *
   * @return 成功返回TPResult.Ok，否则返回相应的错误码
   */
  stop(): TPResult;

  /**
   * 异步停止播放器.
   *
   * 播放器的stop会做一些资源释放，如果在UI线程调用同步stop接口，偶尔会卡一下UI线程。
   * 而此接口是在异步线程中进行释放，不会卡住调用线程。但是后续调用上与同步stop不同，
   * stop操作完成后触发IOnStopAsyncCompleteCallback.onStopAsyncComplete回调，
   * 之后再继续调用其他接口，比如reset等接口。
   */
  stopAsync(): void;

  /**
   * 重置播放器，重置后播放器实例可复用进行新的播放任务
   */
  reset(): void;

  /**
   * release播放器，release之后播放器不能再使用
   */
  release(): void;

  /**
   * seek到指定的时间点
   *
   * @param positionMs seek到的位置，单位毫秒
   * @param mode seek的模式，参考TPSeekMode，不传则采取默认策略
   * @param opaque 调用者自定义的一个值，底层不理解它的含义，不传默认为TP_PLAYER_DEFAULT_OPAQUE
   *               在回调
   * IOnSeekCompleteCallback.onSeekComplete(player: ITPPlayer, opaque: number)
   *               消息时，会把这个值带回给调用者。
   * @return 接口调用成功返回TPResult.Ok，否则返回相应的错误码
   */
  seekToAsync(positionMs: number, mode?: TPSeekMode, opaque?: number): TPResult;

  /**
   * 设置静音模式
   *
   * @param isMute 是否静音
   */
  setAudioMute(isMute: boolean): void;

  /**
   * 设置音量
   *
   * @param volume 音量的大小值，默认值为1.0
   */
  setAudioVolume(volume: number): void;

  /**
   * 设置播放速度
   *
   * @param speedRatio 播放速度
   */
  setPlaySpeedRatio(speedRatio: number): void;

  /**
   * 设置视频画面拉伸模式
   *
   * @param gravity 拉伸模式
   */
  setVideoGravity(gravity: TPVideoGravity): void;

  /**
   * 设置循环播放，可以指定循环播放的区间
   *
   * @param isLoopback 是否循环播放
   * @param loopStartPositionMs
   *        需要循环播放的起始点，如果是从头开始传TP_PLAYER_LOOPBACK_START_POSITION_DEFAULT_MS，不传则默认为从头开始
   * @param loopEndPositionMs
   *        需要循环播放的结束点，如果是从尾部轮播可以传TP_PLAYER_LOOPBACK_END_POSITION_DEFAULT_MS或视频的duration
   *        不传默认为到视频末尾结束
   */
  setLoopback(isLoopback: boolean, loopStartPositionMs?: number, loopEndPositionMs?: number): void;

  /**
   * 切换播放源，即切换同一个视频的不同源，比如同一个视频，从一个分辨率切换到另一个分辨率。
   *
   * @param mediaAsset 播放源
   * @param mode 换源模式，不传则采取默认策略
   * @param opaque 调用者自定义的一个值，底层不理解它的含义，在IOnInfoCallback.onInfo回调回调
   * TPOnInfoID.LONG1_SWITCH_DATA_SOURCE_SUCCESS 消息时，会把这个值带回给调用者。
   * @return 接口调用成功返回TPResult.Ok，否则返回相应的错误码
   */
  switchDataSourceAsync(mediaAsset: ITPMediaAsset, mode?: TPSwitchDataSourceMode, opaque?: number): TPResult;

  /**
   * 切换播放源同时选择轨道
   *
   * @param mediaAsset 播放源
   * @param mode 换源模式
   * @param tracksIndex 待选择的轨道下标
   * @param opaque 调用者自定义的一个值，底层不理解它的含义，在IOnInfoCallback.onInfo回调回调
   * TPOnInfoID.LONG1_SWITCH_DATA_SOURCE_SUCCESS 消息时，会把这个值带回给调用者。
   * @return 接口调用成功返回TPResult.Ok，否则返回相应的错误码
   */
  switchDataSourceAndSelectTrackAsync(mediaAsset: ITPMediaAsset, mode: TPSwitchDataSourceMode, tracksIndex: number[],
    opaque: number): TPResult;

  /**
   * 获取播放器属性
   *
   * @param propertyId 属性id，详见TPPropertyID
   * @return propertyId对应的参数值.如果获取失败，将返回空字符串
   */
  getProperty(propertyId: TPPropertyID): string;

  /**
   * 获取视频的时长.如果获取失败，将返回TP_PLAYER_INVALID_DURATION_VALUE
   *
   * @return 返回视频时长
   */
  getDurationMs(): number;

  /**
   * 获取当前播放的位置
   *
   * @return 播放位置，单位为毫秒
   */
  getCurrentPositionMs(): number;

  /**
   * 获取当前播放的状态，注意该接口可能比较耗时
   *
   * @return 播放器的状态
   */
  getCurrentState(): TPPlayerState;

  /**
   * 获取播放器当前缓存数据可播放到的位置。单位毫秒。
   * 例如，当前播放位置是5000ms，而播放器已缓冲到10000ms，则该方法返回10000ms，即可以继续从5000ms播放到10000ms。
   * 注意:在使用下载组件的时候，MP4等格式文件，此数值是根据码率、下载后的文件长度以及总文件长度进行估算所得，所以会有一些偏差.
   *
   * @return 可播位置。单位为毫秒
   */
  getAvailablePositionMs(): number;

  /**
   * 获取视频宽
   *
   * @return 视频宽
   */
  getWidth(): number;

  /**
   * 获取视频高
   *
   * @return 视频高
   */
  getHeight(): number;

  /**
   * 返回轨道信息，包括外部添加的轨道和播放源中内嵌的轨道。
   * 对于音频轨和字幕轨，可以通过 selectTrack(trackIndex: number, opaque: number)进行选择，通过
   * dselectTrack(trackIndex: number, opaque: number)进行反选。 如果有多路视频轨，比如hls嵌套m3u8的情况（见
   * getProgramInfo()），该方法只返回当前播放的视频轨道，且不可select和deselect。
   * 注意：请不要存储返回信息，每次需要信息时，直接调用此接口，因为内部发生重试等逻辑时，TrackInfo可能会发生变更
   *
   * @return 轨道信息列表
   */
  getTrackInfo(): TPTrackInfo[];

  /**
   * 暂停数据下载，该方法与pause方法不同，pause只是暂停播放，该方法只暂停数据的下载
   */
  pauseDownload(): void;

  /**
   * 恢复数据下载
   */
  resumeDownload(): void;

  /**
   * 返回当前播放内核类型，详见TPPlayerCoreType
   *
   * @return 播放内核类型
   */
  getPlayerCoreType(): TPPlayerCoreType;

  /**
   * 设置log tag前缀，实时生效。
   * 建议在IDLE状态设置，不要在播放过程中设置，比如构造完播放器实例之后立刻设置，或者在复用同一个播放器实例情况下，
   * 调用reset之后，启动一次新的播放前，调用方如想更新log tag前缀，可调用该方法更新log tag前缀。
   *
   * @param logTagPrefix 日志前缀
   */
  setLogTagPrefix(logTagPrefix: string): void;
}

export interface IOnPreparedCallback {
  /**
   * 视频prepared回调
   *
   * @param player 当前播放器的实例
   */
  onPrepared(player: ITPPlayer): void;
}

export interface IOnCompletionCallback {
  /**
   * 播放结束回调
   *
   * @param player 当前播放器的实例
   */
  onCompletion(player: ITPPlayer): void;
}

export interface IOnInfoCallback {
  /**
   * 消息回调
   *
   * @param player 当前播放器的实例
   * @param onInfoId 消息ID，参考TPOnInfoID
   * @param onInfoParam 消息参数
   */
  onInfo(player: ITPPlayer, onInfoId: TPOnInfoID, onInfoParam: TPOnInfoParam | null): void;
}

export interface IOnErrorCallback {
  /**
   * 播放错误回调
   *
   * @param player 当前播放器的实例
   * @param error 错误信息
   */
  onError(player: ITPPlayer, error: TPError): void;
}

export interface IOnSeekCompleteCallback {
  /**
   * seek结束回调
   *
   * @param player 当前播放器的实例
   * @param opaque 调用ITPPlayer::SeekToAsync(int64_t, int64_t) 或
   * ITPPlayer.seekTo 传入的opaque参数
   */
  onSeekComplete(player: ITPPlayer, opaque: number): void;
}

export interface IOnVideoSizeChangedCallback {
  /**
   * 视频size发生改变
   *
   * @param player 当前播放器的实例
   * @param width 视频宽
   * @param height 视频高
   */
  onVideoSizeChanged(player: ITPPlayer, width: number, height: number): void;
}

export interface IOnVideoFrameOutCallback {
  /**
   * 视频帧数据输出
   *
   * @param player 当前播放器的实例
   * @param videoFrame 视频帧数据
   */
  onVideoFrameOut(player: ITPPlayer, videoFrame: TPVideoFrameBuffer): void;
}

export interface IOnAudioFrameOutCallback {
  /**
   * 音频pcm数据输出
   *
   * @param player 当前播放器的实例
   * @param audioFrame 音频pcm数据
   */
  onAudioFrameOut(player: ITPPlayer, audioFrame: TPAudioFrameBuffer): void;
}

export interface IOnSubtitleDataOutCallback {
  /**
   * 字幕帧数据输出
   *
   * @param player 当前播放器的实例
   * @param subtitleData 字幕数据，null为非法值，如果不为null，请参考{@link TPSubtitleData}
   */
  onSubtitleDataOut(player: ITPPlayer, subtitleData: TPSubtitleData): void;
}

export interface IOnStateChangedCallback {
  /**
   * 播放状态流转回调
   *
   * @param player 当前播放器的实例
   * @param preState 前一个状态
   * @param curState 当前状态
   */
  onStateChanged(player: ITPPlayer, preState: TPPlayerState, curState: TPPlayerState): void;
}

export interface IOnStopAsyncCompleteCallback {
  /**
   * 异步停止播放器完成通知。调用ITPPlayer.stopAsync()
   * 后，通过此接口通知异步停止播放器已经完成。
   * 可以在此接口内再继续调用其他接口，比如Reset等接口。
   *
   * @param player 当前播放器的实例
   */
  onStopAsyncComplete(player: ITPPlayer): void;
}

export interface IOnDebugTrackingInfoCallback {
  /**
   * 播放器运行过程中的一些细节信息回调
   *
   * @param player 当前播放器的实例
   * @param info 详细信息
   */
  onDebugTrackingInfo(player: ITPPlayer, info: TPDebugTrackingInfo): void;
}

export interface IOnGetRemainTimeBeforePlayCallback {
  /**
   * 获取播放开始还需要的时间
   *
   * @param player 当前播放器的实例
   * @return 播放开始需要的时间，单位毫秒
   */
  onGetRemainTimeBeforePlayMs(player: ITPPlayer): number;
}

export interface IOnMediaAssetExpireCallback {
  /**
   * asset过期回调，调用方收到该回调后，准备好新的资源后，需通过该回调携带的request来向播放器传递一个新的asset。
   *
   * @param player 当前播放器的实例
   * @param request
   * 调用方通过该request向播放器更新资源，调用方如需向后台请求资源，需先保存下该request，
   *                待资源准备好后，通过该request来向播放器传递一个新的asset。
   */
  onMediaAssetExpire(player: ITPPlayer, request: ITPMediaAssetRequest): void;
}
