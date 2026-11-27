import ability from '@ohos.ability.ability';
import image from '@ohos.multimedia.image';
export interface s19 {
    onMicrophoneVolumeUpdate?: (volume: number) => void;
    onSnapshotComplete?: (pixelMap: image.PixelMap) => void;
    onEvent?: (evtID: number, dictionary: ability.PacMap) => void;
    onNetStatus?: (dictionary: ability.PacMap) => void;
    h20?: (bgmID: number, errorCode: number) => void;
    i20?: (bgmID: number, curPtsMs: number, durationMs: number) => void;
    j20?: (bgmID: number, errorCode: number) => void;
}
