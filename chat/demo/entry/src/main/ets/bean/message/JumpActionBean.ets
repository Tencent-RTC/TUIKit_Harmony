/**
 * 消息详情「查看详情」类操作的跳转参数（对齐 Android `JumpActionBean`）。
 * 用于订单 / 行程 / 优惠券等 target 的 params 解析。
 */
export class JumpActionBean {
  /** 业务 id：订单 id、行程 bookId、优惠券 id 等 */
  id: string = '';
  /** 优惠券类型：0 公券，1 私券（字符串形式，需 parseInt） */
  couponType: string = '';
}
