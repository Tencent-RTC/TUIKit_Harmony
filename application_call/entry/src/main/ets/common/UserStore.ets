import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { LoginStore, UserProfile } from '@tencentcloud/atomicxcore';
import { Constants } from './Constants';

export class UserStore {
  private static _instance: UserStore;
  private pref: preferences.Preferences | null = null;
  private context: common.UIAbilityContext | null = null;
  private initialized: boolean = false;

  userId: string = '';
  autoLogin: boolean = false;

  private constructor() {
  }

  static get instance(): UserStore {
    if (!UserStore._instance) {
      UserStore._instance = new UserStore();
    }
    return UserStore._instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) {
      return;
    }
    this.initialized = true;
    this.context = context;
    this.pref = await preferences.getPreferences(context, Constants.PREF_NAME);
    this.userId = await this.pref.get(Constants.KEY_USER_ID, '') as string;
    this.autoLogin = await this.pref.get(Constants.KEY_AUTO_LOGIN, false) as boolean;

    AppStorage.setOrCreate(Constants.KEY_USER_ID, this.userId);
    AppStorage.setOrCreate(Constants.KEY_NICKNAME, '');
    AppStorage.setOrCreate(Constants.KEY_AVATAR_URL, Constants.DEFAULT_AVATAR_URL);
    AppStorage.setOrCreate(Constants.KEY_AUTO_LOGIN, this.autoLogin);
  }

  async login(sdkAppId: number, userId: string, userSig: string): Promise<void> {
    if (!this.context) {
      throw new Error('UserStore not initialized, call init() first');
    }
    await LoginStore.shared().login(sdkAppId, userId, userSig, this.context);
    this.userId = userId;
    AppStorage.setOrCreate(Constants.KEY_USER_ID, userId);
    if (this.pref) {
      await this.pref.put(Constants.KEY_USER_ID, userId);
      await this.pref.flush();
    }
    this.syncToAppStorage();
  }

  async logout(): Promise<void> {
    await LoginStore.shared().logout();
    this.userId = '';
    AppStorage.setOrCreate(Constants.KEY_USER_ID, '');
    AppStorage.setOrCreate(Constants.KEY_NICKNAME, '');
    AppStorage.setOrCreate(Constants.KEY_AVATAR_URL, Constants.DEFAULT_AVATAR_URL);
    if (this.pref) {
      await this.pref.put(Constants.KEY_USER_ID, '');
      await this.pref.flush();
    }
  }

  async setSelfInfo(nickname?: string, avatarUrl?: string): Promise<void> {
    const info = LoginStore.shared().state.loginUserInfo;
    const finalNickname = nickname ?? info?.nickname;
    const finalAvatarUrl = avatarUrl ?? info?.avatarURL;
    const userProfile = new UserProfile(this.userId, finalNickname, finalAvatarUrl);
    await LoginStore.shared().setSelfInfo(userProfile);
    this.syncToAppStorage();
  }

  async setAutoLogin(value: boolean): Promise<void> {
    this.autoLogin = value;
    AppStorage.setOrCreate(Constants.KEY_AUTO_LOGIN, value);
    if (this.pref) {
      await this.pref.put(Constants.KEY_AUTO_LOGIN, value);
      await this.pref.flush();
    }
  }

  get hasNickname(): boolean {
    const nickname = LoginStore.shared().state.loginUserInfo?.nickname ?? '';
    return nickname.length > 0;
  }

  private syncToAppStorage(): void {
    const info = LoginStore.shared().state.loginUserInfo;
    AppStorage.setOrCreate(Constants.KEY_NICKNAME, info?.nickname ?? '');
    AppStorage.setOrCreate(Constants.KEY_AVATAR_URL, info?.avatarURL || Constants.DEFAULT_AVATAR_URL);
  }
}
