import { RoomToast } from '../toast/RoomToast'
import { RoomResources } from '../util/RoomResources'

export enum ErrorLevel {
  SILENT,
  TOAST,
}

export enum ErrorRule {
  FALLBACK = 0,
  UNKNOWN = -1,
  TOO_FREQUENT = -2,
  INVALID_PARAMETER = -1001,
  NOT_LOGGED_IN = -1002,
  SERVER_ERROR = 100001,
  SERVER_INVALID_PARAMETER = 100002,
  IGNORED = 100100,
  UNCLASSIFIED = 100006,
  PACKAGE_ERROR = 100007,
  OPERATION_TOO_FREQUENT = 100012,
  ILLEGAL_ROOM_ID = -2105,
  ILLEGAL_ROOM_NAME = -2107,
  ROOM_EXISTS = 100003,
  ROOM_NOT_FOUND = 100004,
  ROOM_FULL = 100008,
  ROOM_ALREADY_EXISTS = 100011,
  SENSITIVE_WORD = 100026,
  PASSWORD_REQUIRED = 100018,
  WRONG_PASSWORD = 100019,
  CAMERA_START_FAILED = -1100,
  CAMERA_NO_PERMISSION = -1101,
  CAMERA_OCCUPIED = -1102,
  CAMERA_NO_DEVICE = -1103,
  MIC_START_FAILED = -1104,
  MIC_NO_PERMISSION = -1105,
  MIC_OCCUPIED = -1106,
  MIC_NO_DEVICE = -1107,
  SCREEN_SHARE_SOURCE_UNAVAILABLE = -1108,
  SCREEN_SHARE_FAILED = -1109,
  AUDIO_INTERRUPTED = -1110,
  ALL_MIC_DISABLED = -2361,
  ALL_CAMERA_DISABLED = -2371,
  SCREEN_SHARE_OWNER_ADMIN_ONLY = -2373,
  SCREEN_SHARE_UNSUPPORTED = 12061,
  ADMIN_LIMIT = 100020,
  CHAT_MUTED_ALL = -2380,
  CHAT_MUTED = 100017,
  PACKAGE_UNAVAILABLE = 101072,
}

export class ErrorLocalized {
  private static rule(code: number): ErrorRule {
    switch (code) {
      case -1: return ErrorRule.UNKNOWN
      case -2: return ErrorRule.TOO_FREQUENT
      case -1001: return ErrorRule.INVALID_PARAMETER
      case -1002: return ErrorRule.NOT_LOGGED_IN
      case 100001: return ErrorRule.SERVER_ERROR
      case 100002: return ErrorRule.SERVER_INVALID_PARAMETER
      case 100100: return ErrorRule.IGNORED
      case 100006: return ErrorRule.UNCLASSIFIED
      case 100007: return ErrorRule.PACKAGE_ERROR
      case 100012: return ErrorRule.OPERATION_TOO_FREQUENT
      case -2105: return ErrorRule.ILLEGAL_ROOM_ID
      case -2107: return ErrorRule.ILLEGAL_ROOM_NAME
      case 100003: return ErrorRule.ROOM_EXISTS
      case 100004: return ErrorRule.ROOM_NOT_FOUND
      case 100008: return ErrorRule.ROOM_FULL
      case 100011: return ErrorRule.ROOM_ALREADY_EXISTS
      case 100026: return ErrorRule.SENSITIVE_WORD
      case 100018: return ErrorRule.PASSWORD_REQUIRED
      case 100019: return ErrorRule.WRONG_PASSWORD
      case -1100: return ErrorRule.CAMERA_START_FAILED
      case -1101: return ErrorRule.CAMERA_NO_PERMISSION
      case -1102: return ErrorRule.CAMERA_OCCUPIED
      case -1103: return ErrorRule.CAMERA_NO_DEVICE
      case -1104: return ErrorRule.MIC_START_FAILED
      case -1105: return ErrorRule.MIC_NO_PERMISSION
      case -1106: return ErrorRule.MIC_OCCUPIED
      case -1107: return ErrorRule.MIC_NO_DEVICE
      case -1108: return ErrorRule.SCREEN_SHARE_SOURCE_UNAVAILABLE
      case -1109: return ErrorRule.SCREEN_SHARE_FAILED
      case -1110: return ErrorRule.AUDIO_INTERRUPTED
      case -2361: return ErrorRule.ALL_MIC_DISABLED
      case -2371: return ErrorRule.ALL_CAMERA_DISABLED
      case -2373: return ErrorRule.SCREEN_SHARE_OWNER_ADMIN_ONLY
      case 12061: return ErrorRule.SCREEN_SHARE_UNSUPPORTED
      case 100020: return ErrorRule.ADMIN_LIMIT
      case -2380: return ErrorRule.CHAT_MUTED_ALL
      case 100017: return ErrorRule.CHAT_MUTED
      case 101072: return ErrorRule.PACKAGE_UNAVAILABLE
      default: return ErrorRule.FALLBACK
    }
  }

  private static level(rule: ErrorRule): ErrorLevel {
    return rule === ErrorRule.IGNORED ? ErrorLevel.SILENT : ErrorLevel.TOAST
  }

  private static messageKey(rule: ErrorRule): string {
    switch (rule) {
      case ErrorRule.TOO_FREQUENT:
      case ErrorRule.OPERATION_TOO_FREQUENT:
        return 'roomkit_error_too_frequent'
      case ErrorRule.INVALID_PARAMETER:
      case ErrorRule.SERVER_INVALID_PARAMETER:
        return 'roomkit_error_invalid_parameter'
      case ErrorRule.NOT_LOGGED_IN: return 'roomkit_error_not_logged_in'
      case ErrorRule.SERVER_ERROR: return 'roomkit_error_server'
      case ErrorRule.PACKAGE_ERROR:
      case ErrorRule.PACKAGE_UNAVAILABLE:
        return 'roomkit_error_package'
      case ErrorRule.ILLEGAL_ROOM_ID: return 'roomkit_entry_failure_illegal_room_id'
      case ErrorRule.ILLEGAL_ROOM_NAME: return 'roomkit_entry_failure_illegal_room_name'
      case ErrorRule.ROOM_EXISTS:
      case ErrorRule.ROOM_ALREADY_EXISTS:
        return 'roomkit_entry_failure_room_exists'
      case ErrorRule.ROOM_NOT_FOUND: return 'roomkit_entry_failure_room_not_found'
      case ErrorRule.ROOM_FULL: return 'roomkit_entry_failure_room_full'
      case ErrorRule.SENSITIVE_WORD: return 'roomkit_entry_failure_sensitive_word'
      case ErrorRule.PASSWORD_REQUIRED: return 'roomkit_entry_failure_password_required'
      case ErrorRule.WRONG_PASSWORD: return 'roomkit_entry_failure_wrong_password'
      case ErrorRule.CAMERA_START_FAILED: return 'roomkit_device_camera_start_failed'
      case ErrorRule.CAMERA_NO_PERMISSION: return 'roomkit_device_camera_no_permission'
      case ErrorRule.CAMERA_OCCUPIED: return 'roomkit_device_camera_occupied'
      case ErrorRule.CAMERA_NO_DEVICE: return 'roomkit_device_camera_no_device'
      case ErrorRule.MIC_START_FAILED: return 'roomkit_device_mic_start_failed'
      case ErrorRule.MIC_NO_PERMISSION: return 'roomkit_device_mic_no_permission'
      case ErrorRule.MIC_OCCUPIED: return 'roomkit_device_mic_occupied'
      case ErrorRule.MIC_NO_DEVICE: return 'roomkit_device_mic_no_device'
      case ErrorRule.SCREEN_SHARE_SOURCE_UNAVAILABLE:
        return 'roomkit_screen_share_failure_source_unavailable'
      case ErrorRule.SCREEN_SHARE_FAILED: return 'roomkit_screen_share_failure_failed'
      case ErrorRule.AUDIO_INTERRUPTED: return 'roomkit_device_audio_interrupted'
      case ErrorRule.ALL_MIC_DISABLED: return 'roomkit_device_all_mic_disabled'
      case ErrorRule.ALL_CAMERA_DISABLED: return 'roomkit_device_all_cam_disabled'
      case ErrorRule.SCREEN_SHARE_OWNER_ADMIN_ONLY:
        return 'roomkit_screen_share_failure_owner_admin_only'
      case ErrorRule.SCREEN_SHARE_UNSUPPORTED: return 'roomkit_screen_share_failure_unsupported'
      case ErrorRule.ADMIN_LIMIT: return 'roomkit_participants_admin_limit'
      case ErrorRule.CHAT_MUTED_ALL: return 'roomkit_chat_muted_all'
      case ErrorRule.CHAT_MUTED: return 'roomkit_chat_muted'
      default: return 'roomkit_error_default'
    }
  }

  static showError(error: Error): void {
    const code = Number(Reflect.get(error, 'code') ?? -1)
    const rule = ErrorLocalized.rule(code)
    if (ErrorLocalized.level(rule) === ErrorLevel.SILENT) {
      return
    }
    RoomToast.show(RoomResources.string(ErrorLocalized.messageKey(rule)))
  }
}
