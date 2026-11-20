import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit'

export class RoomDevicePermission {
  private static pending?: (granted: boolean) => void
  private static microphonePermissionListeners: Set<() => void> = new Set()
  private static cameraPermissionListeners: Set<() => void> = new Set()

  static async requestMicrophonePermission(context: common.UIAbilityContext): Promise<boolean> {
    const granted = await RoomDevicePermission.request(context, 'ohos.permission.MICROPHONE')
    if (granted) {
      RoomDevicePermission.microphonePermissionListeners.forEach((listener: () => void) => listener())
    }
    return granted
  }

  static async requestCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
    const granted = await RoomDevicePermission.request(context, 'ohos.permission.CAMERA')
    if (granted) {
      RoomDevicePermission.cameraPermissionListeners.forEach((listener: () => void) => listener())
    }
    return granted
  }

  static addMicrophonePermissionListener(listener: () => void): void {
    RoomDevicePermission.microphonePermissionListeners.add(listener)
  }

  static removeMicrophonePermissionListener(listener: () => void): void {
    RoomDevicePermission.microphonePermissionListeners.delete(listener)
  }

  static addCameraPermissionListener(listener: () => void): void {
    RoomDevicePermission.cameraPermissionListeners.add(listener)
  }

  static removeCameraPermissionListener(listener: () => void): void {
    RoomDevicePermission.cameraPermissionListeners.delete(listener)
  }

  static async hasMicrophonePermission(): Promise<boolean> {
    return RoomDevicePermission.hasPermission('ohos.permission.MICROPHONE')
  }

  static async hasCameraPermission(): Promise<boolean> {
    return RoomDevicePermission.hasPermission('ohos.permission.CAMERA')
  }

  private static async hasPermission(permission: Permissions): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const status = await abilityAccessCtrl.createAtManager().checkAccessToken(
        bundleInfo.appInfo.accessTokenId, permission)
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (error) {
      return false
    }
  }

  private static async request(context: common.UIAbilityContext, permission: Permissions): Promise<boolean> {
    if (await RoomDevicePermission.hasPermission(permission)) {
      return true
    }
    RoomDevicePermission.pending?.(false)
    return new Promise<boolean>((resolve: (granted: boolean) => void) => {
      RoomDevicePermission.pending = resolve
      abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [permission]).then((result) => {
        const granted = result.authResults.length > 0 && result.authResults.every((status: number) => status === 0)
        RoomDevicePermission.finish(resolve, granted)
      }).catch(() => {
        RoomDevicePermission.finish(resolve, false)
      })
    })
  }

  private static finish(resolve: (granted: boolean) => void, granted: boolean): void {
    if (RoomDevicePermission.pending === resolve) {
      RoomDevicePermission.pending = undefined
    }
    resolve(granted)
  }
}
