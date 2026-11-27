import { RoomParticipantController, VideoStreamType, FillMode } from '../../../api/view/room/RoomParticipantController';
import { RoomParticipant } from '../../../api/room/RoomParticipantStore';
export declare class RoomParticipantControllerImpl extends RoomParticipantController {
    _streamType: VideoStreamType;
    _participant: RoomParticipant;
    _fillMode: FillMode | undefined;
    _isActive: boolean;
    _clickAction: (() => void) | undefined;
    onUpdate: (() => void) | undefined;
    constructor(streamType: VideoStreamType, participant: RoomParticipant);
    updateStreamType(streamType: VideoStreamType): void;
    updateParticipant(participant: RoomParticipant): void;
    setFillMode(fillMode: FillMode): void;
    setActive(isActive: boolean): void;
    setOnClickAction(action: () => void): void;
}
export declare class VideoStreamManager {
    private static _shared;
    private log;
    private hdStreamUsers;
    private playCameraStreams;
    private playScreenStream;
    private constructor();
    static get shared(): VideoStreamManager;
    /**
     * The RoomModule instance is scoped by roomID on the native side, so every RoomModule.* call
     * MUST carry the current roomID; otherwise an empty-id call would spin up a second RoomModule
     * instance and clobber the correct participant state.
     */
    private currentRoomID;
    private invoke;
    openLocalCamera(viewId: string): Promise<void>;
    startPlayCameraStream(userID: string, viewID: string, viewWidth: number): void;
    stopPlayCameraStream(userID: string, viewID: string): void;
    startPlayScreenShareStream(userID: string, viewID: string): void;
    stopPlayScreenShareStream(userID: string, viewID: string): void;
    needSwitchStreamType(userID: string, viewWidth: number): boolean;
    setFillMode(userID: string, streamType: VideoStreamType, fillMode: FillMode): void;
    private invokeFillMode;
    private decideVideoStreamType;
}
