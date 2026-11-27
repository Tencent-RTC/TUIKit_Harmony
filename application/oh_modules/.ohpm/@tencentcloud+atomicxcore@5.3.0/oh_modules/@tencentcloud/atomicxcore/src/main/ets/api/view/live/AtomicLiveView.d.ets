/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   AtomicLiveView @ AtomicXCore
 * Function: Minimal atomic view container that hosts a single render surface
 *           for pure playback / preview scenarios. Only exposes the underlying
 *           render view without live-room, seat, co-guest or PK related APIs.
 */
import { DeviceStatus } from '../../device/DeviceStore';
import { SuspendStatus } from '../../live/LiveSeatStore';
export { SuspendStatus };
/**
 * Render type of AtomicLiveView, mirroring AtomicLiveViewType on iOS / Android.
 */
export declare enum AtomicLiveViewType {
    /** Play view, used with AtomicPlayer. */
    playView = 0,
    /** Push view, used with AtomicPusher. */
    pushView = 1
}
/**
 * Live unit info, describing a single seat rendered on the AtomicLiveView.
 */
export declare class UnitInfo {
    /** Unit index. */
    index: number;
    /** Live ID. */
    liveID: string;
    /** User ID. */
    userID: string;
    /** User name. */
    userName: string;
    /** Avatar URL. */
    avatarURL: string;
    /** Microphone status. */
    microphoneStatus: DeviceStatus;
    /** Camera status. */
    cameraStatus: DeviceStatus;
    /** User suspend status. */
    userSuspendStatus: SuspendStatus;
}
/**
 * AtomicLiveView widget adapter. Implement this to provide overlay sub-UIs
 * for the current AtomicLiveView as needed, and receive callbacks such as
 * video view frame changes. The SDK mounts them at the correct layer above
 * the render view without affecting the underlying rendering.
 *
 * Returning undefined from [onCreateUnitView] indicates that the seat does
 * not need a widget.
 */
export declare abstract class AtomicLiveViewChangeAdapter {
    /**
     * Build the seat widget view when a unit is newly added; use
     * [onUpdateUnitView] to refresh its content later.
     *
     * Wrap a global @Builder function with `wrapBuilder(...)` and return it;
     * the view invokes it with the latest unit info on every rebuild.
     *
     * @param unitInfo - Live unit info.
     * @returns Wrapped builder for the custom widget, or undefined if the seat
     *           does not need a widget.
     */
    abstract onCreateUnitView(unitInfo: UnitInfo): WrappedBuilder<[UnitInfo]> | undefined;
    /**
     * Update an existing seat widget view when its business fields change.
     *
     * @param unitInfo - Latest live unit info.
     */
    abstract onUpdateUnitView(unitInfo: UnitInfo): void;
    /**
     * Video view frame change callback. Positions are expressed as ratios
     * relative to the parent container, in the range [0, 1].
     *
     * @param left - Ratio of the top-left point from the left edge.
     * @param top - Ratio of the top-left point from the top edge.
     * @param right - Ratio of the bottom-right point from the left edge.
     * @param bottom - Ratio of the bottom-right point from the top edge.
     */
    abstract onVideoViewFrameChanged(left: number, top: number, right: number, bottom: number): void;
    /**
     * Speaking volume change callback. Triggered by the SDK when the speaking
     * volume of a seat user changes, for both the play side (volume carried by
     * the stream) and the push side (local capture and
     * remote co-guest users). The callback is only delivered when the volume of
     * that user actually changes.
     *
     * @param unitInfo - Live unit info of the seat whose volume changed.
     * @param volume - Latest speaking volume of this seat user, in the range
     *                 0 to 100.
     */
    onVolumeChanged(unitInfo: UnitInfo, volume: number): void;
}
/**
 * Controller for the minimal atomic live view.
 *
 * ArkUI @Component structs are value types recreated across rebuilds, so a
 * stable handle is required to drive the view. This is the ArkTS-idiomatic
 * equivalent of calling `setViewChangeAdapter` directly on the view object
 * on iOS / Android.
 *
 * Create an instance via `AtomicLiveController.create`, pass it to an
 * `AtomicLiveView`, then drive it with `setViewChangeAdapter`.
 */
export declare abstract class AtomicLiveController {
    /**
     * Create controller instance.
     * @param viewType - Atomic live view type, play or push.
     * @returns Controller instance.
     */
    static create(viewType: AtomicLiveViewType): AtomicLiveController;
    /**
     * Set the view adapter used to overlay custom widget UIs on the view
     * (e.g., beauty panel, mute / flip control bar, co-guest seats, countdown,
     * etc.). The returned views are overlaid on the AtomicLiveView without
     * affecting the underlying rendering.
     * @param adapter - View adapter.
     */
    abstract setViewChangeAdapter(adapter: AtomicLiveViewChangeAdapter): void;
}
/**
 * Minimal atomic view container for pure playback / preview scenarios.
 *
 * `AtomicLiveView` is the render view itself: like `UIView` on iOS /
 * `FrameLayout` on Android / `AtomicLiveWidget` on Flutter, it is an object you
 * create, hand to `AtomicPlayer.setView` / `AtomicPusher.setView`, and put on
 * screen with the matching render component.
 *
 * It only renders video (mix-stream or per-seat) plus business widgets, and
 * does not provide seat / co-hosting / PK APIs. The live ID is bound by the
 * player / pusher, so it never needs to be set on the view.
 *
 * > **Note**: An ArkUI `@Component` struct cannot be instantiated outside
 * > `build()`, so the object handed to `setView` is this class. Putting it on
 * > screen additionally requires `AtomicLiveViewImpl` inside `build()`; that
 * > component is an SDK-internal export required by the ArkUI programming model,
 * > not a public API — it has no documentation page and no compatibility
 * > promise. Always pass the same `AtomicLiveView` instance to both.
 *
 * ## Usage
 * ```ts
 * const view = new AtomicLiveView(AtomicLiveController.create(AtomicLiveViewType.playView));
 * player.setView(view);                       // bind the render view
 * // in build(): AtomicLiveViewImpl({ view: view })
 * ```
 *
 * ## See Also
 * - AtomicPlayer
 * - AtomicPusher
 */
export declare class AtomicLiveView {
    /**
     * Stable handle driving the render component. Create it with
     * `AtomicLiveController.create` using `.playView` for `AtomicPlayer` and
     * `.pushView` for `AtomicPusher`.
     */
    controller: AtomicLiveController;
    /**
     * Create a render view driven by the given controller.
     *
     * @param controller - Controller created by `AtomicLiveController.create`.
     */
    constructor(controller: AtomicLiveController);
}
/**
 * Register the controller factory. Called by the internal implementation
 * module when it is loaded; business code never needs to call this.
 */
export declare function registerLiveControllerFactory(factory: (viewType: AtomicLiveViewType) => AtomicLiveController): void;
