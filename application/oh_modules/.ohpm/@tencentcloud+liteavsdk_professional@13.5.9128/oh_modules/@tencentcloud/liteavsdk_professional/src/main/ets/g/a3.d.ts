/**
 * Copyright (c) 2021 Tencent. All rights reserved.
 * Module:   TRTC 音视频统计指标（只读）
 * Function: TRTC SDK 会以两秒钟一次的频率向您汇报当前实时的音视频指标（帧率、码率、卡顿情况等）
 */
import { TRTCVideoStreamType } from "./y2";
/**
 * 本地的音视频统计指标。
 */
export declare class TRTCLocalStatistics {
    width: number;
    height: number;
    frameRate: number;
    videoBitrate: number;
    audioSampleRate: number;
    audioBitrate: number;
    streamType: TRTCVideoStreamType;
    audioCaptureState: number;
}
/**
 * 远端的音视频统计指标。
 */
export declare class TRTCRemoteStatistics {
    userId: string;
    audioPacketLoss: number;
    videoPacketLoss: number;
    width: number;
    height: number;
    frameRate: number;
    videoBitrate: number;
    audioSampleRate: number;
    audioBitrate: number;
    jitterBufferDelay: number;
    point2PointDelay: number;
    audioTotalBlockTime: number;
    audioBlockRate: number;
    videoTotalBlockTime: number;
    videoBlockRate: number;
    finalLoss: number;
    remoteNetworkUplinkLoss: number;
    remoteNetworkRTT: number;
    streamType: TRTCVideoStreamType;
}
/**
 * 网络和性能的汇总统计指标。
 */
export declare class TRTCStatistics {
    appCpu: number;
    systemCpu: number;
    systemMemoryInMB: number;
    systemMemoryUsageInMB: number;
    appMemoryUsageInMB: number;
    upLoss: number;
    downLoss: number;
    rtt: number;
    gatewayRtt: number;
    sentBytes: number;
    receivedBytes: number;
    localStatisticsArray: TRTCLocalStatistics[];
    localStatisticsArraySize: number;
    remoteStatisticsArray: TRTCRemoteStatistics[];
    remoteStatisticsArraySize: number;
}
