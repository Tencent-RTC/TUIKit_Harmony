import { TXBeautyManager, TXBeautyStyle } from "./n";
import image from '@ohos.multimedia.image';
export declare class TXBeautyManagerImpl implements TXBeautyManager {
    constructor(instance: number);
    destroy(): void;
    setBeautyStyle(j1: TXBeautyStyle): void;
    setBeautyLevel(i1: number): void;
    setWhitenessLevel(h1: number): void;
    setRuddyLevel(g1: number): void;
    setFilter(pixelMap: image.PixelMap | null): void;
    setFilterStrength(strength: number): void;
    private beautyManager;
}
