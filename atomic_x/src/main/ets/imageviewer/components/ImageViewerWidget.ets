import { ImageViewer, ImageElement, EventHandler } from './ImageViewer';

@Component
export struct ImageViewerWidget {
  imageElements: ImageElement[] = [];
  initialIndex: number = 0;
  onClose?: () => void;
  onEventTriggered?: (eventData: Record<string, Object>, callback: (result: Object) => void) => void;

  @State _currentIndex: number = 0;
  @State _isImageZoomed: boolean = false;
  @State _imageElements: ImageElement[] = [];
  @State _isUpdatingData: boolean = false;

  private _swiperController: SwiperController = new SwiperController();
  private _previousIndex: number = 0;
  private _isLoadingOlder: boolean = false;
  private _isLoadingNewer: boolean = false;

  aboutToAppear() {
    this._imageElements = [...this.imageElements];
    this._currentIndex = Math.max(0, Math.min(this.initialIndex, this._imageElements.length - 1));
    this._previousIndex = this._currentIndex;
  }

  aboutToDisappear() {
  }

  private _onLoadMore(isOlder: boolean, completion: (elements: ImageElement[], hasMoreData: boolean) => void) {
    if (this.onEventTriggered) {
      this.onEventTriggered({
        'event': 'onLoadMore',
        'param': { 'isOlder': isOlder } as Record<string, Object>
      } as Record<string, Object>, (result: Object) => {
        if (result && typeof result === 'object') {
          const resultMap = result as Record<string, Object>;
          const elements = (resultMap['elements'] ?? []) as ImageElement[];
          const hasMoreData = (resultMap['hasMoreData'] ?? false) as boolean;
          completion(elements, hasMoreData);
        } else {
          completion([], false);
        }
      });
    }
  }

  private _handleIndexChange(newIndex: number) {
    this._checkIfLoadMore(newIndex, this._previousIndex);
    this._previousIndex = newIndex;
  }

  private _checkIfLoadMore(newIndex: number, previousIndex: number) {
    const preloadThreshold = 1;
    const isSwipingLeft = newIndex < previousIndex;
    const isSwipingRight = newIndex > previousIndex;

    if (newIndex < preloadThreshold && isSwipingLeft && !this._isLoadingOlder) {
      this._isLoadingOlder = true;
      this._onLoadMore(true, (newElementsData: ImageElement[], _hasMore: boolean) => {
        this._handleLoadMoreResponse(newElementsData, true);
      });
    } else if (newIndex >= (this._imageElements.length - preloadThreshold) && isSwipingRight &&
      !this._isLoadingNewer) {
      this._isLoadingNewer = true;
      this._onLoadMore(false, (newElementsData: ImageElement[], _hasMore: boolean) => {
        this._handleLoadMoreResponse(newElementsData, false);
      });
    }
  }

  private _handleLoadMoreResponse(newElementsData: ImageElement[], isOlder: boolean) {
    if (newElementsData.length > 0) {
      this._updateImageElements(newElementsData, isOlder);
    }
    if (isOlder) {
      this._isLoadingOlder = false;
    } else {
      this._isLoadingNewer = false;
    }
  }

  private _updateImageElements(newElements: ImageElement[], _isOlder: boolean) {
    this._isUpdatingData = true;
    const currentElement = this._imageElements[this._currentIndex];
    const currentElementSignature = this._getElementSignature(currentElement);
    this._imageElements = newElements;
    const newIndex = this._findElementIndex(newElements, currentElementSignature);
    if (newIndex !== -1) {
      this._currentIndex = newIndex;
    } else {
      this._currentIndex = Math.max(0, Math.min(this._currentIndex, this._imageElements.length - 1));
    }
    this._isUpdatingData = false;
  }

  private _getElementSignature(element: ImageElement): string {
    return `${element.type}_${element.data}`;
  }

  private _findElementIndex(elements: ImageElement[], signature: string): number {
    for (let i = 0; i < elements.length; i++) {
      if (this._getElementSignature(elements[i]) === signature) {
        return i;
      }
    }
    return -1;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)

      if (this._imageElements.length === 0) {
        Column() {
          Text('暂无图片')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this._isUpdatingData && this._currentIndex < this._imageElements.length) {
        this._buildMediaItem(this._imageElements[this._currentIndex])
      } else {
        Swiper(this._swiperController) {
          ForEach(this._imageElements, (element: ImageElement, index: number) => {
            this._buildMediaItem(element)
          }, (element: ImageElement, index: number) => {
            return `${index}_${element.type}_${element.data}`;
          })
        }
        .index(this._currentIndex)
        .loop(false)
        .indicator(this._imageElements.length > 1)
        .duration(300)
        .disableSwipe(this._isImageZoomed)
        .onChange((index: number) => {
          this._currentIndex = index;
          this._isImageZoomed = false;
          this._handleIndexChange(index);
        })
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private _buildMediaItem(element: ImageElement) {
    ImageViewer({
      imageElement: element,
      onZoomChanged: (isZoomed: boolean) => {
        if (this._isImageZoomed !== isZoomed) {
          this._isImageZoomed = isZoomed;
        }
      },
      onClose: () => {
        if (this.onClose) {
          this.onClose();
        }
      }
    })
  }
}

@CustomDialog
export struct ImageViewerWidgetDialog {
  controller: CustomDialogController;
  imageElements: ImageElement[] = [];
  initialIndex: number = 0;
  onDialogClose?: () => void;
  onEventTriggered?: (eventData: Record<string, Object>, callback: (result: Object) => void) => void;

  build() {
    ImageViewerWidget({
      imageElements: this.imageElements,
      initialIndex: this.initialIndex,
      onEventTriggered: this.onEventTriggered,
      onClose: () => {
        this.controller.close();
        if (this.onDialogClose) {
          this.onDialogClose();
        }
      }
    })
  }
}