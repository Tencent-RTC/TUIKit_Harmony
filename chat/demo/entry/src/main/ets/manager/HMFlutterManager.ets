import { FlutterBoost } from 'flutter_boost';
import systemDateTime from '@ohos.systemDateTime';
import { LoginUserInfo } from '../bean/LoginUserInfo';
import { AppSettings } from '../config/AppSettings';

const TAG = 'HMFlutterManager';

/** Android `LoginUserInfo` 中没有的字段就放鸿蒙侧自有的常量里 */
const APP_VERSION = '1.0.5';

/** 与 FlutterBoostPlugin.EventListener 结构兼容的回调签名 */
export type HMFlutterEventCallback = (key: string, args: Record<string, Object>) => void;
/** 反注册函数，调用一次即可移除监听 */
export type HMFlutterListenerRemover = () => void;

/**
 * 鸿蒙版 FlutterManager —— 对齐 Android `com.zlxt.histar.manager.FlutterManager` 的对外 API。
 * - 路由常量
 * - openFlutter / openBindPhonePage
 * - appPushEnvironment / appPushNetworkConfig / appPushLoginInfo
 * - addFlutterEventListener（避免业务侧直接拿 plugin）
 *
 * 初始化逻辑（FlutterBoost.setup）放在 EntryAbility 中完成，此处不再触碰。
 */
export class HMFlutterManager {
  // -------- Flutter 路由常量 --------
  static readonly FLUTTER_ROUTER_TRAVELDETAIL = '/travel/detail';
  static readonly FLUTTER_ROUTER_TRAVEL_ORDER_DETAIL = '/order/info';
  static readonly FLUTTER_ROUTER_SMSLOGIN = '/login/smsLogin';
  static readonly FLUTTER_ROUTER_ORDER = '/order';
  static readonly FLUTTER_ROUTER_ITINERARY = '/mine/itinerary';
  static readonly FLUTTER_ROUTER_FAVORITE = '/mine/favorite';
  static readonly FLUTTER_ROUTER_EDITPHONE = '/account/editPhone';
  static readonly FLUTTER_ROUTER_ACCOUNT_MANAGEMENT = '/account/management';
  static readonly FLUTTER_ROUTER_EDITNAME = '/account/editName';
  static readonly FLUTTER_ROUTER_TRAVELER = '/traveler';
  static readonly FLUTTER_ROUTER_COUPON = '/mine/coupon';
  static readonly FLUTTER_ROUTER_ORDER_DETAIL = '/order/detail';
  static readonly FLUTTER_ROUTER_REPORT = '/report';
  /** 内嵌 H5（隐私协议、用户协议等） */
  static readonly FLUTTER_ROUTER_WEB_URL = '/web/url';
  static readonly FLUTTER_ROUTER_TRAVEL_RESOURCE_DETAIL = '/travel/resourceDetail';
  static readonly MINE_COUPON_DETAIL = '/mine/coupon/detail';
  /** 绑定手机号 */
  static readonly LOGIN_SMS_BIND = '/login/smsBind';

  // -------- Flutter 事件常量 --------
  static readonly FLUTTER_EVENT_LOGINSUCCESS = 'flutter_pushLoginSuccess';
  static readonly FLUTTER_EVENT_LOGINEXPIRED = 'flutter_pushLoginExpired';
  static readonly FLUTTER_EVENT_PUSHEVENTOBJECT = 'flutter_pushEventObject';
  static readonly FLUTTER_EVENT_PUSHEVENTPAGEINOUT = 'flutter_pushEventPageInOut';

  // -------- openFlutter 防重复点击 --------
  private static readonly OPEN_FLUTTER_THROTTLE_MS = 800;
  private static sLastOpenFlutterTime: number = 0;
  private static sLastOpenFlutterRoute: string = '';

  /**
   * 打开 Flutter 页面，带 800ms 同路由防抖。
   * @param routeName Flutter 路由
   * @param args      可选参数，默认空 Map
   * @param opaque    容器是否不透明，默认 true
   */
  static openFlutter(routeName: string, args?: Record<string, Object>, opaque: boolean = true): void {
    if (!routeName || routeName.length === 0) {
      console.warn(`${TAG} openFlutter: empty routeName, ignored`);
      return;
    }

    const now = HMFlutterManager.nowMs();
    if (routeName === HMFlutterManager.sLastOpenFlutterRoute
      && now - HMFlutterManager.sLastOpenFlutterTime < HMFlutterManager.OPEN_FLUTTER_THROTTLE_MS) {
      console.info(`${TAG} openFlutter ignored by throttle, route=${routeName}`);
      return;
    }
    HMFlutterManager.sLastOpenFlutterRoute = routeName;
    HMFlutterManager.sLastOpenFlutterTime = now;

    const argument: Record<string, Object> = args ?? ({} as Record<string, Object>);
    FlutterBoost.getInstance().open(routeName, argument, opaque);
  }

  /**
   * 打开绑定手机号页（need_bind_phone / 账号关联换绑场景），对应 Android `openBindPhonePage`。
   */
  static openBindPhonePage(platform: string, code: string, bindTicket: string): void {
    const args: Record<string, Object> = {
      'platform': platform ?? '',
      'code': code ?? '',
      'bind_ticket': bindTicket ?? '',
    };
    HMFlutterManager.openFlutter(HMFlutterManager.LOGIN_SMS_BIND, args);
  }

  /**
   * 推送运行环境配置 app_pushEnvironment（对齐 Android `appPushEnvironment`）。
   * 数据来源：{@link AppSettings}（默认值由 `BuildProfile` 注入，运行期可被持久化覆盖）。
   */
  static appPushEnvironment(): void {
    const settings = AppSettings.getInstance();
    const inner: Record<string, Object> = {
      'env': settings.getEnvType(),
      'baseURL': settings.getBaseUrl(),
    };
    const data: Record<string, Object> = {
      'code': 0,
      'data': inner,
    };
    FlutterBoost.getInstance().sendEventToFlutter('app_pushEnvironment', data);
  }

  /**
   * 推送网络配置 app_pushNetworkConfig（对齐 Android `appPushNetworkConfig`）。
   * 已登录则附带 Authorization。
   */
  static appPushNetworkConfig(): void {
    const header: Record<string, Object> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Source': 'android',
      'Version': APP_VERSION,
      'Timezone': 'Asia/Shanghai',
      'clientDst': '0',
    };
    const token = LoginUserInfo.getInstance().getToken();
    if (token.length > 0) {
      header['Authorization'] = `Bearer ${token}`;
    }

    const settings = AppSettings.getInstance();
    const inner: Record<string, Object> = {
      'baseURL': settings.getBaseUrl(),
      'H5_URL': settings.getH5Url(),
      'header': header,
    };
    const data: Record<string, Object> = {
      'code': 0,
      'data': inner,
    };
    FlutterBoost.getInstance().sendEventToFlutter('app_pushNetworkConfig', data);
  }

  /**
   * 推送 Token 配置 app_pushLoginInfo（对齐 Android `appPushLoginInfo`）。
   * 数据从 {@link LoginUserInfo} 读取。
   */
  static appPushLoginInfo(): void {
    const userInfo = LoginUserInfo.getInstance();
    const inner: Record<string, Object> = {
      'token': userInfo.getToken(),
      'refresh_token': userInfo.getRefreshToken(),
      'expires_in': userInfo.getExpiresIn(),
      'isLogin': userInfo.isLogin(),
    };
    const data: Record<string, Object> = {
      'code': 0,
      'data': inner,
    };
    FlutterBoost.getInstance().sendEventToFlutter('app_pushLoginInfo', data);
  }

  /**
   * 监听来自 Flutter 的事件（包了一层避免业务侧直接接触 plugin / EventListener）。
   * 返回值是反注册函数，调用一次即可移除监听。
   */
  static addFlutterEventListener(eventKey: string, callback: HMFlutterEventCallback): HMFlutterListenerRemover {
    const plugin = FlutterBoost.getInstance().getPlugin();
    if (plugin === null || plugin === undefined) {
      console.warn(`${TAG} addFlutterEventListener: plugin not ready, key=${eventKey}`);
      return () => {};
    }
    const remover = plugin.addEventListener(eventKey, {
      onEvent: (key: string, args: Record<string, Object>) => {
        callback(key, args);
      }
    });
    return () => {
      remover.remove();
    };
  }

  private static nowMs(): number {
    try {
      return systemDateTime.getTime();
    } catch (_) {
      return Date.now();
    }
  }
}

export default HMFlutterManager;
