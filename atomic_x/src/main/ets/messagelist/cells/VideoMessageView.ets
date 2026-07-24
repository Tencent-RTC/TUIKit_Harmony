import { MessageInfo, VideoMessagePayload, MessageListStore } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState } from '../../basecomponent/Index';
import router from '@ohos.router';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import {
  MediaType,
  MediaItem,
  VideoData,
  VideoPlayerDialog
} from '../../videoplayer/Index';
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

function resolveDisplayVideoSnapshot(payload?: VideoMessagePayload): string {
  if (!payload) {
    return '';
  }
  const localPath = takeNonBlank(payload.videoSnapshotPath);
  if (localPath.length > 0) {
    return toLocalUri(localPath);
  }
  return takeNonBlank(payload.videoSnapshotURL);
}

const DEFAULT_IMAGE_MAX_SIZE = 180;

@Component
export struct VideoMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: VideoMessagePayload;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @State isPlaying: boolean = false;
  @ObjectLink messageListStore: MessageListStore;

  private videoPlayerDialogController?: CustomDialogController;

  aboutToAppear() {
  }

  aboutToDisappear() {
    if (this.videoPlayerDialogController) {
      this.videoPlayerDialogController = undefined;
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {

      Image(resolveDisplayVideoSnapshot(this.messagePayload))
        .width('100%')
        .height('100%')
        .borderRadius(8)
        .interpolation(ImageInterpolation.Medium)
        .objectFit(ImageFit.Cover)
        .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })


      Column() {
        Image($rawfile('videoplayer/ic_play.svg'))
          .width('60vp')
          .height('60vp')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)


      Row() {
        Text(this.formatDuration(this.messagePayload?.videoDuration ?? 0))
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#99000000')
          .borderRadius(4)
          .padding({
            left: 6,
            right: 6,
            top: 2,
            bottom: 2
          })
      }
      .margin({ right: 8, bottom: 8 })
      .alignItems(VerticalAlign.Bottom)

      if (this.message && MessageUtils.shouldShowReadReceipt(this.message,
        this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
        this.isInMergedDetailView)) {
        Image(MessageUtils.getReadReceiptIconResource(this.message))
          .width(14)
          .height(14)
          .margin({ right: 45, bottom: 6 })
      }
    }
    .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
    .onClick(() => {
      if (resolveDisplayVideoSnapshot(this.messagePayload).length === 0) {
        return;
      }
      this.openVideoPlayerDialog();
    })
  }

  private openVideoPlayerDialog() {
    if (resolveDisplayVideoSnapshot(this.messagePayload).length === 0) {
      return;
    }

    const videoData: VideoData = {
      thumbnailPath: resolveDisplayVideoSnapshot(this.messagePayload),
      videoPath: takeNonBlank(this.messagePayload?.videoPath),
      width: this.messagePayload?.videoSnapshotWidth,
      height: this.messagePayload?.videoSnapshotHeight,
      duration: this.messagePayload?.videoDuration,
      messageInfo: this.message,
      messageListStore: this.messageListStore
    };

    this.videoPlayerDialogController = new CustomDialogController({
      builder: VideoPlayerDialog({
        videoData: videoData,
        onDialogClose: () => {
          this.videoPlayerDialogController = undefined;
        },
        onDownloadComplete: (videoPath: string) => {
          if (this.messagePayload) {
            this.messagePayload.videoPath = videoPath;
          }
        }
      }),
      autoCancel: false,
      customStyle: true
    });

    this.videoPlayerDialogController.open();
  }

  private getImageSize(): SizeOptions {
    const originalWidth = ImageSizeUtil.getSquareSize().width * 0.6;
    const originalHeight = ImageSizeUtil.getSquareSize().height;
    return ImageSizeUtil.calculateOptimalSize(originalWidth, originalHeight);
  }

  private togglePlay() {
    this.isPlaying = !this.isPlaying;
  }

  private formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
}

@Builder
export function VideoMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload) {
    VideoMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as VideoMessagePayload,
      messageListStore: context.messageListStore,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false
    })
  }
}
