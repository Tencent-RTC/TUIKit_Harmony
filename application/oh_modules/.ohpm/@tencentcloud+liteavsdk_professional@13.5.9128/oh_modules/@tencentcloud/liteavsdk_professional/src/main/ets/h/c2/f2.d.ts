import ability from '@ohos.ability.ability';
import image from '@ohos.multimedia.image';
export interface p19 {
    onEvent?: (evtID: number, dictionary: ability.PacMap) => void;
    onNetStatus?: (dictionary: ability.PacMap) => void;
    onPlayoutVolumeUpdate?: (volume: number) => void;
    onSnapshotComplete?: (pixelMap: image.PixelMap) => void;
}
