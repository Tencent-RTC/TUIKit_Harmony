/**
 * Copyright (c) 2025 Tencent. All rights reserved.
 * Module:   CallCoreView @ AtomicXCore
 * Function: Call video view component supporting Float/Grid/Pip layout templates.
 */
import { CallLayoutTemplate, VolumeLevel } from '../../../impl/view/call/CallViewConstants';
import { NetworkQuality } from '../../device/DeviceStore';
export { CallLayoutTemplate, VolumeLevel } from '../../../impl/view/call/CallViewConstants';
/**
 * Controller for CallCoreView, used to control layout and configure resources.
 *
 * @Observed enables ArkUI to track property changes when this object is referenced in child components.
 */
@Observed
export declare class CallCoreController {
    private logger;
    currentLayoutTemplate: CallLayoutTemplate;
    waitingAnimationSource: ResourceStr;
    volumeLevelIconSources: Map<VolumeLevel, ResourceStr>;
    networkQualityIconSources: Map<NetworkQuality, ResourceStr>;
    defaultAvatarSource: ResourceStr;
    onTemplateChanged: ((template: CallLayoutTemplate) => void) | null;
    /**
     * Switch the layout mode of the call interface.
     *
     * @param template Target layout template.
     */
    setLayoutTemplate(template: CallLayoutTemplate): void;
    /**
     * Configure call waiting animation.
     *
     * @param source Image source. Accepts `$rawfile(...)`, `$r(...)`, network URL,
     *               local file path (`file:///...`) or Base64 data URI.
     */
    setWaitingAnimation(source: ResourceStr): void;
    /**
     * Customize volume level icons.
     *
     * @param icons Mapping between volume levels and icon sources. Each value
     *              accepts `$rawfile(...)`, `$r(...)`, network URL, local file
     *              path (`file:///...`) or Base64 data URI.
     */
    setVolumeLevelIcons(icons: Map<VolumeLevel, ResourceStr>): void;
    /**
     * Customize network quality icons.
     *
     * @param icons Mapping between network quality states and icon sources.
     *              Each value accepts `$rawfile(...)`, `$r(...)`, network URL,
     *              local file path (`file:///...`) or Base64 data URI.
     */
    setNetworkQualityIcons(icons: Map<NetworkQuality, ResourceStr>): void;
    /**
     * Set the default placeholder avatar used when a participant has no specific avatar.
     *
     * @param source Image source. Accepts `$rawfile(...)`, `$r(...)`, network URL,
     *               local file path (`file:///...`) or Base64 data URI.
     */
    setDefaultAvatar(source: ResourceStr): void;
}
/**
 * Call video view component.
 */
@Component
export declare struct CallCoreView {
    controller: CallCoreController;
    @State
    private callState;
    @State
    private selfInfo;
    @State
    private activeCall;
    @State
    private deviceState;
    build(): void;
}
