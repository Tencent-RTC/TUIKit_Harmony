import { TUICallMediaType } from '@tencentcloud/rtcroomengine'
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import Logger from './Logger'

const TAG: string = "Permission"
const context = getContext() as common.UIAbilityContext;
const MicrophonePermission = 'ohos.permission.MICROPHONE'
const CameraPermission = 'ohos.permission.CAMERA'

export interface PermissionGrantStatusResult {
  permissionsAll: Permissions[];
  permissionsDenied: Permissions[];
  grantStatus: boolean;
}

let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()

export default class Permission {
  static async requestPermission(mediaType: TUICallMediaType): Promise<PermissionGrantStatusResult> {
    Logger.error(TAG, `requestPermission: ${TUICallMediaType[mediaType]}`)
    if (mediaType === TUICallMediaType.Audio) {
      return await Permission.getMicrophonePermission();
    }

    const microphonePermission = await Permission.getMicrophonePermission();
    if (!microphonePermission.grantStatus) {
      return microphonePermission;
    }

    return await Permission.getCameraPermission();
  }

  private static async reqPermissionsFromUser(permissionsArray: Array<Permissions>): Promise<PermissionGrantStatusResult> {
    return atManager.requestPermissionsFromUser(context, permissionsArray).then((data) => {
      Logger.info(TAG, 'reqPermissionsFromUser:' + JSON.stringify(data));
      let grantStatus: Array<number> = data.authResults;
      let permissions: Array<string> = data.permissions;

      let permissionsDenied: Array<Permissions> = new Array()
      let dialogShownResults: Array<boolean> | undefined = data.dialogShownResults
      permissions.forEach((value, index) => {
        let dialogShown = dialogShownResults != undefined ? dialogShownResults[index] : false
        //0:表示授权,-1:表示不授权,2:表示请求无效。
        if (grantStatus[index] === -1 && !dialogShown) {
          permissionsDenied.push(permissionsArray[index])
        } else if (grantStatus[index] === 2) {
          throw new Error("invalid request")
        }
      })
      let result: PermissionGrantStatusResult = {
        "permissionsAll": permissionsArray,
        "permissionsDenied": permissionsDenied,
        "grantStatus": permissionsDenied.length <= 0
      }
      return result
    }).catch((err: BusinessError) => {
      Logger.info(TAG, `reqPermissionArrayFromUser err:${err?.message},${JSON.stringify(permissionsArray)}`);
      let result: PermissionGrantStatusResult = {
        "permissionsAll": permissionsArray,
        "permissionsDenied": permissionsArray,
        "grantStatus": false
      }
      return result
    });
  }

  private static async requestPermissionsOnSetting(permissionsArray: Array<Permissions>):
    Promise<PermissionGrantStatusResult> {
    let permissionsDenied: Array<Permissions> = new Array()
    Logger.info(TAG, 'requestPermissionOnSetting permissionArray:' + JSON.stringify(permissionsArray));

    return atManager.requestPermissionOnSetting(context, permissionsArray)
      .then((data: Array<abilityAccessCtrl.GrantStatus>) => {
        Logger.info(TAG, 'requestPermissionOnSetting data:' + JSON.stringify(data));
        permissionsArray.forEach((value, index) => {
          Logger.info(TAG,
            `requestPermissionOnSetting [${value},${data[index] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED ?
              "Denied" : "Granted"}]`);
          if (data[index] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
            permissionsDenied.push(permissionsArray[index])
          }
        })
        let result: PermissionGrantStatusResult = {
          "permissionsAll": permissionsArray,
          "permissionsDenied": permissionsDenied,
          "grantStatus": permissionsDenied.length <= 0
        }
        return result
      }).catch((err: BusinessError) => {
        Logger.info(TAG, `reqPermissionArrayFromUser err:${err?.message},${JSON.stringify(permissionsArray)}`);
        let result: PermissionGrantStatusResult = {
          "permissionsAll": permissionsArray,
          "permissionsDenied": permissionsArray,
          "grantStatus": false
        }
        return result
      });
  }

  private static async getMicrophonePermission(): Promise<PermissionGrantStatusResult> {
    let result = await Permission.reqPermissionsFromUser([MicrophonePermission])
    if (!result.grantStatus) {
      result = await Permission.requestPermissionsOnSetting([MicrophonePermission])
    }
    return result
  }

  private static async getCameraPermission(): Promise<PermissionGrantStatusResult> {
    let result = await Permission.reqPermissionsFromUser([CameraPermission])
    if (!result.grantStatus) {
      result = await Permission.requestPermissionsOnSetting([CameraPermission])
    }
    return result
  }
}

