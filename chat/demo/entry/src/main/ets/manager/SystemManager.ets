import { VersionBean } from '../bean/VersionBean';
import { getVersionLatest } from '../api/SystemApi';
import { AppVersionUtil, LocalAppVersion } from './AppVersionUtil';

export type VersionListener = (latest: VersionBean | null, hasNewVersion: boolean) => void;

/**
 * 系统能力管理（对齐 Android `SystemRepository` 版本相关逻辑）。
 */
export class SystemManager {
  private static sInstance: SystemManager | null = null;

  private latestVersion: VersionBean | null = null;
  private localVersion: LocalAppVersion | null = null;
  private hasNewVersion: boolean = false;
  private readonly listeners: VersionListener[] = [];
  private fetching: boolean = false;

  static getInstance(): SystemManager {
    if (SystemManager.sInstance === null) {
      SystemManager.sInstance = new SystemManager();
    }
    return SystemManager.sInstance;
  }

  getLatestVersion(): VersionBean | null {
    return this.latestVersion;
  }

  getHasNewVersion(): boolean {
    return this.hasNewVersion;
  }

  async getLocalVersion(): Promise<LocalAppVersion> {
    if (this.localVersion !== null) {
      return this.localVersion;
    }
    this.localVersion = await AppVersionUtil.getLocalVersion();
    return this.localVersion;
  }

  /** 拉取服务端最新版本并通知监听方（对齐 `getVersionLastest` + LiveData） */
  async refreshLatestVersion(): Promise<void> {
    if (this.fetching) {
      return;
    }
    this.fetching = true;
    try {
      const local = await this.getLocalVersion();
      const latest = await getVersionLatest();
      this.latestVersion = latest;
      this.hasNewVersion = latest.versionCode > local.versionCode;
      this.notifyListeners();
    } catch (err) {
      console.error(`SystemManager refreshLatestVersion failed: ${JSON.stringify(err)}`);
      this.notifyListeners();
    } finally {
      this.fetching = false;
    }
  }

  addVersionListener(listener: VersionListener): () => void {
    this.listeners.push(listener);
    listener(this.latestVersion, this.hasNewVersion);
    return () => {
      const idx = this.listeners.indexOf(listener);
      if (idx >= 0) {
        this.listeners.splice(idx, 1);
      }
    };
  }

  private notifyListeners(): void {
    const latest = this.latestVersion;
    const hasNew = this.hasNewVersion;
    this.listeners.forEach((listener: VersionListener) => {
      listener(latest, hasNew);
    });
  }
}

export default SystemManager;
