export class Constants {
  static readonly TUICALL_VERSION: string = '4.2.0';

  static readonly MAX_USER: number = 9;
  static readonly TUI_CALLKIT_SIGNALING_MAX_TIME: number = 30;

  static readonly TUI_CALLING_BELL_KEY: string = 'CallingBell';
  static readonly ENABLE_MUTEMODE_USERDEFAULT: string = 'ENABLE_MUTEMODE_USERDEFAULT';
  static readonly TUI_CALLKIT_PREF_NAME: string = 'tuicallkit_prefs';

  static readonly DEFAULT_RINGING_FILE: string = 'phone_ringing.mp3';
  static readonly DEFAULT_DIALING_FILE: string = 'phone_dialing.m4a';
  static readonly DEFAULT_HANGUP_FILE: string = 'phone_hangup.mp3';

  static readonly CONTROL_BTN_SIZE: number = 60;
  static readonly BTN_LARGE_SIZE: number = 60;
  static readonly BTN_SMALL_ICON_SIZE: number = 28;
  static readonly BTN_SMALL_SIZE: number = 50;

  static readonly CONTROLS_CONTAINER_MAX_WIDTH: number = 480;
}

export class FrameworkConstants {
  static readonly callFrameworkNative: number = 1;
  static readonly callComponent: number = 14;
  static readonly callComponentChat: number = 15;
  static readonly callLanguageArkTS: number = 11;

  static readonly framework: number = FrameworkConstants.callFrameworkNative;
  static readonly component: number = FrameworkConstants.callComponent;
  static readonly language: number = FrameworkConstants.callLanguageArkTS;
}
