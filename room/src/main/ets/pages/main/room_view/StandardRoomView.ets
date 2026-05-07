import {
  RoomParticipant,
  RoomParticipantStore,
  RoomParticipantState,
} from '@tencentcloud/atomicxcore';
import { RoomImages } from '../../../base/resources/RoomImages';
import { ParticipantLayoutView } from './ParticipantLayoutView';

class PageIndexDataSource implements IDataSource {
  private items: number[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): number {
    return this.items[index];
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

  reload(data: number[]): void {
    this.items = data;
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }
}

@Component
export struct StandardRoomView {
  roomId: string = '';

  private static readonly ITEMS_PER_PAGE: number = 6;

  @State private participantState: RoomParticipantState = new RoomParticipantState();
  @State private currentPageIndex: number = 0;
  private lastHasScreenShare: boolean = false;
  private lastTotalPageCount: number = 1;
  private pageDataSource: PageIndexDataSource = new PageIndexDataSource();

  private swiperController: SwiperController = new SwiperController();

  private participantListListener: DataChangeListener = {
    onDataReloaded: () => {
      this.onParticipantDataChanged();
    },
    onDataAdd: () => {
      this.onParticipantDataChanged();
    },
    onDataChange: () => {
      this.onParticipantDataChanged();
    },
    onDataDelete: () => {
      this.onParticipantDataChanged();
    },
    onDataMove: () => {
      this.onParticipantDataChanged();
    },
    onDataAdded: () => {
      this.onParticipantDataChanged();
    },
    onDataChanged: () => {
      this.onParticipantDataChanged();
    },
    onDataDeleted: () => {
      this.onParticipantDataChanged();
    },
    onDataMoved: () => {
      this.onParticipantDataChanged();
    },
    onDatasetChange: () => {
      this.onParticipantDataChanged();
    },
  };

  aboutToAppear(): void {
    this.participantState = RoomParticipantStore.create(this.roomId).state;
    this.lastHasScreenShare = this.hasScreenShare();
    this.lastTotalPageCount = this.getTotalPageCount();
    this.pageDataSource.reload(this.buildPageIndices());
    this.participantState.participantList.registerDataChangeListener(this.participantListListener);
  }

  aboutToDisappear(): void {
    this.participantState.participantList.unregisterDataChangeListener(this.participantListListener);
  }

  build() {
    Stack() {
      this.buildPageView()
      this.buildNavigationArrows()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildPageView() {
    Column() {
      Swiper(this.swiperController) {
        LazyForEach(
          this.pageDataSource,
          (pageIndex: number) => {
            this.buildPage(pageIndex)
          },
          (pageIndex: number) => `page_${pageIndex}`
        )
      }
      .cachedCount(1)
      .index(this.getAdjustedPageIndex())
      .indicator(false)
      .loop(false)
      .onChange((index: number) => {
        this.currentPageIndex = index;
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildPage(pageIndex: number) {
    ParticipantLayoutView({
      roomId: this.roomId,
      participants: this.getAllParticipants(),
      startIndex: this.getPageStartIndex(pageIndex),
      endIndex: this.getPageEndIndex(pageIndex),
      currentPageIndex: pageIndex,
      isScreenLayout: this.isScreenLayout(pageIndex),
      screenParticipant: this.participantState.participantWithScreen,
    })
  }

  @Builder
  private buildNavigationArrows() {
    if (this.getTotalPageCount() > 1) {
      Row() {
        if (this.currentPageIndex > 0) {
          Image(RoomImages.arrowLeft)
            .width(24)
            .height(24)
            .onClick(() => {
              // this.swiperController.showPrevious();
            })
        } else {
          Column()
            .width(24)
            .height(24)
        }

        Blank().layoutWeight(1)

        if (this.currentPageIndex < this.getTotalPageCount() - 1) {
          Image(RoomImages.arrowRight)
            .width(24)
            .height(24)
            .onClick(() => {
              // this.swiperController.showNext();
            })
        } else {
          Column()
            .width(24)
            .height(24)
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
  }

  private onParticipantDataChanged(): void {
    const newTotalPageCount = this.getTotalPageCount();
    if (newTotalPageCount !== this.lastTotalPageCount) {
      this.lastTotalPageCount = newTotalPageCount;
      if (this.currentPageIndex >= newTotalPageCount) {
        this.currentPageIndex = Math.max(0, newTotalPageCount - 1);
      }
      this.pageDataSource.reload(this.buildPageIndices());
    }
  }

  private getAllParticipants(): RoomParticipant[] {
    return this.participantState.participantList.toArray();
  }

  private getAdjustedPageIndex(): number {
    const currentHasScreen = this.hasScreenShare();
    if (currentHasScreen !== this.lastHasScreenShare) {
      this.lastHasScreenShare = currentHasScreen;
      const newTotalPageCount = this.getTotalPageCount();
      if (newTotalPageCount !== this.lastTotalPageCount) {
        this.lastTotalPageCount = newTotalPageCount;
        this.pageDataSource.reload(this.buildPageIndices());
      }
      if (currentHasScreen) {
        this.currentPageIndex = 0;
        return 0;
      } else {
        const adjusted = Math.max(0, this.currentPageIndex - 1);
        this.currentPageIndex = adjusted;
        return adjusted;
      }
    }
    return this.currentPageIndex;
  }

  private hasScreenShare(): boolean {
    return this.participantState.participantWithScreen !== undefined;
  }

  private isScreenLayout(pageIndex: number): boolean {
    return this.hasScreenShare() && pageIndex === 0;
  }

  private getTotalPageCount(): number {
    const participantCount = this.participantState.participantList.totalCount();
    const hasScreen = this.hasScreenShare();
    const count = hasScreen
      ? Math.ceil(participantCount / StandardRoomView.ITEMS_PER_PAGE) + 1
      : Math.ceil(participantCount / StandardRoomView.ITEMS_PER_PAGE);
    return count > 0 ? count : 1;
  }

  private buildPageIndices(): number[] {
    const total = this.getTotalPageCount();
    const indices: number[] = [];
    for (let i = 0; i < total; i++) {
      indices.push(i);
    }
    return indices;
  }

  private getPageStartIndex(pageIndex: number): number {
    const hasScreen = this.hasScreenShare();
    if (hasScreen) {
      return pageIndex === 0 ? 0 : (pageIndex - 1) * StandardRoomView.ITEMS_PER_PAGE;
    }
    return pageIndex * StandardRoomView.ITEMS_PER_PAGE;
  }

  private getPageEndIndex(pageIndex: number): number {
    const participantCount = this.participantState.participantList.totalCount();
    const startIndex = this.getPageStartIndex(pageIndex);
    const endIndex = startIndex + StandardRoomView.ITEMS_PER_PAGE - 1;
    return endIndex < participantCount ? endIndex : participantCount - 1;
  }
}
