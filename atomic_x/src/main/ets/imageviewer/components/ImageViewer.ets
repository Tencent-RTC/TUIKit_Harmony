import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { ThemeState } from '../../basecomponent/Index';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

export interface EventHandler {
  onEvent(eventData: Record<string, Object>, callback: (result: Object) => void): void;
}

export interface ImageElement {
  data: string; // Image path or URL
  type: number; // 0 = image, 1 = video
  width: number;
  height: number;
}

export enum ImageSourceType {
  URL = 0, 
  LOCAL = 1 
}


@CustomDialog
export struct ImageViewerDialog {
  controller: CustomDialogController;
  imageElement?: ImageElement;
  onDialogClose?: () => void;

  aboutToAppear() {
    console.log('[ImageViewerDialog] aboutToAppear, imageElement:', this.imageElement);
  }

  build() {
    ImageViewer({
      imageElement: this.imageElement,
      onClose: () => {
        console.log('[ImageViewerDialog] onClose called');
        this.controller.close();
        if (this.onDialogClose) {
          this.onDialogClose();
        }
      }
    })
  }
}

@Component
export  struct ImageViewer {
  imageElement?: ImageElement;
  onClose?: () => void;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State localTempPath: string = '';
  @State currentScale: number = 1.0;
  @State centerX: number = 0;
  @State centerY: number = 0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    console.log('[ImageViewerComponent] aboutToAppear, imageElement:', this.imageElement);
    
    if (this.imageElement) {
      if (this.imageElement.type === ImageSourceType.URL) {
        console.log('[ImageViewerComponent] URL image, downloading...');
        // Download URL image
        this.downloadImage();
      } else {
        console.log('[ImageViewerComponent] Local image, ready to display');
        // Local image, ready to display
        this.isLoading = false;
      }
    } else {
      console.error('[ImageViewerComponent] No image data provided');
      this.hasError = true;
      this.errorMessage = 'No image data provided';
      this.isLoading = false;
    }
  }

  
  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeState.colors.textColorPrimary)

      Text('加载中...')
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorTertiary)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  
  @Builder
  ErrorStateBuilder() {
    Column() {
      
      Image($r('sys.media.ohos_app_icon'))
        .width(80)
        .height(80)
        .fillColor(this.themeState.colors.textColorTertiary)

      Text('loading error')
        .fontSize(18)
        .fontColor(this.themeState.colors.textColorTertiary)
        .margin({ top: 16 })

      Text(this.errorMessage)
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorTertiary)
        .margin({ top: 8 })

      Button('Retry')
        .margin({ top: 24 })
        .onClick(() => {
          this.isLoading = true;
          this.hasError = false;
          this.downloadImage();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Background
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')

      if (this.isLoading) {
        // Loading
        this.LoadingStateBuilder()
      } else if (this.hasError) {
        
        this.ErrorStateBuilder()
      } else {
        
        Column() {
          Image(this.getDisplayImagePath())
            .objectFit(ImageFit.Contain)
            .width('100%')
            .height('100%')
            .translate({ x: this.offsetX, y: this.offsetY })
            .scale({ x: this.currentScale, y: this.currentScale })
            .onComplete(() => {
              
              this.resetZoomAndPan();
            })
            .gesture(
              PinchGesture({ fingers: 2 })
                .onActionStart((event: GestureEvent) => {
                  
                  
                })
                .onActionUpdate((event: GestureEvent) => {
                  
                  const prevScale = this.currentScale;
                  const newScale = Math.max(1.0, Math.min(1.5, this.currentScale * event.scale));
                  this.currentScale = newScale;

                  
                  if (Math.abs(prevScale - newScale) > 0.01) {
                    
                    if (Math.abs(newScale - 1.0) < 0.05) {
                      
                      this.offsetX *= 0.5;
                      this.offsetY *= 0.5;
                    }
                  }
                })
                .onActionEnd(() => {
                  
                  if (Math.abs(this.currentScale - 1.0) < 0.05) {
                    this.currentScale = 1.0;
                    this.offsetX = 0;
                    this.offsetY = 0;
                  }
                  
                })
            )
            .gesture(
              PanGesture({ fingers: 1, direction: PanDirection.All })
                .onActionStart(() => {
                  
                })
                .onActionUpdate((event: GestureEvent) => {
                  
                  if (this.currentScale > 1.0) {
                    
                    const dampingFactor = 0.1; 
                    const deltaX = event.offsetX * dampingFactor;
                    const deltaY = event.offsetY * dampingFactor;

                    this.offsetX += deltaX;
                    this.offsetY += deltaY;

                    
                    const viewWidth = 390; 
                    const viewHeight = 640; 

                    
                    const maxOffsetX = (this.currentScale - 1.0) * viewWidth / 2;
                    const maxOffsetY = (this.currentScale - 1.0) * viewHeight / 2;

                    
                    this.offsetX = Math.max(-maxOffsetX, Math.min(maxOffsetX, this.offsetX));
                    this.offsetY = Math.max(-maxOffsetY, Math.min(maxOffsetY, this.offsetY));
                  }
                })
                .onActionEnd(() => {
                  
                  if (Math.abs(this.currentScale - 1.0) < 0.05) {
                    this.resetZoomAndPan();
                  }
                  
                })
            )
            .gesture(
              TapGesture({ count: 2 })
                .onAction(() => {
                  
                  if (Math.abs(this.currentScale - 1.0) < 0.1) {
                    this.currentScale = 1.5;
                    
                  } else {
                    this.resetZoomAndPan();
                  }
                })
            )
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      
      Column() {
        Row() {
          Button() {
            
            Image($r('sys.media.ohos_ic_back'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .borderRadius(24)
          .width(48)
          .height(48)
          .margin({ left: 16 })
          .onClick(() => this.closeViewer())
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .gesture(
      TapGesture()
        .onAction(() => {
          
          this.closeViewer();
        })
    )
  }

  private downloadImage() {
    if (!this.imageElement || !this.imageElement.data) {
      this.hasError = true;
      this.errorMessage = 'Image URL is empty';
      this.isLoading = false;
      return;
    }

    const imageUrl = this.imageElement.data;
    let httpRequest = http.createHttp();

    httpRequest.request(
      imageUrl,
      {
        method: http.RequestMethod.GET,
        readTimeout: 30000,
        connectTimeout: 30000
      },
      (err, data) => {
        if (err) {
          this.hasError = true;
          this.errorMessage = `Download failed: ${err.message}`;
          this.isLoading = false;
          return;
        }

        if (data.responseCode === 200) {
          this.saveToTempFile(data.result as ArrayBuffer);
        } else {
          this.hasError = true;
          this.errorMessage = `Download failed: HTTP status ${data.responseCode}`;
          this.isLoading = false;
        }
      }
    );
  }

  
  private saveToTempFile(data: ArrayBuffer) {
    try {
      
      const cacheDir = this.context.cacheDir;
      
      const fileName = `img_${new Date().getTime()}.jpg`;
      const filePath = `${cacheDir}/${fileName}`;

      
      let file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);

      
      this.localTempPath = filePath;
      this.isLoading = false;

    } catch (error) {
      
      this.hasError = true;
      this.errorMessage = '保存图片失败';
      this.isLoading = false;
    }
  }

  private getDisplayImagePath(): string {
    if (!this.imageElement) {
      return '';
    }
    
    if (this.imageElement.type === ImageSourceType.URL) {
      return this.localTempPath || '';
    } else {
      return this.imageElement.data;
    }
  }

  private closeViewer() {
    // Clean up temporary file
    if (this.localTempPath && fs.accessSync(this.localTempPath)) {
      try {
        fs.unlinkSync(this.localTempPath);
      } catch (error) {
        console.warn('[ImageViewer] Failed to delete temp file:', error);
      }
    }

    // Close via callback
    if (this.onClose) {
      this.onClose();
    }
  }

  
  private resetZoomAndPan() {
    this.currentScale = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
  }
} 