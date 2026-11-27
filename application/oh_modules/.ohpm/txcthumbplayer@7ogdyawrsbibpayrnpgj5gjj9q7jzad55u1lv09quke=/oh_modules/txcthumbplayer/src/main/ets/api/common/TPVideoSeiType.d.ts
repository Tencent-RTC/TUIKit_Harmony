/*
 *  Copyright 1998-2024 Tencent Inc. All rights reserved.
 *  This file and proprietary source code may only be used
 *  and distributed under the Tencent Video Player Core Group Agreement.
 */

/**
 * Video Sei定义
 * 与内核tp2_sei_info.h中的定义保持一致，不要修改这里的枚举值
 *
 * @author karlyczhang
 * @date 2024/03/14
 */
export const enum TPVideoSeiType {
  /** unknown */
  UNKNOWN = -1,
  /** buffering_period */
  BUFFERING_PERIOD = 0,
  /** pic_timing */
  PIC_TIMING = 1,
  /** pan_scan_rect */
  PAN_SCAN_RECT = 2,
  /** filler_payload */
  FILLER_PAYLOAD = 3,
  /** user_data_registered_itu_t_t35 */
  USER_DATA_REGISTERED_ITU_T_T35 = 4,
  /** user_data_unregistered */
  USER_DATA_UNREGISTERED = 5,
  /** recovery_point */
  RECOVERY_POINT = 6,
  /** scene_info */
  SCENE_INFO = 9,
  /** full_frame_snapshot */
  FULL_FRAME_SNAPSHOT = 15,
  /** progressive_refinement_segment_start */
  PROGRESSIVE_REFINEMENT_SEGMENT_START = 16,
  /** progressive_refinement_segment_end */
  PROGRESSIVE_REFINEMENT_SEGMENT_END = 17,
  /** film_grain_characteristics */
  FILM_GRAIN_CHARACTERISTICS = 19,
  /** post_filter_hint */
  POST_FILTER_HINT = 22,
  /** tone_mapping_info */
  TONE_MAPPING_INFO = 23,
  /** frame_packing_arrangement */
  FRAME_PACKING = 45,
  /** display_orientation */
  DISPLAY_ORIENTATION = 47,
  /** green_metadata */
  GREEN_METADATA = 56,
  /** structure_of_pictures_info */
  SOP_INFO = 128,
  /** active_parameter_sets */
  ACTIVE_PARAMETER_SETS = 129,
  /** decoding_unit_info */
  DECODING_UNIT_INFO = 130,
  /** temporal_sub_layer_zero_idx */
  TEMPORAL_LEVEL0_INDEX = 131,
  /** decoded_picture_hash */
  DECODED_PICTURE_HASH = 132,
  /** scalable_nesting */
  SCALABLE_NESTING = 133,
  /** region_refresh_info */
  REGION_REFRESH_INFO = 134,
  /** mastering_display_colour_volume */
  MASTERING_COLOUR_VOLUME = 137,
  /** content_light_level_info */
  CONTENT_LIGHT_LEVEL_INFO = 144,
  /** alternative_transfer_characteristics */
  ALTERNATIVE_TRANSFER_CHARACTERISTICS = 147,
}
