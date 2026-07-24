import { MessageInfo, ImageMessagePayload, MessageListStore, MessageType, MessageListState } from '@tencentcloud/atomicxcore';
import { MessageActionStore, MediaQuality } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState } from '../../basecomponent/Index';
import { ImageSourceType, ImageElement, ImageViewerWidgetDialog } from '../../imageviewer/Index';
import common from '@ohos.app.ability.common';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { MessageRenderContext } from '../context/MessageRenderContext';

function toLocalUri(path?: string): string {
  if (!path) {
    return '';
  }
  if (path.startsWith('file://') || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('datashare://')) {
    return path;
  }
  if (path.startsWith('/')) {
    return 'file://' + path;
  }
  return path;
}

function takeNonBlank(value?: string): string {
  return value && value.length > 0 ? value : '';
}

function resolveDisplayImageSource(payload?: ImageMessagePayload): string {
  if (!payload) {
    return '';
  }
  return takeNonBlank(payload.originalImagePath)
    || takeNonBlank(payload.largeImagePath)
    || takeNonBlank(payload.thumbImagePath)
    || takeNonBlank(payload.originalImageURL)
    || takeNonBlank(payload.largeImageURL)
    || takeNonBlank(payload.thumbImageURL);
}

function isRemoteUrl(value?: string): boolean {
  if (!value) {
    return false;
  }
  return value.startsWith('http://') || value.startsWith('https://');
}

@Component
export struct ImageMessageViewContent {
  @ObjectLink messagePayload: ImageMessagePayload;
  @ObjectLink message: MessageInfo;
  @ObjectLink messageListStore: MessageListStore;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private imageViewerDialogController?: CustomDialogController;

  getImageSize(): SizeOptions {
    const originalWidth = ImageSizeUtil.getSquareSize().width * 0.6;
    const originalHeight = ImageSizeUtil.getSquareSize().height;
    return ImageSizeUtil.calculateOptimalSize(originalWidth, originalHeight);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (resolveDisplayImageSource(this.messagePayload).length > 0) {
        Image(toLocalUri(resolveDisplayImageSource(this.messagePayload)))
          .interpolation(ImageInterpolation.Low)
          .objectFit(ImageFit.Cover)
          .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
          .draggable(false)
          .onClick(() => {
            const source = resolveDisplayImageSource(this.messagePayload);
            const sourceType = isRemoteUrl(source) ? ImageSourceType.URL : ImageSourceType.LOCAL;
            this.openImageViewer(sourceType, sourceType === ImageSourceType.LOCAL ? toLocalUri(source) : source);
          })
      } else {
        Image($rawfile('basecomponent/common_image_replace_icon.png'))
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
    if (!this.message || !this.message.msgID) {
      return;
    }
    const actionStore = MessageActionStore.create(this.message);
    actionStore.downloadMedia(MediaQuality.ORIGINAL);
  }

  private collectImageElements(): ImageElement[] {
    const imageElements: ImageElement[] = [];
    const messageListState: MessageListState | undefined = this.messageListStore?.state;
    const messageList: MessageInfo[] = messageListState?.messageList ?? [];
    for (let i = 0; i < messageList.length; i++) {
      const msg = messageList[i];
      if (msg && msg.messageType === MessageType.IMAGE && msg.messagePayload) {
        const body = msg.messagePayload as ImageMessagePayload;
        const localPath = takeNonBlank(body.originalImagePath)
          || takeNonBlank(body.largeImagePath)
          || takeNonBlank(body.thumbImagePath);
        if (localPath.length > 0) {
          imageElements.push({
            data: toLocalUri(localPath),
            type: ImageSourceType.LOCAL,
            width: body.originalImageWidth || 0,
            height: body.originalImageHeight || 0
          });
          continue;
        }
        const remoteUrl = takeNonBlank(body.originalImageURL)
          || takeNonBlank(body.largeImageURL)
          || takeNonBlank(body.thumbImageURL);
        if (remoteUrl.length > 0) {
          imageElements.push({
            data: remoteUrl,
            type: ImageSourceType.URL,
            width: body.originalImageWidth || 0,
            height: body.originalImageHeight || 0
          });
        }
      }
    }
    return imageElements;
  }

  private findCurrentIndex(imageElements: ImageElement[], currentImagePath: string): number {
    for (let i = 0; i < imageElements.length; i++) {
      if (imageElements[i].data === currentImagePath) {
        return i;
      }
    }
    return 0;
  }

  private openImageViewer(imageType: ImageSourceType, imagePath: string) {
    const imageElements = this.collectImageElements();
    if (imageElements.length === 0) {
      imageElements.push({
        data: imagePath,
        type: imageType,
        width: this.messagePayload?.originalImageWidth || 0,
        height: this.messagePayload?.originalImageHeight || 0
      });
    }
    const initialIndex = this.findCurrentIndex(imageElements, imagePath);

    try {
      if (this.imageViewerDialogController) {
        this.imageViewerDialogController.close();
        this.imageViewerDialogController = undefined;
      }

      this.imageViewerDialogController = new CustomDialogController({
        builder: ImageViewerWidgetDialog({
          imageElements: imageElements,
          initialIndex: initialIndex,
          onDialogClose: () => {
            this.imageViewerDialogController = undefined;
          }
        }),
        alignment: DialogAlignment.Center,
        customStyle: true,
        autoCancel: false,
        maskColor: 'rgba(0, 0, 0, 0.8)'
      });

      this.imageViewerDialogController.open();
    } catch (error) {
      console.error('[ImageMessageView] Error opening ImageViewer dialog:', error);
    }
  }
}

@Builder
export function ImageMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    ImageMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as ImageMessagePayload,
      messageListStore: context.messageListStore,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false
    })
  }
}
