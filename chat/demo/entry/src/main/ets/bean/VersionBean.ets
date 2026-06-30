/**
 * 版本信息，对齐 Android `com.zlxt.histar.bean.VersionBean`。
 */
export class VersionBean {
  appId: string = '';
  appName: string = '';
  title: string = '';
  contents: string = '';
  platform: string = '';
  versionName: string = '';
  versionCode: number = 0;
  url: string = '';
  isSilent: boolean = false;
  isForce: boolean = false;
  isPublish: boolean = true;
}

/** 从接口 JSON 解析为 VersionBean */
export function parseVersionBean(raw: Record<string, Object>): VersionBean {
  const bean = new VersionBean();
  bean.appId = VersionBeanParser.str(raw, 'appId');
  bean.appName = VersionBeanParser.str(raw, 'appName');
  bean.title = VersionBeanParser.str(raw, 'title');
  bean.contents = VersionBeanParser.str(raw, 'contents');
  bean.platform = VersionBeanParser.str(raw, 'platform');
  bean.versionName = VersionBeanParser.str(raw, 'versionName');
  bean.versionCode = VersionBeanParser.num(raw, 'versionCode');
  bean.url = VersionBeanParser.str(raw, 'url');
  bean.isSilent = VersionBeanParser.bool(raw, 'isSilent');
  bean.isForce = VersionBeanParser.bool(raw, 'isForce');
  bean.isPublish = VersionBeanParser.bool(raw, 'isPublish');
  return bean;
}

namespace VersionBeanParser {
  export function str(obj: Record<string, Object>, key: string): string {
    const v = obj[key];
    if (typeof v === 'string') {
      return v;
    }
    if (typeof v === 'number') {
      return String(v);
    }
    return '';
  }

  export function num(obj: Record<string, Object>, key: string): number {
    const v = obj[key];
    if (typeof v === 'number' && !Number.isNaN(v)) {
      return v;
    }
    if (typeof v === 'string') {
      const n = Number.parseInt(v, 10);
      return Number.isNaN(n) ? 0 : n;
    }
    return 0;
  }

  export function bool(obj: Record<string, Object>, key: string): boolean {
    return obj[key] === true;
  }
}

export default VersionBean;
