/**
 * 消息中心网络接口（对齐 Android `MessageCenterApi`）。
 */
import { MessageDetailBean } from '../bean/message/MessageDetailBean';
import { MessageResponse } from '../bean/message/MessageResponse';
import { http } from '../network';

/** 消息列表查询参数，对应 GET /api/v1/msg/list 的 query */
export interface MessageListQuery {
  /** 当前页码，从 1 开始 */
  pageNum: number;
  /** 每页条数 */
  pageSize: number;
  /** 搜索关键字，空字符串表示不过滤 */
  keyword: string;
}

/**
 * 拉取消息中心分页列表。
 * @param query 分页与搜索条件
 * @returns 含 list / total 等字段的分页数据（Http 拦截器已解包 data）
 */
export const getMessageList = (query: MessageListQuery): Promise<MessageResponse> => {
  const params: MessageListQuery = {
    pageNum: query.pageNum,
    pageSize: query.pageSize,
    keyword: query.keyword,
  };
  return http.get<MessageResponse>('/api/v1/msg/list', params);
};

/**
 * 拉取单条消息详情（进入详情页时调用，服务端通常会标记已读）。
 * @param msgId 消息 id
 */
export const getMessageDetail = (msgId: string): Promise<MessageDetailBean> => {
  return http.get<MessageDetailBean>(`/api/v1/msg/${msgId}`);
};

/**
 * 删除单条消息（列表左滑删除确认后调用）。
 * @param msgId 消息 id
 */
export const deleteMessage = (msgId: string): Promise<Object | null> => {
  return http.delete<Object | null>(`/api/v1/msg/${msgId}`);
};
