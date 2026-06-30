import { MMKV } from '@tencent/mmkv';
import { UserBean, emptyUserBean, assignProfile, assignAll } from './UserBean';

/**
 * 登录态单例：内部只持有一份 {@link UserBean}，读写 MMKV 与业务 API 共用同一结构。
 */
const PER_USER_MODEL = 'per_user_model';

export class LoginUserInfo {
  private static sInstance: LoginUserInfo | null = null;
  private readonly bean: UserBean = emptyUserBean();

  private constructor() {
    this.loadFromDisk();
  }

  static getInstance(): LoginUserInfo {
    if (LoginUserInfo.sInstance === null) {
      LoginUserInfo.sInstance = new LoginUserInfo();
    }
    return LoginUserInfo.sInstance;
  }

  /** 只读访问完整数据（字段与 UserBean / MMKV 一致） */
  getData(): UserBean {
    return this.bean;
  }

  getToken(): string {
    return this.bean.token;
  }

  getRefreshToken(): string {
    return this.bean.refresh_token;
  }

  getExpiresIn(): number {
    return this.bean.expires_in;
  }

  getUserId(): string {
    return this.bean.user_id;
  }

  getPhoneNumber(): string {
    return this.bean.phone_number;
  }

  getNickname(): string {
    return this.bean.nickname;
  }

  getAvatarUrl(): string {
    return this.bean.avatar_url;
  }

  isLogin(): boolean {
    return this.bean.is_login && this.bean.token.length > 0;
  }

  isExperimentTypeAi(): boolean {
    return this.bean.experiment_type === 'AI';
  }

  /** {@link getUserInfo}：只更新资料段，保留已有 token */
  updateFromUserBean(source: UserBean): void {
    assignProfile(this.bean, source);
    this.save();
  }

  /** Flutter 登录成功：只写会话段 */
  updateFromLoginSuccess(args: Record<string, Object>): void {
    const p = LoginUserInfo.unwrapData(args);
    const tokenVal = p['token'] ?? args['token'];
    const refreshVal = p['refresh_token'] ?? p['refreshToken'] ?? args['refresh_token'] ?? args['refreshToken'];
    const expiresVal = p['expires_in'] ?? p['expiresIn'] ?? args['expires_in'] ?? args['expiresIn'];

    if (typeof tokenVal === 'string') {
      this.bean.token = tokenVal;
    }
    if (typeof refreshVal === 'string') {
      this.bean.refresh_token = refreshVal;
    }
    if (typeof expiresVal === 'number') {
      this.bean.expires_in = expiresVal;
    } else if (typeof expiresVal === 'string') {
      const n = Number.parseInt(expiresVal, 10);
      if (!Number.isNaN(n)) {
        this.bean.expires_in = n;
      }
    }
    this.bean.is_login = this.bean.token.length > 0;
    this.save();
  }

  cleanUserInfo(): void {
    assignAll(this.bean, emptyUserBean());
    this.save();
  }

  debugDumpForTest(): string {
    const b = this.bean;
    return [
      '=== LoginUserInfo (UserBean) ===',
      `is_login: ${b.is_login}, isLogin(): ${this.isLogin()}`,
      `token: ${b.token}`,
      `refresh_token: ${b.refresh_token}`,
      `expires_in: ${b.expires_in}`,
      `user_id: ${b.user_id}`,
      `phone_number: ${b.phone_number}`,
      `nickname: ${b.nickname}`,
      `avatar_url: ${b.avatar_url}`,
      `imId: ${b.imId}`,
      `experiment_type: ${b.experiment_type}`,
      '==============================',
    ].join('\n');
  }

  private getMMKV(): MMKV | null {
    try {
      return MMKV.defaultMMKV();
    } catch (_) {
      return null;
    }
  }

  private loadFromDisk(): void {
    const mmkv = this.getMMKV();
    if (mmkv === null) {
      return;
    }
    const json = mmkv.decodeString(PER_USER_MODEL);
    if (json === null || json === undefined || json.length === 0) {
      return;
    }
    try {
      const raw = JSON.parse(json) as Record<string, Object>;
      assignAll(this.bean, LoginUserInfo.parseFromRecord(raw));
    } catch (err) {
      console.error(`LoginUserInfo loadFromDisk failed: ${JSON.stringify(err)}`);
    }
  }

  private save(): void {
    const mmkv = this.getMMKV();
    if (mmkv === null) {
      return;
    }
    try {
      mmkv.encodeString(PER_USER_MODEL, JSON.stringify(this.bean));
    } catch (err) {
      console.error(`LoginUserInfo save failed: ${JSON.stringify(err)}`);
    }
  }

  /** 从 MMKV JSON 解析为 UserBean（兼容旧版 camelCase 键名） */
  private static parseFromRecord(raw: Record<string, Object>): UserBean {
    return {
      token: LoginUserInfo.str(raw, 'token'),
      refresh_token: LoginUserInfo.str(raw, 'refresh_token', 'refreshToken'),
      expires_in: LoginUserInfo.num(raw, 'expires_in', 'expiresIn'),
      is_login: LoginUserInfo.bool(raw, 'is_login', 'isLoginFlag'),
      zone: LoginUserInfo.str(raw, 'zone'),
      auto_login: LoginUserInfo.bool(raw, 'auto_login', 'autoLogin'),
      user_id: LoginUserInfo.str(raw, 'user_id', 'userId'),
      nickname: LoginUserInfo.str(raw, 'nickname'),
      avatar_url: LoginUserInfo.str(raw, 'avatar_url', 'avatarUrl'),
      phone_number: LoginUserInfo.str(raw, 'phone_number', 'phoneNumber'),
      gender: LoginUserInfo.num(raw, 'gender'),
      city: LoginUserInfo.str(raw, 'city'),
      country: LoginUserInfo.str(raw, 'country'),
      province: LoginUserInfo.str(raw, 'province'),
      registration_date: LoginUserInfo.str(raw, 'registration_date', 'registrationDate'),
      last_login_at: LoginUserInfo.str(raw, 'last_login_at', 'lastLoginAt'),
      mark: LoginUserInfo.num(raw, 'mark'),
      imId: LoginUserInfo.str(raw, 'imId'),
      imUserSig: LoginUserInfo.str(raw, 'imUserSig'),
      imUserSigExpire: LoginUserInfo.str(raw, 'imUserSigExpire'),
      experiment_type: LoginUserInfo.str(raw, 'experiment_type', 'experimentType'),
      experiment_version: LoginUserInfo.num(raw, 'experiment_version', 'experimentVersion'),
    };
  }

  private static unwrapData(args: Record<string, Object>): Record<string, Object> {
    const wrapped = args['data'];
    if (wrapped !== undefined && wrapped !== null && typeof wrapped === 'object') {
      return wrapped as Record<string, Object>;
    }
    return {} as Record<string, Object>;
  }

  private static str(obj: Record<string, Object>, key: string, alt?: string): string {
    const v = obj[key] ?? (alt !== undefined ? obj[alt] : undefined);
    if (typeof v === 'string') {
      return v;
    }
    if (typeof v === 'number') {
      return String(v);
    }
    return '';
  }

  private static num(obj: Record<string, Object>, key: string, alt?: string): number {
    const v = obj[key] ?? (alt !== undefined ? obj[alt] : undefined);
    if (typeof v === 'number' && !Number.isNaN(v)) {
      return v;
    }
    if (typeof v === 'string') {
      const n = Number.parseInt(v, 10);
      return Number.isNaN(n) ? 0 : n;
    }
    return 0;
  }

  private static bool(obj: Record<string, Object>, key: string, alt?: string): boolean {
    const v = obj[key] ?? (alt !== undefined ? obj[alt] : undefined);
    return v === true;
  }
}

export default LoginUserInfo;
