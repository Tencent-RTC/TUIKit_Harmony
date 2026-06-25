// CAMERA / MICROPHONE runtime permission check + request, with permanent-denial
// fallback dialog guiding the user to system Settings.

import { abilityAccessCtrl, common, bundleManager, Permissions } from '@kit.AbilityKit';
import { CallStore, CallMediaType, CallParticipantStatus } from '@tencentcloud/atomicxcore';
import { promptAction } from '@kit.ArkUI';
import { Logger } from './Logger';
import { TUICallKitLocalize } from '../Localized';
import { CallEndedFlag } from '../../state/CallEndedFlag';

const CAMERA_PERM: Permissions = 'ohos.permission.CAMERA';
const MIC_PERM: Permissions = 'ohos.permission.MICROPHONE';

enum DeniedKind {
  audio,
  video,
}

export class Permission {
  /** audio → mic; video → mic + camera. Returns true when all required perms are granted. */
  static async hasPermission(
    context: common.UIAbilityContext,
    mediaType: CallMediaType,
  ): Promise<boolean> {
    const required: Permissions[] = mediaType === CallMediaType.video
      ? [MIC_PERM, CAMERA_PERM]
      : [MIC_PERM];

    const atManager = abilityAccessCtrl.createAtManager();
    let tokenId: number = 0;
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      );
      tokenId = bundleInfo.appInfo.accessTokenId;
    } catch (e) {
      Logger.error('Permission: getBundleInfoForSelf failed', e);
      return false;
    }

    let allGranted = true;
    for (const p of required) {
      const result = await atManager.checkAccessToken(tokenId, p);
      if (result !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        allGranted = false;
        break;
      }
    }
    if (allGranted) {
      return true;
    }

    try {
      const result = await atManager.requestPermissionsFromUser(context, required);
      const allOk = result.authResults.every((v: number): boolean => v === 0);
      if (allOk) {
        return true;
      }
      // Permanent denial → settings-guidance dialog.
      // Prefer audio over video when both are denied (matches iOS behavior).
      const deniedKind = Permission.resolveDeniedKind(required, result.authResults);
      void Permission.showSettingsAlert(context, deniedKind);
      return false;
    } catch (e) {
      Logger.error('Permission: requestPermissionsFromUser failed', e);
      return false;
    }
  }

  static async requestCameraInCall(context: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    let tokenId: number = 0;
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      );
      tokenId = bundleInfo.appInfo.accessTokenId;
    } catch (e) {
      Logger.error('Permission: getBundleInfoForSelf failed', e);
      return false;
    }

    const checked = await atManager.checkAccessToken(tokenId, CAMERA_PERM);
    if (checked === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return true;
    }

    try {
      const result = await atManager.requestPermissionsFromUser(context, [CAMERA_PERM]);
      return result.authResults.length > 0 && result.authResults[0] === 0;
    } catch (e) {
      Logger.error('Permission: requestPermissionsFromUser (camera) failed', e);
      return false;
    }
  }

  private static resolveDeniedKind(
    requested: Permissions[],
    authResults: number[],
  ): DeniedKind {
    for (let i = 0; i < requested.length; i++) {
      if (requested[i] === MIC_PERM && authResults[i] !== 0) {
        return DeniedKind.audio;
      }
    }
    for (let i = 0; i < requested.length; i++) {
      if (requested[i] === CAMERA_PERM && authResults[i] !== 0) {
        return DeniedKind.video;
      }
    }
    return DeniedKind.audio;
  }

  private static async showSettingsAlert(
    context: common.UIAbilityContext,
    deniedKind: DeniedKind,
  ): Promise<void> {
    const isVideo = deniedKind === DeniedKind.video;
    const titleKey = isVideo
      ? 'TUICallKit.FailedToGetCameraPermission.Title'
      : 'TUICallKit.FailedToGetMicrophonePermission.Title';
    const tipsKey = isVideo
      ? 'TUICallKit.FailedToGetCameraPermission.Tips'
      : 'TUICallKit.FailedToGetMicrophonePermission.Tips';
    const laterKey = isVideo
      ? 'TUICallKit.FailedToGetCameraPermission.Later'
      : 'TUICallKit.FailedToGetMicrophonePermission.Later';
    const enableKey = isVideo
      ? 'TUICallKit.FailedToGetCameraPermission.Enable'
      : 'TUICallKit.FailedToGetMicrophonePermission.Enable';

    const appName = await Permission.appDisplayName(context);
    const tipsTemplate = TUICallKitLocalize(tipsKey);
    const message = tipsTemplate.replace(/%s|%@/g, appName);

    promptAction.showDialog({
      title: TUICallKitLocalize(titleKey),
      message: message,
      buttons: [
        { text: TUICallKitLocalize(laterKey), color: '#666666' },
        { text: TUICallKitLocalize(enableKey), color: '#006EFF' },
      ],
    })
      .then((result: promptAction.ShowDialogSuccessResponse): void => {
        Permission.endActiveCallOnDenied();
        if (result.index === 1) {
          Permission.openAppSettings(context);
        }
      })
      .catch((e: Object): void => {
        Logger.warn('Permission: showDialog failed', e);
        Permission.endActiveCallOnDenied();
      });
  }

  private static endActiveCallOnDenied(): void {
    const status = CallStore.shared().state.selfInfo.status;
    if (status === CallParticipantStatus.none) {
      return;
    }
    CallEndedFlag().markSelfEnded();
    if (status === CallParticipantStatus.waiting) {
      CallStore.shared().reject().catch((e: Object): void => {
        Logger.warn('Permission: reject after denial failed', e);
      });
    } else {
      CallStore.shared().hangup().catch((e: Object): void => {
        Logger.warn('Permission: hangup after denial failed', e);
      });
    }
  }

  private static async appDisplayName(context: common.UIAbilityContext): Promise<string> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      );
      const labelId = bundleInfo.appInfo.labelId;
      if (labelId && labelId !== 0) {
        const name = context.resourceManager.getStringSync(labelId);
        if (name && name.length > 0) {
          return name;
        }
      }
      const rawLabel = bundleInfo.appInfo.label;
      if (rawLabel && rawLabel.length > 0 && !rawLabel.startsWith('$')) {
        return rawLabel;
      }
    } catch (e) {
      Logger.warn('Permission: read app label failed', e);
    }
    return 'App';
  }

  private static openAppSettings(context: common.UIAbilityContext): void {
    try {
      void context.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: context.abilityInfo.bundleName,
        },
      });
    } catch (e) {
      Logger.warn('Permission: open settings failed', e);
    }
  }
}
