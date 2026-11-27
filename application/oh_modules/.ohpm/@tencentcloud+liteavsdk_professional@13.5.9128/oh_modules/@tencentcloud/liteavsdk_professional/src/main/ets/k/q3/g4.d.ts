import image from '@ohos.multimedia.image';
import { ParamType, TXVodSubtitleData } from "./x3";
import { TXVodPlayer } from "./f4";
/**
 * 腾讯云点播回调通知
 */
export interface ITXVodPlayCallback {
    onPlayEvent(player: TXVodPlayer, event: number, eventData?: Map<string, ParamType>): void;
    onNetStatus(player: TXVodPlayer, statusData: Map<string, ParamType>): void;
    onSnapshotComplete?(player: TXVodPlayer, pixelMap?: image.PixelMap): void;
    /**
     * 字幕数据回调
     * @param subtitleData 字幕数据
     */
    onSubtitleData?(player: TXVodPlayer, subtitleData: TXVodSubtitleData): void;
}
