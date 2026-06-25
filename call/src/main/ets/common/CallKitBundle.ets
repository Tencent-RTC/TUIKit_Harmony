// Centralised symbolic-name → $r('app.media.xxx') mapping. ArkTS does not
// allow dynamic `$r("app.media." + name)` so callers go through `imageMap`.

export class CallKitBundle {
  static image(name: string): Resource {
    return CallKitBundle.imageMap(name);
  }

  static imageMap(name: string): Resource {
    switch (name) {
      case 'icon_hangup': return $r('app.media.icon_hangup');
      case 'icon_dialing': return $r('app.media.icon_dialing');
      case 'icon_video_dialing': return $r('app.media.icon_video_dialing');
      case 'icon_mute': return $r('app.media.icon_mute');
      case 'icon_mute_on': return $r('app.media.icon_mute_on');
      case 'icon_mic_off': return $r('app.media.icon_mic_off');
      case 'icon_handsfree': return $r('app.media.icon_handsfree');
      case 'icon_handsfree_on': return $r('app.media.icon_handsfree_on');
      case 'icon_camera_on': return $r('app.media.icon_camera_on');
      case 'icon_camera_off': return $r('app.media.icon_camera_off');
      case 'icon_big_switch_camera': return $r('app.media.icon_big_switch_camera');
      case 'switch_camera': return $r('app.media.switch_camera');
      case 'icon_big_virtual_background_off': return $r('app.media.icon_big_virtual_background_off');
      case 'icon_big_virtual_background_on': return $r('app.media.icon_big_virtual_background_on');
      case 'virtual_background': return $r('app.media.virtual_background');
      case 'icon_min_window': return $r('app.media.icon_min_window');
      case 'icon_add_user': return $r('app.media.icon_add_user');
      case 'default_user_icon': return $r('app.media.default_user_icon');
      case 'default_participant_icon': return $r('app.media.default_participant_icon');
      case 'audio_call': return $r('app.media.audio_call');
      case 'video_call': return $r('app.media.video_call');
      case 'icon_volume': return $r('app.media.icon_volume');
      case 'group_network_low_quality': return $r('app.media.group_network_low_quality');
      case 'icon_audio_route_picker': return $r('app.media.icon_audio_route_picker');
      case 'icon_float_dialing': return $r('app.media.icon_float_dialing');
      case 'icon_float_group_audio_on': return $r('app.media.icon_float_group_audio_on');
      case 'icon_float_group_audio_off': return $r('app.media.icon_float_group_audio_off');
      case 'icon_float_group_video_on': return $r('app.media.icon_float_group_video_on');
      case 'icon_float_group_video_off': return $r('app.media.icon_float_group_video_off');
      case 'icon_match': return $r('app.media.icon_match');
      default: return $r('app.media.default_user_icon');
    }
  }
}
