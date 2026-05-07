export class ErrorLocalized {
  static convertToErrorMessage(code: number | undefined, message: string | undefined, uiContext?: UIContext): string {
    const resourceName = ERROR_CODE_RESOURCE_MAP.get(code ?? 0);
    if (resourceName && uiContext) {
      try {
        return uiContext.getHostContext()?.resourceManager.getStringByNameSync(resourceName) ?? resourceName;
      } catch (_e) {
        return resourceName;
      }
    }
    if (resourceName) {
      return resourceName;
    }
    return `code: ${code ?? ''}, message: ${message ?? ''}`;
  }
}

const ERROR_CODE_RESOURCE_MAP: Map<number, string> = new Map([
  [0, 'roomkit_err_0_success'],
  [-2, 'roomkit_err_n2_request_rate_limited'],
  [-3, 'roomkit_err_n3_repeat_operation'],
  [-4, 'roomkit_err_n4_roomID_not_match'],
  [-1000, 'roomkit_err_n1000_sdk_appid_not_found'],
  [-1001, 'roomkit_err_n1001_invalid_parameter'],
  [-1002, 'roomkit_err_n1002_not_logged_in'],
  [-1003, 'roomkit_err_n1003_permission_denied'],
  [-1004, 'roomkit_err_n1004_package_required'],
  [-1100, 'roomkit_err_n1100_camera_open_failed'],
  [-1101, 'roomkit_err_n1101_camera_no_permission'],
  [-1102, 'roomkit_err_n1102_camera_occupied'],
  [-1103, 'roomkit_err_n1103_camera_not_found'],
  [-1104, 'roomkit_err_n1104_mic_open_failed'],
  [-1105, 'roomkit_err_n1105_mic_no_permission'],
  [-1106, 'roomkit_err_n1106_mic_occupied'],
  [-1107, 'roomkit_err_n1107_mic_not_found'],
  [-1108, 'roomkit_err_n1108_screen_share_get_source_failed'],
  [-1109, 'roomkit_err_n1109_screen_share_start_failed'],
  [-2101, 'roomkit_err_n2101_not_in_room'],
  [-2102, 'roomkit_err_n2102_owner_cannot_leave'],
  [-2103, 'roomkit_err_n2103_unsupported_in_room_type'],
  [-2105, 'roomkit_err_n2105_invalid_room_id'],
  [-2107, 'roomkit_err_n2107_invalid_room_name'],
  [-2108, 'roomkit_err_n2108_user_already_in_other_room'],
  [-2200, 'roomkit_err_n2200_user_not_exist'],
  [-2300, 'roomkit_err_n2300_need_owner_permission'],
  [-2301, 'roomkit_err_n2301_need_admin_permission'],
  [-2310, 'roomkit_err_n2310_signal_no_permission'],
  [-2311, 'roomkit_err_n2311_signal_invalid_request_id'],
  [-2312, 'roomkit_err_n2312_signal_request_duplicated'],
  [-2340, 'roomkit_err_n2340_seat_count_limit_exceeded'],
  [-2344, 'roomkit_err_n2344_seat_not_exist'],
  [-2360, 'roomkit_err_n2360_seat_audio_locked'],
  [-2361, 'roomkit_tip_all_muted_cannot_unmute'],
  [-2370, 'roomkit_err_n2370_seat_video_locked'],
  [-2371, 'roomkit_tip_all_video_off_cannot_start'],
  [-2372, 'roomkit_err_n2372_screen_share_seat_locked'],
  [-2373, 'roomkit_err_n2373_screen_share_need_permission'],
  [-2380, 'roomkit_err_n2380_all_members_muted'],
  [-2381, 'roomkit_err_10017_muted_in_room'],
  [-4001, 'roomkit_err_n4001_room_not_support_preload'],
  [7002, 'roomkit_err_7002_invalid_user_id'],
  [10017, 'roomkit_err_10017_muted_in_room'],
  [100001, 'roomkit_err_100001_server_internal_error'],
  [100002, 'roomkit_err_100002_server_invalid_parameter'],
  [100003, 'roomkit_err_100003_room_id_already_exists'],
  [100004, 'roomkit_err_100004_room_not_exist'],
  [100005, 'roomkit_err_100005_not_room_member'],
  [100006, 'roomkit_err_100006_operation_not_allowed'],
  [100007, 'roomkit_err_100007_no_payment_info'],
  [100008, 'roomkit_err_100008_room_is_full'],
  [100009, 'roomkit_err_100009_room_tag_limit_exceeded'],
  [100010, 'roomkit_err_100010_room_id_reusable_by_owner'],
  [100011, 'roomkit_err_100011_room_id_occupied_by_im'],
  [100012, 'roomkit_err_100012_create_room_frequency_limit'],
  [100013, 'roomkit_err_100013_payment_limit_exceeded'],
  [100015, 'roomkit_err_100015_invalid_room_type'],
  [100016, 'roomkit_err_100016_member_already_banned'],
  [100017, 'roomkit_err_100017_member_already_muted'],
  [100018, 'roomkit_err_100018_room_password_required'],
  [100019, 'roomkit_err_100019_room_password_incorrect'],
  [100020, 'roomkit_err_100020_admin_limit_exceeded'],
  [100102, 'roomkit_err_100102_signal_request_conflict'],
  [100200, 'roomkit_err_100200_seat_is_locked'],
  [100201, 'roomkit_err_100201_seat_is_occupied'],
  [100202, 'roomkit_err_100202_already_in_seat_queue'],
  [100203, 'roomkit_err_100203_already_on_seat'],
  [100204, 'roomkit_err_100204_not_in_seat_queue'],
  [100205, 'roomkit_err_100205_all_seats_are_full'],
  [100206, 'roomkit_err_100206_not_on_seat'],
  [100210, 'roomkit_err_100210_user_already_on_seat'],
  [100211, 'roomkit_err_100211_seat_not_supported'],
  [100251, 'roomkit_err_100251_seat_list_is_empty'],
  [100500, 'roomkit_err_100500_room_metadata_key_limit'],
  [100501, 'roomkit_err_100501_room_metadata_value_limit'],
  [100502, 'roomkit_err_100502_room_metadata_total_limit'],
  [100503, 'roomkit_err_100503_room_metadata_no_valid_keys'],
  [100504, 'roomkit_err_100504_room_metadata_key_size_limit'],
]);
