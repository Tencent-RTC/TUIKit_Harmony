import { MessageDetailActionBean } from './MessageDetailActionBean';

/**
 * 消息详情接口响应体（对齐 Android `MessageDetailBean`）。
 */
export class MessageDetailBean {
  /** 底部操作按钮列表，如「查看详情」「咨询」 */
  action: MessageDetailActionBean[] = [];
  /** 业务类型 */
  bizType: string = '';
  /** 详情正文 */
  content: string = '';
  /** 创建时间 */
  createTime: string = '';
  /** 消息 id */
  id: string = '';
  /** 是否已读：服务端为 number，1 表示已读 */
  isRead: number = 0;
  /** 标题 */
  title: string = '';
}
