import { UserBean } from '../bean/UserBean';
import { http } from '../network';

/** 获取当前用户资料（Http 拦截器已解包为 `data` 字段）。 */
export const getUserInfo = (): Promise<UserBean> => {
  return http.get<UserBean>('/api/v1/user/profile');
};
