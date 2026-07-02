import { Prompt } from '@kit.ArkUI';
import { JumpActionBean } from '../bean/message/JumpActionBean';
import { MessageConstants } from '../utils/MessageConstants';
import { HMFlutterManager } from './HMFlutterManager';

const TAG = 'MessageNavigatorManager';

/**
 * 消息详情「查看详情」按钮的页面跳转（对齐 Android `AppNavigatorManager` 的 Flutter 分支）。
 * 咨询类按钮不在此处理，由 MessageDetailPage 直接 Toast。
 */
export class MessageNavigatorManager {
  /**
   * 根据服务端下发的 target 打开对应业务页。
   * @param target 动作目标，见 MessageConstants.TARGET_*
   * @param params 原始 params 对象，内部会解析为 JumpActionBean
   */
  static handleAction(target: string, params?: Record<string, Object>): void {
    if (!target || target.length === 0) {
      console.warn(`${TAG} handleAction: empty target`);
      return;
    }

    const jump = MessageNavigatorManager.parseJumpParams(params);
    switch (target) {
      case MessageConstants.TARGET_ORDER_INFO:
        MessageNavigatorManager.openOrderDetail(jump?.id ?? '');
        break;
      case MessageConstants.TARGET_TRAVEL_INFO:
        MessageNavigatorManager.openTravelDetail(jump?.id ?? '');
        break;
      case MessageConstants.TARGET_COUPON_LIST:
        HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_COUPON);
        break;
      case MessageConstants.TARGET_COUPON_INFO:
        MessageNavigatorManager.openCouponDetail(jump);
        break;
      default:
        console.warn(`${TAG} Unknown target: ${target}`);
        break;
    }
  }

  /** 将 params Map 解析为 JumpActionBean */
  private static parseJumpParams(params?: Record<string, Object>): JumpActionBean | null {
    if (!params) {
      return null;
    }
    const bean = new JumpActionBean();
    const idVal = params['id'];
    const typeVal = params['couponType'];
    bean.id = typeof idVal === 'string' ? idVal : '';
    bean.couponType = typeof typeVal === 'string' ? typeVal : '';
    return bean;
  }

  /** 打开 Flutter 行程详情 */
  private static openTravelDetail(bookId: string): void {
    if (!bookId || bookId.length === 0) {
      Prompt.showToast({ message: 'bookId 为空' });
      return;
    }
    const args: Record<string, Object> = { 'bookId': bookId };
    HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_TRAVELDETAIL, args);
  }

  /** 打开 Flutter 订单详情 */
  private static openOrderDetail(orderId: string): void {
    if (!orderId || orderId.length === 0) {
      Prompt.showToast({ message: 'orderId 为空' });
      return;
    }
    const args: Record<string, Object> = { 'orderId': orderId };
    HMFlutterManager.openFlutter(HMFlutterManager.FLUTTER_ROUTER_ORDER_DETAIL, args);
  }

  /** 打开 Flutter 优惠券详情 */
  private static openCouponDetail(jump: JumpActionBean | null): void {
    const couponId = jump?.id ?? '';
    if (!couponId || couponId.length === 0) {
      Prompt.showToast({ message: 'couponId 为空' });
      return;
    }
    let couponTypeCode = 0;
    const rawType = jump?.couponType ?? '';
    if (rawType.length > 0) {
      const parsed = parseInt(rawType, 10);
      if (!Number.isNaN(parsed)) {
        couponTypeCode = parsed;
      }
    }
    const args: Record<string, Object> = {
      'couponId': couponId,
      'couponType': couponTypeCode,
      'fromCouponDetail': false,
    };
    HMFlutterManager.openFlutter(HMFlutterManager.MINE_COUPON_DETAIL, args);
  }
}
