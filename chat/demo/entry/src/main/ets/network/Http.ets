/**
 * 网络请求封装（基于 @ohos/axios，用法类似前端的 axios）。
 *
 * 调用链简要说明：
 * 1. 业务代码调用 Http.get/post → 走下面的 request 实例；
 * 2. 【请求拦截器】在真正发请求前统一加 baseURL、Token、公共 Header；
 * 3. 服务器返回后，【响应拦截器】解析 { code, message, data }，成功时只把 data 交给业务层；
 * 4. 失败时 Toast 提示，并用 Promise.reject 让 await / .catch 能接到错误。
 */

import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios';
import { Prompt } from '@kit.ArkUI';
import { AppSettings } from '../config/AppSettings';
import { LoginUserInfo } from '../bean/LoginUserInfo';

/**
 * 服务端统一响应外壳（业务数据在 data 里）。
 * 例如：{ "code": 0, "message": "success", "data": { ...用户资料... } }
 */
export interface ResponseType<T> {
  code: number;
  message: string;
  data: T;
  ok: boolean;
}

/** 环境配置（baseUrl 等），来自 AppSettings / 编译配置 */
const appSettings = AppSettings.getInstance();
/** 当前登录用户（token、userId 等），请求时要带给后端 */
const loginUserInfo = LoginUserInfo.getInstance();

/**
 * 创建 axios 实例：所有接口共用一个 baseURL 和超时时间。
 * - baseURL：如 https://test.histar.com/zlxt/app/，后面 get('/api/...') 会拼在这个后面
 * - timeout：10000 表示 10 秒没响应就按超时失败处理
 */
const request = axios.create({
  baseURL: appSettings.getBaseUrl(),
  timeout: 10000
});

// ===================== 请求拦截器：发请求「之前」执行 =====================
request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 已登录则把用户 id、Token 放进请求头（后端用来识别是谁在调接口）
    if (loginUserInfo != null) {
      if (loginUserInfo.getUserId() != null) {
        config.headers.userId = loginUserInfo.getUserId();
      }
      if (loginUserInfo.getToken() != null) {
        config.headers.Authorization = 'Bearer ' + loginUserInfo.getToken();
      }
    }
    // 以下是与 Android / Flutter 对齐的公共 Header，每个接口都会自动带上
    config.headers.ContentType = 'application/json';
    config.headers.Accept = 'application/json';
    config.headers.Source = 'android';
    config.headers.Version = '1.1.0';
    config.headers.Timezone = 'Asia/Shanghai';
    config.headers.clientDst = '0';
    // 必须把 config 返回出去，axios 才会用修改后的配置继续发请求
    return config;
  }
);

// ===================== 响应拦截器：收到响应「之后」执行 =====================
request.interceptors.response.use(
  // 第一个函数：HTTP 成功（状态码 2xx）且能解析到 body 时进入
  (response: AxiosResponse) => {
    // 调试用：把整包 JSON 打成字符串，避免控制台只显示 [object Object]
    console.log('axios-response: ' + JSON.stringify(response.data));

    const bizCode = Number(response.data.code);
    // 你们接口成功时 code 为 0；部分老接口可能是 200，两种都视为成功
    if (bizCode === 0 || bizCode === 200) {
      // 只把 data 返回给业务层，例如 getUserInfo 直接拿到 UserBean，不用再解一层
      return response.data.data;
    } else {
      // 业务失败：code 非 0/200，例如参数错误、未登录等
      const message = response.data.message as string;
      Prompt.showToast({ message });
      // reject 后，调用方的 await getUserInfo() 会进 catch
      return Promise.reject(message);
    }
  },
  // 第二个函数：网络错误、超时、HTTP 4xx/5xx 等会进这里（不会走上面的成功分支）
  (error: AxiosError) => {
    const message = error.message as string;
    Prompt.showToast({ message });
    return Promise.reject(message);
  }
);

/**
 * 对外暴露的 Http 类：业务里用 http.get / http.post，不要直接用上面的 request。
 *
 * 泛型 T：表示「解包后 data 的类型」，例如 http.get<UserBean>('/api/v1/user/profile')
 */
export default class Http {
  /** GET：参数会拼在 URL 查询串上，例如 ?page=1 */
  get<T>(url: string, params?: object) {
    return request.get<null, T>(url, {
      params
    });
  }

  /** POST：请求体在 body 里，一般用来提交表单、登录等 */
  post<T>(url: string, data?: object) {
    return request.post<null, T>(url, data);
  }

  /** PUT：更新资源 */
  put<T>(url: string, data?: object) {
    return request.put<null, T>(url, data);
  }

  /** DELETE：删除资源，可选查询参数 params */
  delete<T>(url: string, params?: object) {
    return request.delete<null, T>(url, {
      params
    });
  }
}
