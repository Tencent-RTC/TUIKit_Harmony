import { ContactInfo } from '@tencentcloud/atomicxcore';

export default class ContactArrayDataSource implements IDataSource {
  private dataSet: ContactInfo[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(data: ContactInfo[] = []) {
    if (data.length > 0) {
      this.dataSet = data.slice();
    }
  }

  totalCount(): number {
    return this.dataSet.length;
  }

  getData(index: number): ContactInfo {
    if (index < 0 || index >= this.dataSet.length) {
      return new ContactInfo('');
    }
    return this.dataSet[index];
  }

  updateData(newData: ContactInfo[]): void {
    this.dataSet = newData.slice();
    this.notifyDataReload();
  }

  getRawData(): ContactInfo[] {
    return this.dataSet.slice();
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  private notifyDataReload(): void {
    this.listeners.forEach((listener) => {
      listener.onDataReloaded();
    });
  }
}