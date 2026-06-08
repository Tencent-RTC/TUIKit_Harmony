// CallTestRouter.ets
// Centralized navigation path names used by the root NavPathStack.

export class CallTestRouter {
  static readonly LOGIN: string = 'Login';
  static readonly CALL: string = 'Call';
  static readonly JOIN_GROUP: string = 'JoinGroupCall';
  static readonly SETTINGS: string = 'CallSettings';
  static readonly SETTING_DETAIL: string = 'CallSettingDetail';
}

export enum SettingDetailType {
  ringInfo = 'ringInfo',
  extendInfo = 'extendInfo',
  offlinePushInfo = 'offlinePushInfo',
}

export class SettingDetailParam {
  type: SettingDetailType;

  constructor(type: SettingDetailType) {
    this.type = type;
  }
}
