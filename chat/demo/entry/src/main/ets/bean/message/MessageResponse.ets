import { MessageInfo } from './MessageInfo';

/**
 * 消息列表分页接口响应体（对齐 Android `MessageResponse`）。
 */
export class MessageResponse {
  /** 符合条件的消息总数 */
  total: number = 0;
  /** 当前页码 */
  pageNum: number = 0;
  /** 每页大小 */
  pageSize: number = 0;
  /** 当前页消息列表 */
  list: MessageInfo[] = [];
}
