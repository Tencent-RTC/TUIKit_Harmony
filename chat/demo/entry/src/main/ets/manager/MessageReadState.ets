/**
 * 详情页返回列表时的「待同步已读」暂存。
 *
 * 背景：router.back + onPageShow + getParams 在部分时机下拿不到 readMsgId，
 * 与 MessageCenterPage.lastOpenedMsgId 配合，保证返回后红点能及时消失。
 */
export class MessageReadState {
  /** 待同步到列表的已读消息 id（单次消费） */
  private static pendingReadMsgId: string = '';

  /**
   * 详情页返回前写入待同步 id。
   * @param msgId 当前查看的消息 id
   */
  static setPendingRead(msgId: string): void {
    MessageReadState.pendingReadMsgId = msgId;
  }

  /**
   * 列表页 onPageShow 时取出并清空，避免重复消费。
   * @returns 待同步的 msgId，无则返回空字符串
   */
  static consumePendingRead(): string {
    const id = MessageReadState.pendingReadMsgId;
    MessageReadState.pendingReadMsgId = '';
    return id;
  }
}
