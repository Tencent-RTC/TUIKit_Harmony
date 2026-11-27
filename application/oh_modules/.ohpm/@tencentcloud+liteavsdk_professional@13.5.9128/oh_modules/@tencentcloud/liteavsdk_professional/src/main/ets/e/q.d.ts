import { TXDeviceManager, TXAudioRoute } from "./p";
export declare class TXDeviceManagerImpl implements TXDeviceManager {
    constructor(instance: number);
    destroy(): void;
    isFrontCamera(): boolean;
    switchCamera(l1: boolean): number;
    getCameraZoomMaxRatio(): number;
    setCameraZoomRatio(zoomRatio: number): number;
    enableCameraTorch(enabled: boolean): number;
    setAudioRoute(k1: TXAudioRoute): number;
    private deviceManager;
}
