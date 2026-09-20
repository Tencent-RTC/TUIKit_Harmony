import { MessageInfo } from '@tencentcloud/atomicxcore';

export class MessageInfoDataSource implements IDataSource {
  private messages: MessageInfo[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.messages.length;
  }

  getData(index: number): MessageInfo {
    return this.messages[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  setMessages(messages: MessageInfo[]): void {
    this.messages = Array.from(messages);
    this.listeners.forEach((listener: DataChangeListener) => listener.onDataReloaded());
  }

  forceRefresh(index: number): void {
    if (index < 0 || index >= this.messages.length) {
      return;
    }
    this.listeners.forEach((listener: DataChangeListener) => listener.onDataChange(index));
  }

  getIndex(msgID: string): number {
    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].msgID === msgID) {
        return i;
      }
    }
    return -1;
  }
}
