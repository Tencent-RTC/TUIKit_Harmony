import { bundleManager } from '@kit.AbilityKit';

/** 本机安装包版本信息 */
export interface LocalAppVersion {
  versionName: string;
  versionCode: number;
}

/**
 * 读取当前 Harmony 应用版本（对齐 Android `AndroidUtil.getApkVersionName/Code`）。
 */
export class AppVersionUtil {
  private static cached: LocalAppVersion | null = null;

  static async getLocalVersion(): Promise<LocalAppVersion> {
    if (AppVersionUtil.cached !== null) {
      return AppVersionUtil.cached;
    }
    try {
      const info = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const local: LocalAppVersion = {
        versionName: info.versionName ?? '',
        versionCode: info.versionCode ?? 0,
      };
      AppVersionUtil.cached = local;
      return local;
    } catch (err) {
      console.error(`AppVersionUtil getLocalVersion failed: ${JSON.stringify(err)}`);
      return { versionName: '', versionCode: 0 };
    }
  }

  /** 格式：`V1.1.0`，用于关于页菜单右侧展示 */
  static formatDisplayName(versionName: string): string {
    if (versionName.length === 0) {
      return '';
    }
    return versionName.startsWith('V') || versionName.startsWith('v')
      ? versionName
      : `V${versionName}`;
  }

  /**
   * 格式：`版本 V1.1.0(Build64)-test`
   * 对齐 Android `VersionInfoActivity` 主文案。
   */
  static formatDetailText(versionName: string, versionCode: number, envType: string): string {
    const name = AppVersionUtil.formatDisplayName(versionName);
    const env = envType.length > 0 ? envType : 'unknown';
    return `版本 ${name}(Build${versionCode})-${env}`;
  }
}

export default AppVersionUtil;
