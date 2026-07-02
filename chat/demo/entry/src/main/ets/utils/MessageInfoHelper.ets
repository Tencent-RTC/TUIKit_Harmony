import { MessageInfo } from '../bean/message/MessageInfo';

/**
 * 消息列表数据归一化与本地已读同步。
 * 解决接口 id 可能为 number、isRead 可能为 0/1 导致的比较与 UI 刷新问题。
 */
export class MessageInfoHelper {
  /** 将消息 id 统一转为字符串，便于与路由参数比较 */
  static normalizeId(id: string | number | undefined): string {
    if (id === undefined || id === null) {
      return '';
    }
    return `${id}`;
  }

  /**
   * 判断是否已读（兼容 boolean 与 0/1）。
   * @param isRead 接口或模型中的 isRead 字段
   */
  static isMessageRead(isRead: boolean | number | undefined): boolean {
    return isRead === true || isRead === 1;
  }

  /**
   * 将接口返回的列表项转为规范的 MessageInfo 实例。
   * @param raw 接口 JSON 反序列化后的对象
   */
  static normalize(raw: MessageInfo): MessageInfo {
    const item = new MessageInfo();
    item.content = raw.content ?? '';
    item.contentType = raw.contentType ?? '';
    item.createTime = raw.createTime ?? '';
    item.delFlag = raw.delFlag === true;
    item.id = MessageInfoHelper.normalizeId(raw.id);
    item.isImportant = raw.isImportant === true;
    item.isRead = MessageInfoHelper.isMessageRead(raw.isRead);
    item.title = raw.title ?? '';
    item.type = raw.type ?? '';
    item.typeCode = raw.typeCode ?? '';
    item.updateTime = raw.updateTime ?? '';
    item.bizType = raw.bizType ?? '';
    return item;
  }

  /**
   * 本地将指定消息标为已读，并返回全新数组以触发 @State / ForEach 刷新。
   * @param list  当前列表
   * @param msgId 已读消息 id
   */
  static markAsRead(list: MessageInfo[], msgId: string): MessageInfo[] {
    const targetId = MessageInfoHelper.normalizeId(msgId);
    if (targetId.length === 0) {
      return list;
    }
    return list.map((item: MessageInfo) => {
      const copy = MessageInfoHelper.normalize(item);
      if (MessageInfoHelper.normalizeId(copy.id) === targetId) {
        copy.isRead = true;
      }
      return copy;
    });
  }

  /**
   * 生成 ForEach 唯一 key。
   * id 相同但 isRead 变化时必须变更 key，否则列表项不会重绘、红点不消失。
   */
  static listItemKey(message: MessageInfo): string {
    return `${MessageInfoHelper.normalizeId(message.id)}_${message.isRead ? 1 : 0}`;
  }
}
