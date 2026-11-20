import { BasicData, BasicDataSource } from '@tencentcloud/atomicxcore'

export class RoomDataObserver implements DataChangeListener {
  private onChange: () => void

  constructor(onChange: () => void) {
    this.onChange = onChange
  }

  static observe<T extends BasicData>(source: BasicDataSource<T>, onChange: () => void): () => void {
    const observer = new RoomDataObserver(onChange)
    source.registerDataChangeListener(observer)
    return () => source.unregisterDataChangeListener(observer)
  }

  onDataReloaded(): void { this.onChange() }
  onDataAdded(index: number): void { this.onChange() }
  onDataAdd(index: number): void { this.onChange() }
  onDataMoved(from: number, to: number): void { this.onChange() }
  onDataMove(from: number, to: number): void { this.onChange() }
  onDataDeleted(index: number): void { this.onChange() }
  onDataDelete(index: number): void { this.onChange() }
  onDataChanged(index: number): void { this.onChange() }
  onDataChange(index: number): void { this.onChange() }
  onDatasetChange(dataOperations: DataOperation[]): void { this.onChange() }
}
