import { UserBean } from '../bean/UserBean';
import { http } from '../network';

/** 获取当前用户资料（Http 拦截器已解包为 `data` 字段）。 */
export const getUserInfo = (): Promise<UserBean> => {
  return http.get<UserBean>('/api/v1/user/profile');
};

/**
 * 注销当前账号（对齐 Android `UserApi.cancelAccount` → DELETE `/api/v1/user/cancelAccount`）。
 * @returns 服务端返回的业务数据（一般为空字符串或提示文案）
 */
export const cancelAccount = (): Promise<string> => {
  return http.delete<string>('/api/v1/user/cancelAccount');
};
