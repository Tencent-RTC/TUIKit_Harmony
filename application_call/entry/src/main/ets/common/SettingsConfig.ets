// SettingsConfig.ets
// In-memory settings singleton, aligned with iOS atomic-x/ios/application/App-UIKit/Call/CallSettings/SettingsConfig.swift.
// All values are kept in memory (not persisted), matching the iOS demo behavior.

export class SettingsConfig {
  private static _instance: SettingsConfig | null = null;

  static shared(): SettingsConfig {
    if (!SettingsConfig._instance) {
      SettingsConfig._instance = new SettingsConfig();
    }
    return SettingsConfig._instance;
  }

  private constructor() {}

  /* identity */
  userId: string = '';
  avatar: string = '';
  name: string = '';

  /* basic */
  ringUrl: string = '';
  mute: boolean = false;
  floatWindow: boolean = true;
  enableVirtualBackground: boolean = true;
  enableIncomingBanner: boolean = true;
  /** Not supported by call_v2 v1 — UI only. */
  enableAITranscriber: boolean = true;

  /* call params */
  intRoomId: number = 0;
  strRoomId: string = '';
  timeout: number = 60;
  userData: string = '';
  /**
   * Default offline push payload. Aligned with iOS `pushInfo` defaults
   * (title / desc / iOSPushType / iOSSound / androidSound / OPPO / FCM / VIVO / HuaWei).
   */
  offlineData: string = JSON.stringify({
    title: 'NEW CALL',
    desc: 'You have a new call invitation!',
    iOSPushType: 0,
    ignoreIOSBadge: false,
    iOSSound: 'phone_ringing.mp3',
    androidSound: 'phone_ringing',
    androidOPPOChannelID: 'tuikit',
    androidFCMChannelID: 'fcm_push_channel',
    androidVIVOClassification: 1,
    androidHuaWeiCategory: 'IM',
  }, null, 2);

  /* video — none of the following can actually be delivered via call_v2 v1; UI only. */
  /** 0=640*360, 1=960*540, 2=1280*720, 3=1920*1080 */
  resolution: number = 2;
  /** 0=landscape, 1=portrait */
  resolutionMode: number = 1;
  /** 0=0deg, 1=90deg, 2=180deg, 3=270deg */
  rotation: number = 0;
  /** 0=fit, 1=fill */
  fillMode: number = 1;
  beautyLevel: number = 6;

  /* misc */
  is1VN: boolean = true;
  /** 0=portrait, 1=landscapeLeft, 2=auto */
  screenOrientation: number = 0;
}
