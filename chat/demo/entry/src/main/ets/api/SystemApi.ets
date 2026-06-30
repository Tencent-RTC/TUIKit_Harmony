import { VersionBean } from '../bean/VersionBean';
import { http } from '../network';

/** 与 Android `SystemApi.versionLatest` 使用相同的 appId 查询参数 */
const VERSION_APP_ID = 'com.zlxt.histar';

/** `GET /api/v1/version/latest` 查询参数 */
interface VersionLatestQuery {
  appId: string;
}

/**
 * 获取服务端最新版本信息。
 * 对齐 Android：`GET /api/v1/version/latest?appId=...`
 */
export const getVersionLatest = (): Promise<VersionBean> => {
  const query: VersionLatestQuery = {
    appId: VERSION_APP_ID,
  };
  return http.get<VersionBean>('/api/v1/version/latest', query);
};
