/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallVideoManager @ AtomicXCore
 * Function: Manages video rendering for call participants via engine JSON bridge.
 */
/**
 * CallVideoManager bridges XComponent surfaceId (string) to the C++
 * TRTCAdapter layer via the JSON engine call interface.
 *
 * Each CallParticipantView owns its surface for the entire lifetime of the
 * view, so the manager itself stays stateless: callers simply pass the
 * surface viewId they currently hold.
 */
export declare class CallVideoManager {
    private static _shared;
    private log;
    static get shared(): CallVideoManager;
    /**
     * Bind a remote user's video stream to a surface.
     *
     * If the user is already being rendered to another surface (typical of a
     * tap-to-swap when the same user moves between the big and small slots),
     * this internally calls native `updateRemoteView` instead of `startRemoteView`
     * — that just hands the stream to the new surface without dropping the
     * subscription, so there is no black flash. A first-time bind goes through
     * `startRemoteView` as before.
     */
    openLocalCamera(viewId: string): Promise<void>;
    startRemoteView(userId: string, viewId: string): void;
    /**
     * Stop rendering a remote user's video stream.
     *
     * @param ownerViewId Caller's surface id; if a different surface has since
     *                    taken over rendering this user, the stop is skipped
     *                    so we do not tear down the new binding.
     */
    stopRemoteView(userId: string, ownerViewId?: string): void;
    /**
     * Open camera and start local preview on the previously set view.
     */
    openCamera(frontCamera?: boolean): void;
    /**
     * Close camera and stop local preview.
     */
    closeCamera(): void;
    private currentRemoteViewIds;
}
