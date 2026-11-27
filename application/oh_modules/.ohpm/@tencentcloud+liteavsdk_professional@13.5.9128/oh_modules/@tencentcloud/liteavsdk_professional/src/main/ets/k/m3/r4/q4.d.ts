import { ParamType } from "../../q3/x3";
export declare class TXVCubePlayerConfig {
    connectRetryCount: number;
    connectRetryInterval: number;
    timeout: number;
    enableHardwareDecode: boolean;
    playerType: number;
    headers?: Map<string, string>;
    enableAccurateSeek: boolean;
    smoothSwitchBitrate: boolean;
    cacheMp4ExtName: string;
    progressInterval: number;
    maxBufferSize: number;
    maxPreloadSize: number;
    startPlayTimeMs: number;
    autoPlay: boolean;
    videoPath: string;
    preferredBitrate: number;
    preferredBitrateIndex: number;
    autoPreferredResolution: number;
    /**
     * Hls多Program时，根据设定的mPreferredResolution选最优的Program进行起播，mPreferredResolution是宽高的乘积
     * 配置有效值为>=-1的整形数，缺省为-1播放内核理解为应使用优先级更低的信息进行配置，会从小于该值的program中匹配算数距离最接近的
     * 优先级为 bitrateIndex > mPreferredBitrate > mPreferredResolution
     */
    preferredResolution: number;
    autoRotate: boolean;
    overlayKey: string;
    overlayIv: string;
    enableAdaptiveBitrate: boolean;
    extInfoMap?: Map<string, ParamType>;
    enableRenderProcess: boolean;
    mediaType: number;
    vInfo: string;
}
