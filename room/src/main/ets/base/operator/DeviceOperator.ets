import { DeviceStore, RoomParticipantStore, ErrorInfo } from '@tencentcloud/atomicxcore';
import { Toast } from '@tencentcloud/atomicx';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { ErrorLocalized } from '../error/ErrorLocalized';

const ERROR_CODE_OPEN_CAMERA_NEED_PERMISSION_FROM_ADMIN = -2371;
const ERROR_CODE_OPEN_MICROPHONE_NEED_PERMISSION_FROM_ADMIN = -2361;

export enum DeviceOperatorType {
  microphone,
  camera,
}

export class DeviceOperator {
  static async openCamera(uiContext: UIContext): Promise<void> {
    const deviceStore = DeviceStore.shared();
    const context = uiContext.getHostContext();
    if (!context) {
      return;
    }

    const hasPermission = await DeviceOperator.requestPermission(context, DeviceOperatorType.camera);
    if (!hasPermission) {
      Toast.error($r('app.string.roomkit_err_n1101_camera_no_permission'), uiContext);
      return;
    }

    try {
      await deviceStore.openLocalCamera(deviceStore.state.isFrontCamera);
    } catch (error) {
      const errorInfo = error as ErrorInfo;
      const errorMessage = ErrorLocalized.convertToErrorMessage(errorInfo.code, errorInfo.message, uiContext);
      if (errorInfo.code === ERROR_CODE_OPEN_CAMERA_NEED_PERMISSION_FROM_ADMIN) {
        Toast.warning(errorMessage, uiContext);
      } else {
        Toast.error(errorMessage, uiContext);
      }
    }
  }

  static closeCamera(): void {
    DeviceStore.shared().closeLocalCamera();
  }

  static async unmuteMicrophone(uiContext: UIContext, participantStore: RoomParticipantStore): Promise<void> {
    const deviceStore = DeviceStore.shared();
    const context = uiContext.getHostContext();
    if (!context) {
      return;
    }

    const hasPermission = await DeviceOperator.requestPermission(context, DeviceOperatorType.microphone);
    if (!hasPermission) {
      Toast.error($r('app.string.roomkit_err_n1105_mic_no_permission'), uiContext);
      return;
    }

    try {
      await deviceStore.openLocalMicrophone();
    } catch (error) {
      const errorInfo = error as ErrorInfo;
      const errorMessage = ErrorLocalized.convertToErrorMessage(errorInfo.code, errorInfo.message, uiContext);
      if (errorInfo.code === ERROR_CODE_OPEN_MICROPHONE_NEED_PERMISSION_FROM_ADMIN) {
        Toast.warning(errorMessage, uiContext);
      } else {
        Toast.error(errorMessage, uiContext);
      }
      return;
    }

    try {
      await participantStore.unmuteMicrophone();
    } catch (error) {
      const errorInfo = error as ErrorInfo;
      const errorMessage = ErrorLocalized.convertToErrorMessage(errorInfo.code, errorInfo.message, uiContext);
      if (errorInfo.code === ERROR_CODE_OPEN_MICROPHONE_NEED_PERMISSION_FROM_ADMIN) {
        Toast.warning(errorMessage, uiContext);
      } else {
        Toast.error(errorMessage, uiContext);
      }
    }
  }

  static muteMicrophone(participantStore: RoomParticipantStore): void {
    participantStore.muteMicrophone();
  }

  static async requestPermission(context: Context, type: DeviceOperatorType): Promise<boolean> {
    const permission: Permissions = type === DeviceOperatorType.camera
      ? 'ohos.permission.CAMERA'
      : 'ohos.permission.MICROPHONE';

    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const tokenId = bundleInfo.appInfo.accessTokenId;
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = await atManager.checkAccessToken(tokenId, permission);
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
    } catch (error) {
      console.error(`DeviceOperator checkAccessToken error: ${JSON.stringify(error)}`);
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, [permission]);
      return result.authResults[0] === 0;
    } catch (error) {
      console.error(`DeviceOperator requestPermission error: ${JSON.stringify(error)}`);
      return false;
    }
  }
}
