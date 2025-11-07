import { MessageInfo } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState } from '../../basecomponent/Index';
import { MessageBody } from '@tencentcloud/atomicxcore';
import router from '@ohos.router';
import {
  MediaType,
  MediaItem,
  VideoData,
  VideoPlayerDialog
} from '../../videoplayer/Index';
import { MessageMediaFileType, MessageListStore } from '@tencentcloud/atomicxcore';

// import { AppContext } from '../../basecomponent/Index';

const DEFAULT_IMAGE_MAX_SIZE = 180;

@Component
export struct VideoMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messageBody: MessageBody;
  @State isPlaying: boolean = false;
  @ObjectLink messageListStore: MessageListStore;
  
  // Dialog controller for video player
  private videoPlayerDialogController?: CustomDialogController;

  aboutToAppear() {
    // Video player listener removed - using direct dialog approach
  }

  aboutToDisappear() {
    // Clean up dialog controller
    if (this.videoPlayerDialogController) {
      this.videoPlayerDialogController = undefined;
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {

      Image(this.messageBody?.videoSnapshotPath)
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
        Text(this.formatDuration(this.messageBody?.videoDuration ?? 0))
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
    }
     .size({ width: `${this.getImageSize().width}vp`, height: `${this.getImageSize().height}vp` })
    .onClick(() => {

      if (!this.messageBody?.videoSnapshotPath) {
        console.error('Thumbnail is empty');
        return;
      }

      this.openVideoPlayerDialog();
    })
  }



  private openVideoPlayerDialog() {
    if (!this.messageBody?.videoSnapshotPath) {
      return;
    }

    // Create video data
    const videoData: VideoData = {
      thumbnailPath: this.messageBody?.videoSnapshotPath || '',
      videoPath: this.messageBody?.videoPath || '',
      width: this.messageBody?.videoSnapshotWidth,
      height: this.messageBody?.videoSnapshotHeight,
      duration: this.messageBody?.videoDuration,
      // Add download functionality support
      messageInfo: this.message,
      messageListStore: this.messageListStore
    };

    // Create dialog controller
    this.videoPlayerDialogController = new CustomDialogController({
      builder: VideoPlayerDialog({
        videoData: videoData,
        onDialogClose: () => {
          console.log('[VideoMessageView] Video player dialog closed');
          // Clean up dialog reference
          this.videoPlayerDialogController = undefined;
        },
        onDownloadComplete: (videoPath: string) => {
          console.log('[VideoMessageView] Video download completed in dialog:', videoPath);
          // Update message body with new video path
          if (this.messageBody) {
            this.messageBody.videoPath = videoPath;
          }
        }
      }),
      autoCancel: false,
      customStyle: true
    });

    // Open dialog immediately (will show loading state if no video path)
    this.videoPlayerDialogController.open();
    
    console.log('[VideoMessageView] Video player dialog opened, initial videoPath:', this.messageBody?.videoPath);
  }

  private getImageSize(): SizeOptions {
    const originalWidth =   ImageSizeUtil.getSquareSize().width * 0.6;
    const originalHeight =  ImageSizeUtil.getSquareSize().height;
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
export function VideoMessageView(messageData: MessageInfo, MessageListStore: MessageListStore) {
  if (messageData && messageData.messageBody) {
    VideoMessageViewContent({
      message: messageData,
      messageBody: messageData.messageBody,
      messageListStore: MessageListStore
    })
  }
}