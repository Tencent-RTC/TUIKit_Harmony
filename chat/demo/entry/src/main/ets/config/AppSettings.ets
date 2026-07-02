//鸿蒙上的本地小数据库，用 key-value 把登录信息、设置等存到手机，下次打开 App 还能读回来。
import { MMKV } from '@tencent/mmkv';
import BuildProfile from 'BuildProfile';

/**
 * 鸿蒙版 AppSettings —— 与 Android `com.zlxt.histar.config.AppSettings` 对齐。
 *
 * 设计要点：
 * - 单例：`getInstance()` 全局访问。
 * - 默认值：来自 `BuildProfile`（由 `entry/build-profile.json5` 中各 buildMode 的
 *   `arkOptions.buildProfileFields` 注入），等价于 Android `BuildConfig.xxx`。
 * - 持久化：通过 MMKV 以单条 JSON 的形式落盘（key = `app_settings`），
 *   等价于 Android 中 `SharedPreferences + Gson` 的玩法。
 * - 写时即刻持久化：每个 setter 内部都会调用 `save()`。
 *
 * 字段对齐：
 *   envType / baseUrl / h5Url / imSdkAppId / pushAppkey / agreePrivacy
 */

/** MMKV 落盘 key */
const APP_SETTINGS_KEY = 'app_settings';

/** 持久化结构（注意：用可选字段以兼容老版本数据） */
interface AppSettingsPersistShape {
  envType?: string;
  baseUrl?: string;
  h5Url?: string;
  imSdkAppId?: number;
  pushAppkey?: string;
  agreePrivacy?: number;
}

export class AppSettings {
  // ============ 环境类型常量（与 Android `AppConfig` 对齐） ============
  static readonly ENV_TYPE_DEV: string = 'dev';
  static readonly ENV_TYPE_TEST: string = 'test';
  static readonly ENV_TYPE_UAT: string = 'uat';
  static readonly ENV_TYPE_RELEASE: string = 'release';

  private static sInstance: AppSettings | null = null;

  // ============ 环境配置 ============
  private envType: string = '';
  private baseUrl: string = '';
  private h5Url: string = '';
  private imSdkAppId: number = 0;
  private pushAppkey: string = '';

  /** 是否同意隐私协议：0 未同意，1 已同意 */
  private agreePrivacy: number = 0;

  private constructor() {
    // 先以 BuildProfile（编译期注入）作为默认值，再用磁盘上持久化的值覆盖。
    this.envType = AppSettings.readBuildProfileString('ENV_TYPE');
    this.baseUrl = AppSettings.readBuildProfileString('BASE_URL');
    this.h5Url = AppSettings.readBuildProfileString('H5_URL');
    this.imSdkAppId = AppSettings.readBuildProfileNumber('IM_SDK_APPID');
    this.pushAppkey = AppSettings.readBuildProfileString('PUSH_APPKEY');
    this.loadFromDisk();
  }

  /** 全局单例。线程模型为 UI 线程顺序执行，无需额外加锁。 */
  static getInstance(): AppSettings {
    if (AppSettings.sInstance === null) {
      AppSettings.sInstance = new AppSettings();
    }
    return AppSettings.sInstance;
  }

  // ===================== getter / setter =====================

  getEnvType(): string {
    return this.envType;
  }

  setEnvType(envType: string): void {
    this.envType = envType ?? '';
    this.save();
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  setBaseUrl(baseUrl: string): void {
    this.baseUrl = baseUrl ?? '';
    this.save();
  }

  getH5Url(): string {
    return this.h5Url;
  }

  setH5Url(h5Url: string): void {
    this.h5Url = h5Url ?? '';
    this.save();
  }

  getImSdkAppId(): number {
    return this.imSdkAppId;
  }

  setImSdkAppId(imSdkAppId: number): void {
    this.imSdkAppId = imSdkAppId;
    this.save();
  }

  getPushAppkey(): string {
    return this.pushAppkey;
  }

  setPushAppkey(pushAppkey: string): void {
    this.pushAppkey = pushAppkey ?? '';
    this.save();
  }

  getAgreePrivacy(): number {
    return this.agreePrivacy;
  }

  setAgreePrivacy(agreePrivacy: number): void {
    this.agreePrivacy = agreePrivacy;
    this.save();
  }

  /** 一次性批量更新环境配置（对齐 Android `setEnvironmentConfig`）。 */
  setEnvironmentConfig(
    envType: string,
    baseUrl: string,
    h5Url: string,
    imSdkAppId: number,
    pushAppkey: string,
  ): void {
    this.envType = envType ?? '';
    this.baseUrl = baseUrl ?? '';
    this.h5Url = h5Url ?? '';
    this.imSdkAppId = imSdkAppId;
    this.pushAppkey = pushAppkey ?? '';
    this.save();
  }

  /** 环境显示名（对齐 Android `AppConfig.getEnvDisplayName`）。 */
  getEnvDisplayName(): string {
    switch (this.envType) {
      case AppSettings.ENV_TYPE_DEV:
        return 'Dev环境';
      case AppSettings.ENV_TYPE_TEST:
        return 'Test环境';
      case AppSettings.ENV_TYPE_UAT:
        return 'Uat环境';
      case AppSettings.ENV_TYPE_RELEASE:
        return 'Release环境';
      default:
        return this.envType;
    }
  }

  /** 调试快照（不要在生产日志里打 PUSH_APPKEY 这种敏感信息，仅本地排查用）。 */
  debugDump(): string {
    const lines: string[] = [
      '=== AppSettings 调试快照 ===',
      `envType: ${this.envType}`,
      `baseUrl: ${this.baseUrl}`,
      `h5Url: ${this.h5Url}`,
      `imSdkAppId: ${this.imSdkAppId}`,
      `pushAppkey: ${this.pushAppkey}`,
      `agreePrivacy: ${this.agreePrivacy}`,
      '============================',
    ];
    return lines.join('\n');
  }

  // ===================== 内部：BuildProfile 读取 =====================

  /**
   * 安全读取 BuildProfile 上的字符串字段。
   * BuildProfile 中的字段要在 entry/build-profile.json5 的 `arkOptions.buildProfileFields` 中注入；
   * 若由于配置缺失/旧产物未重建造成字段不存在，这里返回空串而不是抛异常，避免冷启动崩溃。
   *
   * 注意 ArkTS 严格模式不允许从 `typeof BuildProfile` 直接断言成 `Record<...>`，
   * 需要经由顶层 `Object` 中转才能合法做反射式属性访问。
   */
  private static readBuildProfileString(key: string): string {
    const v = AppSettings.readBuildProfileField(key);
    if (typeof v === 'string') {
      return v;
    }
    if (typeof v === 'number') {
      return String(v);
    }
    return '';
  }

  /** 同上，读取 number 类型的 BuildProfile 字段（不存在则返回 0）。 */
  private static readBuildProfileNumber(key: string): number {
    const v = AppSettings.readBuildProfileField(key);
    if (typeof v === 'number') {
      return v;
    }
    if (typeof v === 'string') {
      const parsed = Number.parseInt(v, 10);
      return Number.isNaN(parsed) ? 0 : parsed;
    }
    return 0;
  }

  /** 反射式读取 BuildProfile 上的任意字段，封装类型断言细节。 */
  private static readBuildProfileField(key: string): Object | null {
    try {
      // 双重断言：typeof BuildProfile -> Object -> Record，绕过 ArkTS 严格类型检查。
      const profileMap = BuildProfile as Object as Record<string, Object>;
      const v = profileMap[key];
      return v ?? null;
    } catch (_) {
      return null;
    }
  }

  // ===================== 内部：MMKV 持久化 =====================

  private getMMKV(): MMKV | null {
    try {
      return MMKV.defaultMMKV();
    } catch (_) {
      // MMKV 未初始化（异常场景，例如未走 EntryAbility.onCreate 的单元测试）
      return null;
    }
  }

  private loadFromDisk(): void {
    const mmkv = this.getMMKV();
    if (mmkv === null) {
      return;
    }
    const json = mmkv.decodeString(APP_SETTINGS_KEY);
    if (json === null || json === undefined || json.length === 0) {
      return;
    }
    try {
      const data = JSON.parse(json) as AppSettingsPersistShape;
      // 仅当持久化数据存在该字段时才覆盖默认值，便于线上动态切换环境。
      if (typeof data.envType === 'string' && data.envType.length > 0) {
        this.envType = data.envType;
      }
      if (typeof data.baseUrl === 'string' && data.baseUrl.length > 0) {
        this.baseUrl = data.baseUrl;
      }
      if (typeof data.h5Url === 'string' && data.h5Url.length > 0) {
        this.h5Url = data.h5Url;
      }
      if (typeof data.imSdkAppId === 'number' && data.imSdkAppId > 0) {
        this.imSdkAppId = data.imSdkAppId;
      }
      if (typeof data.pushAppkey === 'string' && data.pushAppkey.length > 0) {
        this.pushAppkey = data.pushAppkey;
      }
      if (typeof data.agreePrivacy === 'number') {
        this.agreePrivacy = data.agreePrivacy;
      }
    } catch (err) {
      console.error(`AppSettings loadFromDisk parse failed: ${JSON.stringify(err)}`);
    }
  }

  private save(): void {
    const mmkv = this.getMMKV();
    if (mmkv === null) {
      return;
    }
    const data: AppSettingsPersistShape = {
      envType: this.envType,
      baseUrl: this.baseUrl,
      h5Url: this.h5Url,
      imSdkAppId: this.imSdkAppId,
      pushAppkey: this.pushAppkey,
      agreePrivacy: this.agreePrivacy,
    };
    try {
      mmkv.encodeString(APP_SETTINGS_KEY, JSON.stringify(data));
    } catch (err) {
      console.error(`AppSettings save failed: ${JSON.stringify(err)}`);
    }
  }
}

export default AppSettings;
