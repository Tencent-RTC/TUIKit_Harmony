import { matrix4, window } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';

export interface EventHandler {
  onEvent(eventData: Record<string, Object>, callback: (result: Object) => void): void;
}

export interface ImageElement {
  data: string;
  type: number;
  width: number;
  height: number;
}

export enum ImageSourceType {
  URL = 0,
  LOCAL = 1
}

class ScaleModel {
  scaleValue: number;
  lastValue: number;
  maxScaleValue: number;
  extraScaleValue: number;
  readonly defaultScaleValue: number = 1;

  constructor(scaleValue: number = 1.0, lastValue: number = 1.0,
    maxScaleValue: number = 2.5, extraScaleValue: number = 0.3) {
    this.scaleValue = scaleValue;
    this.lastValue = lastValue;
    this.maxScaleValue = maxScaleValue;
    this.extraScaleValue = extraScaleValue;
  }

  reset(): void {
    this.scaleValue = this.defaultScaleValue;
    this.lastValue = this.scaleValue;
  }

  stash(): void {
    this.lastValue = this.scaleValue;
  }
}

class OffsetModel {
  currentX: number;
  currentY: number;
  lastX: number = 0;
  lastY: number = 0;

  constructor(currentX: number = 0, currentY: number = 0) {
    this.currentX = currentX;
    this.currentY = currentY;
  }

  reset(): void {
    this.currentX = 0;
    this.currentY = 0;
    this.lastX = 0;
    this.lastY = 0;
  }

  stash(): void {
    this.lastX = this.currentX;
    this.lastY = this.currentY;
  }
}

function runWithAnimation(
  fn: Function,
  duration: number = 300,
  curve: Curve = Curve.Smooth): void {
  animateTo({ duration: duration, curve: curve }, () => {
    fn();
  })
}

@Component
export struct ImageViewer {
  imageElement?: ImageElement;
  onClose?: () => void;
  onZoomChanged?: (isZoomed: boolean) => void;

  @State private scaleInfo: ScaleModel = new ScaleModel(1.0, 1.0, 2.5, 0.3);
  @State private offsetInfo: OffsetModel = new OffsetModel(0, 0);
  @State private matrix: matrix4.Matrix4Transit = matrix4.identity().copy();
  @State private fitWH: "width" | "height" | undefined = undefined;
  @State private imageDefaultSize: image.Size = { width: 0, height: 0 };
  @State private panDirection: PanDirection = PanDirection.None;

  private imageWHRatio: number = 0;
  private windowSize: window.Size = { width: 0, height: 0 };

  aboutToAppear(): void {
    window.getLastWindow(getContext()).then((value: window.Window) => {
      const rect: window.Rect = value.getWindowProperties().windowRect;
      this.windowSize.width = px2vp(rect.width);
      this.windowSize.height = px2vp(rect.height);
    });
  }

  private handleScaleChange() {
    if (this.scaleInfo.scaleValue === this.scaleInfo.defaultScaleValue) {
      this.panDirection = PanDirection.None;
    } else {
      this.panDirection = PanDirection.All;
    }
    const isZoomed = this.scaleInfo.scaleValue > this.scaleInfo.defaultScaleValue + 0.01;
    if (this.onZoomChanged) {
      this.onZoomChanged(isZoomed);
    }
  }

  private calcImageDefaultSize(ratio: number, size: window.Size): image.Size {
    let w = 0;
    let h = 0;
    if (ratio > size.width / size.height) {
      w = size.width;
      h = size.width / ratio;
    } else {
      h = size.height;
      w = size.height * ratio;
    }
    return { width: w, height: h };
  }

  private calcFitScaleRatio(imageSize: image.Size, windowSize: window.Size): number {
    let ratio: number = 1.0;
    if (windowSize.width > imageSize.width) {
      ratio = windowSize.width / imageSize.width;
    } else {
      ratio = windowSize.height / imageSize.height;
    }
    return ratio;
  }

  private initCurrentImageInfo(width: number, height: number): void {
    if (width <= 0 || height <= 0) {
      return;
    }
    this.matrix = matrix4.identity().copy();
    this.imageWHRatio = width / height;
    this.imageDefaultSize = this.calcImageDefaultSize(this.imageWHRatio, this.windowSize);
    if (this.imageDefaultSize.width === this.windowSize.width) {
      this.fitWH = "width";
    } else {
      this.fitWH = "height";
    }
    this.scaleInfo.maxScaleValue = 2.5;
    this.scaleInfo.maxScaleValue += this.fitWH === "width" ?
      (this.windowSize.height / this.imageDefaultSize.height) :
      (this.windowSize.width / this.imageDefaultSize.width);
    this.scaleInfo.reset();
    this.offsetInfo.reset();
  }

  private resetCurrentImageInfo(): void {
    this.scaleInfo.reset();
    this.offsetInfo.reset();
    this.matrix = matrix4.identity().copy();
    this.handleScaleChange();
  }

  private evaluateBound(): void {
    const leftEdge = this.imageDefaultSize.width * this.scaleInfo.scaleValue / 2 - this.windowSize.width / 2;
    this.offsetInfo.currentX = this.offsetInfo.currentX > leftEdge ? leftEdge : this.offsetInfo.currentX;

    const rightEdge = this.windowSize.width / 2 - this.imageDefaultSize.width * this.scaleInfo.scaleValue / 2;
    this.offsetInfo.currentX = this.offsetInfo.currentX < rightEdge ? rightEdge : this.offsetInfo.currentX;

    if (this.imageDefaultSize.height * this.scaleInfo.scaleValue > this.windowSize.height) {
      const topEdge = this.imageDefaultSize.height * this.scaleInfo.scaleValue / 2 - this.windowSize.height / 2;
      this.offsetInfo.currentY = this.offsetInfo.currentY > topEdge ? topEdge : this.offsetInfo.currentY;

      const bottomEdge = this.windowSize.height / 2 - this.imageDefaultSize.height * this.scaleInfo.scaleValue / 2;
      this.offsetInfo.currentY = this.offsetInfo.currentY < bottomEdge ? bottomEdge : this.offsetInfo.currentY;
    }
  }

  private getDisplayImageSource(): string | Resource {
    if (!this.imageElement) {
      return '';
    }
    return this.imageElement.data;
  }

  build() {
    Stack() {
      Image(this.getDisplayImageSource())
        .width(this.fitWH === "width" ? '100%' : undefined)
        .height(this.fitWH === "height" ? '100%' : undefined)
        .aspectRatio(this.imageWHRatio > 0 ? this.imageWHRatio : undefined)
        .objectFit(ImageFit.Cover)
        .autoResize(false)
        .transform(this.matrix)
        .defaultFocus(true)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .offset({
          x: this.offsetInfo.currentX,
          y: this.offsetInfo.currentY
        })
        .onComplete((event) => {
          this.initCurrentImageInfo(event?.width ?? 0, event?.height ?? 0);
        })
    }
    .backgroundColor(Color.Black)
    .alignContent(Alignment.Center)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .clip(true)
    .width('100%')
    .height('100%')
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        TapGesture({ count: 2 })
          .onAction(() => {
            let fn: Function;
            if (this.scaleInfo.scaleValue > this.scaleInfo.defaultScaleValue) {
              fn = () => {
                this.scaleInfo.reset();
                this.offsetInfo.reset();
                this.matrix = matrix4.identity().copy();
                this.handleScaleChange();
              };
            } else {
              fn = () => {
                const ratio: number = this.calcFitScaleRatio(this.imageDefaultSize, this.windowSize);
                this.scaleInfo.scaleValue = ratio;
                this.offsetInfo.reset();
                this.matrix = matrix4.identity().scale({
                  x: ratio,
                  y: ratio,
                }).copy();
                this.scaleInfo.stash();
                this.handleScaleChange();
              };
            }
            runWithAnimation(fn);
          }),
        TapGesture({ count: 1 })
          .onAction(() => {
            if (this.scaleInfo.scaleValue <= this.scaleInfo.defaultScaleValue + 0.01) {
              if (this.onClose) {
                this.onClose();
              }
            }
          }),
        PinchGesture({ fingers: 2, distance: 1 })
          .onActionUpdate((event: GestureEvent) => {
            this.scaleInfo.scaleValue = this.scaleInfo.lastValue * event.scale;
            if (this.scaleInfo.scaleValue > this.scaleInfo.maxScaleValue *
              (1 + this.scaleInfo.extraScaleValue)) {
              this.scaleInfo.scaleValue = this.scaleInfo.maxScaleValue *
                (1 + this.scaleInfo.extraScaleValue);
            }
            if (this.scaleInfo.scaleValue < this.scaleInfo.defaultScaleValue *
              (1 - this.scaleInfo.extraScaleValue)) {
              this.scaleInfo.scaleValue = this.scaleInfo.defaultScaleValue *
                (1 - this.scaleInfo.extraScaleValue);
            }
            this.matrix = matrix4.identity().scale({
              x: this.scaleInfo.scaleValue,
              y: this.scaleInfo.scaleValue,
            }).copy();
            this.handleScaleChange();
          })
          .onActionEnd(() => {
            if (this.scaleInfo.scaleValue < this.scaleInfo.defaultScaleValue) {
              runWithAnimation(() => {
                this.scaleInfo.reset();
                this.offsetInfo.reset();
                this.matrix = matrix4.identity().copy();
                this.handleScaleChange();
              });
            }
            if (this.scaleInfo.scaleValue > this.scaleInfo.maxScaleValue) {
              runWithAnimation(() => {
                this.scaleInfo.scaleValue = this.scaleInfo.maxScaleValue;
                this.matrix = matrix4.identity().scale({
                  x: this.scaleInfo.maxScaleValue,
                  y: this.scaleInfo.maxScaleValue
                }).copy();
                this.handleScaleChange();
              });
            }
            this.scaleInfo.stash();
            runWithAnimation(() => {
              this.evaluateBound();
            });
          }),
        PanGesture({ fingers: 1, direction: this.panDirection })
          .onActionUpdate((event: GestureEvent) => {
            if (this.scaleInfo.scaleValue === this.scaleInfo.defaultScaleValue) {
              return;
            }
            this.offsetInfo.currentX = this.offsetInfo.lastX + event.offsetX;
            if (this.imageDefaultSize.height * this.scaleInfo.scaleValue > this.windowSize.height) {
              this.offsetInfo.currentY = this.offsetInfo.lastY + event.offsetY;
            }
            this.evaluateBound();
          })
          .onActionEnd(() => {
            this.evaluateBound();
            this.offsetInfo.stash();
          })
      ),
    )
  }
}

@CustomDialog
export struct ImageViewerDialog {
  controller: CustomDialogController;
  imageElement?: ImageElement;
  onDialogClose?: () => void;

  build() {
    ImageViewer({
      imageElement: this.imageElement,
      onClose: () => {
        this.controller.close();
        if (this.onDialogClose) {
          this.onDialogClose();
        }
      }
    })
  }
}