/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   RoomParticipantController @ AtomicXCore
 * Function: Controller definitions for room participant video view.
 */
import { RoomParticipant } from '../../room/RoomParticipantStore';
/** Video stream type */
export declare enum VideoStreamType {
    /** Camera video stream */
    camera = 0,
    /** Screen sharing video stream */
    screen = 1
}
/** Video fill mode */
export declare enum FillMode {
    /** Fill mode, video fills the entire view area, may crop some content */
    fill = 0,
    /** Fit mode, video displays completely, may have black borders */
    fit = 1
}
export declare function registerControllerFactory(factory: (streamType: VideoStreamType, participant: RoomParticipant) => RoomParticipantController): void;
/**
 * Controller for managing room participant video view.
 *
 * Use `RoomParticipantController.create` to create an instance,
 * then pass it to `RoomParticipantView` to display the video.
 */
export declare abstract class RoomParticipantController {
    /**
     * Create controller instance.
     * @param streamType - Video stream type
     * @param participant - Participant info
     * @returns Controller instance
     */
    static create(streamType: VideoStreamType, participant: RoomParticipant): RoomParticipantController;
    /**
     * Update video stream type.
     *
     * Switch video stream type, for example from camera to screen sharing.
     * @param streamType - Video stream type
     */
    abstract updateStreamType(streamType: VideoStreamType): void;
    /**
     * Update participant info.
     *
     * Update the participant rendered by the view, switch to display the new participant's video stream.
     * @param participant - Participant info
     */
    abstract updateParticipant(participant: RoomParticipant): void;
    /**
     * Set fill mode.
     *
     * Set the fill mode of the video, can choose FILL or FIT mode.
     * @param fillMode - Fill mode
     */
    abstract setFillMode(fillMode: FillMode): void;
    /**
     * Set active state.
     *
     * Set the active state of the view. When active, the view will render video;
     * when inactive, it will stop rendering to save resources.
     * @param isActive - Whether active
     */
    abstract setActive(isActive: boolean): void;
    /**
     * Set click callback.
     *
     * Set the callback closure when the view is clicked.
     * @param action - Click callback closure
     */
    abstract setOnClickAction(action: () => void): void;
}
