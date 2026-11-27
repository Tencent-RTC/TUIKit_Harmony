import { ParamType } from "./x3";
/**
 * 播放器SDK播放配置
 */
export declare class TXVodPlayConfig {
    connectRetryCount: number;
    connectRetryInterval: number;
    timeout: number;
    headers: Map<string, string>;
    enableAccurateSeek: boolean;
    smoothSwitchBitrate: boolean;
    progressInterval: number;
    maxBufferSize: number;
    maxPreloadSize: number;
    preferredResolution: number;
    mediaType: number;
    extInfoMap?: Map<string, ParamType>;
}
