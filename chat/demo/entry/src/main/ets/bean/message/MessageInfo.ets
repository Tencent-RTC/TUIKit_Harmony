/**
 * 消息中心列表单条数据（对齐 Android `MessageInfo`）。
 */
export class MessageInfo {
  /** 消息正文摘要 */
  content: string = '';
  /** 内容类型 */
  contentType: string = '';
  /** 创建时间，如 yyyy-MM-dd HH:mm:ss */
  createTime: string = '';
  /** 是否已删除标记 */
  delFlag: boolean = false;
  /** 消息唯一 id */
  id: string = '';
  /** 是否重要消息 */
  isImportant: boolean = false;
  /** 是否已读（列表未读红点依据此字段） */
  isRead: boolean = false;
  /** 标题 */
  title: string = '';
  /** 消息类型 */
  type: string = '';
  /** 类型编码 */
  typeCode: string = '';
  /** 更新时间 */
  updateTime: string = '';
  /** 业务类型：COUPON / TRAVEL / ORDER，用于列表图标 */
  bizType: string = '';
}
