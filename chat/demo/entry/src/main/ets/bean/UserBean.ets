/**
 * 用户 + 登录态统一数据模型。
 * - `getUserInfo` 的 `data` 只填充资料段；token 等由 Flutter 登录成功后写入。
 * - MMKV / LoginUserInfo 单例均使用本结构，字段名与接口 JSON 一致。
 */
export interface UserBean {
  // ---------- 登录会话（Flutter flutter_pushLoginSuccess / 本地 MMKV）----------

  /** 访问令牌，请求头 Authorization: Bearer {token} */
  token: string;
  /** 刷新令牌，用于续期 access token */
  refresh_token: string;
  /** access token 有效时长（秒） */
  expires_in: number;
  /** 是否已登录（token 非空且登录成功时为 true） */
  is_login: boolean;
  /** 手机区号，如 +86 */
  zone: string;
  /** 是否开启自动登录 */
  auto_login: boolean;

  // ---------- 用户资料（GET /api/v1/user/profile 的 data）----------

  /** 业务用户 ID */
  user_id: string;
  /** 昵称 */
  nickname: string;
  /** 头像 URL */
  avatar_url: string;
  /** 手机号（不含区号） */
  phone_number: string;
  /** 性别：0 未知，1 男，2 女（与后端约定一致） */
  gender: number;
  /** 城市 */
  city: string;
  /** 国家 */
  country: string;
  /** 省份 */
  province: string;
  /** 注册时间（ISO 8601 字符串） */
  registration_date: string;
  /** 最近登录时间（ISO 8601 字符串） */
  last_login_at: string;
  /** 用户标记位（业务自定义） */
  mark: number;
  /** 腾讯云 IM 用户 ID */
  imId: string;
  /** 腾讯云 IM UserSig */
  imUserSig: string;
  /** UserSig 剩余有效时间（秒，接口常为字符串） */
  imUserSigExpire: string;
  /** 实验类型，如 AI */
  experiment_type: string;
  /** 实验版本号 */
  experiment_version: number;
}

export function emptyUserBean(): UserBean {
  return {
    token: '',
    refresh_token: '',
    expires_in: 0,
    is_login: false,
    zone: '',
    auto_login: false,
    user_id: '',
    nickname: '',
    avatar_url: '',
    phone_number: '',
    gender: 0,
    city: '',
    country: '',
    province: '',
    registration_date: '',
    last_login_at: '',
    mark: 0,
    imId: '',
    imUserSig: '',
    imUserSigExpire: '',
    experiment_type: '',
    experiment_version: 0,
  };
}

/** 仅合并资料段（不覆盖 token 等会话字段，供 getUserInfo 结果写入） */
export function assignProfile(target: UserBean, source: UserBean): void {
  target.user_id = source.user_id ?? '';
  target.nickname = source.nickname ?? '';
  target.avatar_url = source.avatar_url ?? '';
  target.phone_number = source.phone_number ?? '';
  target.gender = source.gender ?? 0;
  target.city = source.city ?? '';
  target.country = source.country ?? '';
  target.province = source.province ?? '';
  target.registration_date = source.registration_date ?? '';
  target.last_login_at = source.last_login_at ?? '';
  target.mark = source.mark ?? 0;
  target.imId = source.imId ?? '';
  target.imUserSig = source.imUserSig ?? '';
  target.imUserSigExpire = source.imUserSigExpire ?? '';
  target.experiment_type = source.experiment_type ?? '';
  target.experiment_version = source.experiment_version ?? 0;
}

/** 整对象覆盖（MMKV 恢复 / 登出清空） */
export function assignAll(target: UserBean, source: UserBean): void {
  target.token = source.token ?? '';
  target.refresh_token = source.refresh_token ?? '';
  target.expires_in = source.expires_in ?? 0;
  target.is_login = source.is_login ?? false;
  target.zone = source.zone ?? '';
  target.auto_login = source.auto_login ?? false;
  assignProfile(target, source);
}

export default UserBean;
