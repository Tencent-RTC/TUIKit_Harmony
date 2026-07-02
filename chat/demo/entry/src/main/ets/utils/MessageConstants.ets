/**
 * 消息模块常量（对齐 Android `Constants.MessageCenter`）。
 */
export class MessageConstants {
  /** 跳转订单详情 */
  static readonly TARGET_ORDER_INFO = 'order_info';
  /** 跳转行程详情 */
  static readonly TARGET_TRAVEL_INFO = 'travel_info';
  /** 跳转优惠券列表 */
  static readonly TARGET_COUPON_LIST = 'coupon_list';
  /** 跳转优惠券详情 */
  static readonly TARGET_COUPON_INFO = 'coupon_info';
  /** 创建会话（鸿蒙侧仅 Toast，不实现） */
  static readonly TARGET_CREATE_SESSION = 'create_session';
  /** 进入已有会话（鸿蒙侧仅 Toast，不实现） */
  static readonly TARGET_ENTER_SESSION = 'enter_session';

  /** 列表默认每页条数（对齐 Android `PagerConfig.DEFAULT_PAGE_SIZE`） */
  static readonly DEFAULT_PAGE_SIZE = 10;

  /**
   * 判断是否为「咨询」类底部按钮。
   * 鸿蒙详情页对咨询仅弹出「功能开发中」，不打开 IM 会话。
   * @param target 服务端下发的 target
   * @param name   按钮文案
   */
  static isConsultAction(target: string, name: string): boolean {
    if (name.indexOf('咨询') >= 0) {
      return true;
    }
    return target === MessageConstants.TARGET_CREATE_SESSION
      || target === MessageConstants.TARGET_ENTER_SESSION;
  }
}
