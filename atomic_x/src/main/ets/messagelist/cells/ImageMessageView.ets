import { MessageInfo, MessageBody, MessageListStore, MessageMediaFileType } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState } from '../../basecomponent/Index';
import { ImageSourceType, ImageElement, ImageViewerDialog } from '../../imageviewer/Index';
import common from '@ohos.app.ability.common';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct ImageMessageViewContent {
  @ObjectLink messageBody: MessageBody;
  @ObjectLink message: MessageInfo;
  @ObjectLink messageListStore: MessageListStore;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private imageViewerDialogController?: CustomDialogController;

  getImageSize(): SizeOptions {
    const originalWidth = ImageSizeUtil.getSquareSize().width * 0.6
    const originalHeight = ImageSizeUtil.getSquareSize().height;
    return ImageSizeUtil.calculateOptimalSize(originalWidth, originalHeight);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.messageBody?.originalImagePath) {
        Image(this.messageBody.originalImagePath)
          .interpolation(ImageInterpolation.Low)
          .objectFit(ImageFit.Cover)
          .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
          .draggable(false)
          .onClick(() => this.openImageViewer(ImageSourceType.LOCAL, this.messageBody.originalImagePath ?? ""))
      } else if (this.messageBody?.thumbImagePath) {
        Image(this.messageBody.thumbImagePath)
          .interpolation(ImageInterpolation.Low)
          .objectFit(ImageFit.Cover)
          .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
          .draggable(false)
          .onClick(() => {
            const imagePath = this.messageBody.largeImagePath || this.messageBody.thumbImagePath;
            this.openImageViewer(ImageSourceType.LOCAL, imagePath ?? "");
          })
      } else {
        Image($rawfile("basecomponent/common_image_replace_icon.png"))
          .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
          .backgroundColor('#F2F2F2')
          .borderRadius(5)
      }

      if (MessageUtils.shouldShowReadReceipt(this.message,
        this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
        this.isInMergedDetailView)) {
        Image(MessageUtils.getReadReceiptIconResource(this.message))
          .width(14)
          .height(14)
          .margin({ right: 8, bottom: 6 })
      }
    }
    .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
  }

  public requestImageDownload() {
    if (!this.message || !this.message.ID) {
      return;
    }
    return this.messageListStore.downloadMessageResource(this.message, MessageMediaFileType.originalImage);
  }

  private openImageViewer(imageType: ImageSourceType, imagePath: string) {
    console.log('[ImageMessageView] openImageViewer called with:', imageType, imagePath);
    
    const imageElement: ImageElement = {
      data: imagePath,
      type: imageType,
      width: this.messageBody?.originalImageWidth || 0,
      height: this.messageBody?.originalImageHeight || 0
    };

    console.log('[ImageMessageView] Created imageElement:', imageElement);
    
    try {
      // Close existing dialog if any
      if (this.imageViewerDialogController) {
        this.imageViewerDialogController.close();
        this.imageViewerDialogController = undefined;
      }

      // Create dialog controller in component context (like ChatPage does)
      this.imageViewerDialogController = new CustomDialogController({
        builder: ImageViewerDialog({
          imageElement: imageElement,
          onDialogClose: () => {
            console.log('[ImageMessageView] ImageViewer dialog closed');
            this.imageViewerDialogController = undefined;
          }
        }),
        alignment: DialogAlignment.Center,
        customStyle: true,
        autoCancel: false,
        maskColor: 'rgba(0, 0, 0, 0.8)'
      });

      console.log('[ImageMessageView] Opening ImageViewer dialog...');
      this.imageViewerDialogController.open();
      console.log('[ImageMessageView] ImageViewer dialog opened successfully');
    } catch (error) {
      console.error('[ImageMessageView] Error opening ImageViewer dialog:', error);
    }
  }
}

@Builder
export function ImageMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messageBody) {
    ImageMessageViewContent({
      message: context.message,
      messageBody: context.message.messageBody,
      messageListStore: context.messageListStore,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false
    })
  }
}
