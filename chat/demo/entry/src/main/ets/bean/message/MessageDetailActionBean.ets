/**
 * 消息详情底部操作按钮数据（对齐 Android `MessageDetailActionBean`）。
 */
export class MessageDetailActionBean {
  /** 按钮展示文案，如「查看详情」「咨询」 */
  name: string = '';
  /** 跳转参数，结构随 target 不同而变化 */
  params?: Record<string, Object>;
  /** 动作目标，见 {@link MessageConstants} 中 TARGET_* */
  target: string = '';
  /** 动作类型，如 NATIVE */
  type: string = '';
}
