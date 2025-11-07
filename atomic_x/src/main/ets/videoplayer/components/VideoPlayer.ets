import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import media from '@ohos.multimedia.media';
import { MessageInfo, MessageListStore, MessageMediaFileType } from '@tencentcloud/atomicxcore';

export enum MediaType {
  IMAGE = 0,
  VIDEO = 1
}

export interface MediaItem {
  path: string;
  type: MediaType;
  videoPath?: string;
}

// Video data structure similar to VideoPlayer.kt
export interface VideoData {
  thumbnailPath: string;
  videoPath?: string;
  width?: number;
  height?: number;
  duration?: number;
  snapshotUrl?: string;
  snapshotLocalPath?: string;

  // Additional fields for download functionality
  messageInfo?: MessageInfo; // MessageInfo from atomicxcore
  messageListStore?: MessageListStore; // MessageListStore from atomicxcore
}

// Video player dialog controller similar to ImageViewer
@CustomDialog
export struct VideoPlayerDialog {
  controller: CustomDialogController;
  videoData?: VideoData;
  onDialogClose?: () => void;
  onDownloadComplete?: (videoPath: string) => void;

  aboutToAppear() {
    console.log('[VideoPlayerDialog] aboutToAppear, videoData:', this.videoData);
  }

  build() {
    VideoPlayer({
      videoData: this.videoData,
      onClose: () => {
        console.log('[VideoPlayerDialog] onClose called');
        this.controller.close();
        if (this.onDialogClose) {
          this.onDialogClose();
        }
      },
      onDownloadComplete: this.onDownloadComplete
    })
  }
}

interface PreparedEvent {
  duration: number;
  width?: number;
  height?: number;
}

interface UpdateTimeEvent {
  time: number;
}

@Component
export struct VideoPlayer {
  // @StorageLink('ThemeState') ThemeState: ThemeState = ThemeState.getInstance();

  // New props for dialog usage
  videoData?: VideoData;
  onClose?: () => void;
  onDownloadComplete?: (videoPath: string) => void;
  @State thumbnailPath: string = '';
  @State videoPath: string = '';
  @State mediaType: MediaType = MediaType.IMAGE;
  @State isLoading: boolean = true;
  @State isPlaying: boolean = false;
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State showControls: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State isDownloading: boolean = false;
  @State downloadProgress: number = 0;
  private videoController: VideoController = new VideoController();
  private controlsTimerId: number = -1;
  private downloadCheckInterval: number = -1;
  private durationCheckInterval: number = -1;
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    // Support both dialog usage and router usage
    if (this.videoData) {
      // Dialog usage - use videoData prop
      this.thumbnailPath = this.videoData.thumbnailPath || '';
      this.videoPath = this.videoData.videoPath || '';
      this.mediaType = MediaType.VIDEO;
      console.info(`[VideoPlayer] Dialog mode - thumbnail: ${this.thumbnailPath}, videoPath: ${this.videoPath}`);
    }

    // Always show controls permanently
    this.showControls = true;
    console.log('[VideoPlayer] Controls set to always visible');

    // Reset error state on initialization to prevent showing error from previous session
    this.hasError = false;
    this.errorMessage = '';

    if (this.mediaType === MediaType.VIDEO) {
      if (this.videoPath) {
        // Video path exists, prepare for playback
        this.isLoading = true;
        this.isDownloading = false;
        console.log('[VideoPlayer] Video path exists, preparing for playback');
      } else {
        // No video path, need to download
        this.isLoading = false;
        this.isDownloading = true;
        console.log('[VideoPlayer] No video path, starting download');
        this.requestVideoDownload();
      }
    } else {
      this.isLoading = false;
      this.isDownloading = false;
    }
  }

  aboutToDisappear() {

    if (this.controlsTimerId !== -1) {
      clearTimeout(this.controlsTimerId);
    }

    if (this.downloadCheckInterval !== -1) {
      clearInterval(this.downloadCheckInterval);
    }

    if (this.durationCheckInterval !== -1) {
      clearInterval(this.durationCheckInterval);
    }

  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(Color.White)

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
        .fillColor(Color.White)

      Text($r('app.string.video_play_failed'))
        .fontSize(18)
        .fontColor(Color.White)
        .margin({ top: 16 })

      Text(this.errorMessage)
        .fontSize(14)
        .fontColor(Color.White)
        .margin({ top: 8 })

      Button($r('app.string.back_button'))
        .margin({ top: 24 })
        .onClick(() => {
          this.handleBackClick();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ControlsBuilder() {
    Column() {

      Row() {
        Image($rawfile('videoplayer/ic_back.svg'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
          .onClick(() => {
            this.handleBackClick();
          })

        Blank()
      }
      .width('100%')
      .padding(16)

      Blank()


      Column() {

        Slider({
          value: this.currentTime,
          min: 0,
          max: this.duration > 0 ? this.duration : 100,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .selectedColor(Color.White)
          .trackColor(Color.Gray)
          .showSteps(false)
          .showTips(false)
          .onChange((value: number) => {
            try {
              this.currentTime = value;
              const seekTimeMs = Math.floor(value);
              this.videoController.setCurrentTime(seekTimeMs);
            } catch (error) {
            }
            this.resetControlsTimer();
          })
        Row() {
          Image(this.getPlayButtonIcon())
            .width(32)
            .height(32)
            .fillColor(this.isDownloading ? Color.Gray : Color.White)
            .opacity(this.isDownloading ? 0.5 : 1.0)
            .onClick(() => {
              this.onPlayButtonClick();
            })
          Text(`${this.formatTime(this.currentTime)} / ${this.formatTime(this.duration)}`)
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ left: 16 })

          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
    }
    .width('100%')
    .height('100%')
    .opacity(1) // Always fully visible
    .animation({
      duration: 300,
      curve: Curve.EaseOut
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')

      // Priority: downloading > error > normal display
      if (this.isDownloading) {
        // Show loading state when downloading (regardless of videoPath status)
        Stack({ alignContent: Alignment.TopStart }) {

          Image(this.thumbnailPath)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              console.log('[VideoPlayer] Image clicked during download, controls remain visible');
            })


          Column() {

            Row() {
              Image($rawfile('videoplayer/ic_back.svg'))
                .width(24)
                .height(24)
                .fillColor(Color.White)
                .onClick(() => {
                  this.handleBackClick();
                })

              Blank()
            }
            .width('100%')
            .padding(16)

            Blank()
          }
          .width('100%')
          .height('100%')
          .opacity(1) // Always fully visible
          .animation({
            duration: 300,
            curve: Curve.EaseOut
          })

          // Always show loading when downloading
          this.LoadingStateBuilder()
        }
      } else if (this.mediaType === MediaType.IMAGE || (this.mediaType === MediaType.VIDEO && !this.videoPath)) {

        Stack({ alignContent: Alignment.TopStart }) {

          Image(this.thumbnailPath)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              // Controls always visible, no toggle needed
              console.log('[VideoPlayer] Image clicked, controls remain visible');
            })


          Column() {

            Row() {
              Image($rawfile('videoplayer/ic_back.svg'))
                .width(24)
                .height(24)
                .fillColor(Color.White)
                .onClick(() => {
                  this.handleBackClick();
                })

              Blank()
            }
            .width('100%')
            .padding(16)

            Blank()


            Blank()
          }
          .width('100%')
          .height('100%')
          .opacity(1) // Always fully visible
          .animation({
            duration: 300,
            curve: Curve.EaseOut
          })

        }
      } else if (this.hasError) {

        this.ErrorStateBuilder()
      } else {


        if (this.videoPath) {
          Stack({ alignContent: Alignment.Center }) {

            Video({
              src: this.videoPath,
              previewUri: this.thumbnailPath,
              controller: this.videoController
            })
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .autoPlay(true)
              .controls(false)
              .onStart(() => {
                this.isPlaying = true;
                console.log('[VideoPlayer] Video started playing, controls always visible');
              })
              .onPause(() => {
                this.isPlaying = false;

              })
              .onFinish(() => {
                this.isPlaying = false;
                this.currentTime = this.duration;
                console.log('[VideoPlayer] Video finished, controls always visible');
              })
              .onError(() => {
                this.handleError('Video play failed', new Error('Video play failed'));
              })
              .onPrepared((event: PreparedEvent) => {


                if (event && typeof event.duration === 'number' && event.duration > 0) {
                  this.duration = Math.floor(event.duration);

                } else {
                  console.warn(`[VideoPlayer] No valid duration is returned in the video prepare event: ${JSON.stringify(event)}`);

                  try {

                    if (this.duration === 0) {

                      this.duration = 60;

                    }
                  } catch (error) {

                  }
                }

                this.isLoading = false;
              })
              .onUpdate((event: UpdateTimeEvent) => {

                if (!event || typeof event.time !== 'number') {
                  console.warn(`[VideoPlayer] 收到无效的时间更新事件: ${JSON.stringify(event)}`);
                  return;
                }


                const newTime = Math.floor(event.time);
                if (newTime !== this.currentTime) {
                  this.currentTime = newTime;

                }


                if (this.duration === 0 || (this.duration === 60 && this.currentTime > 30)) {
                  const estimatedDuration = Math.max(this.currentTime + 30, 60);
                  if (estimatedDuration !== this.duration) {
                    this.duration = estimatedDuration;

                  }
                }
              })
              .onClick(() => {
                // Controls always visible, no action needed
                console.log('[VideoPlayer] Video clicked, controls remain visible');
              })


            if (this.isLoading) {
              this.LoadingStateBuilder()
            }
          }
        }
      }


      if (!this.hasError) {
        this.ControlsBuilder()
      }
    }
    .width('100%')
    .height('100%')
  }

  public handleDownloadComplete(videoPath: string) {
    console.log('[VideoPlayer] handleDownloadComplete called with path:', videoPath);

    // Stop download progress and set video path
    this.isDownloading = false;
    this.downloadProgress = 100;

    // Set the new video path and update UI state
    this.setVideoPath(videoPath);

    console.log('[VideoPlayer] Download completed, controls always visible');

    // Call external callback if provided
    if (this.onDownloadComplete) {
      this.onDownloadComplete(videoPath);
    }
  }

  public setVideoPath(path: string) {
    console.log('[VideoPlayer] setVideoPath called with path:', path);

    // Update video path
    this.videoPath = path;
    this.isDownloading = false;
    this.downloadProgress = 100;

    // Reset video player state
    this.isLoading = true;
    this.currentTime = 0;
    this.isPlaying = false;
    this.hasError = false;
    this.duration = 0;

    // Clear any existing intervals
    if (this.downloadCheckInterval !== -1) {
      clearInterval(this.downloadCheckInterval);
      this.downloadCheckInterval = -1;
    }
  }

  public requestVideoDownload() {
    if (!this.videoData?.messageInfo || !this.videoData?.messageListStore) {
      console.warn('[VideoPlayer] Missing messageInfo or messageListStore for download');
      return;
    }

    console.log('[VideoPlayer] Starting video download');

    // Reset error state when starting download
    this.hasError = false;
    this.errorMessage = '';
    this.isDownloading = true;
    this.downloadProgress = 0;

    // Start download
    this.videoData.messageListStore.downloadMessageResource(this.videoData.messageInfo, MessageMediaFileType.video)
      .then(() => {
        console.log('[VideoPlayer] Video download completed');

        // Get the updated video path from message body
        const videoPath = this.videoData?.messageInfo?.messageBody?.videoPath;
        if (videoPath) {
          this.handleDownloadComplete(videoPath);
        } else {
          console.warn('[VideoPlayer] Download completed but video path is empty');
          this.isDownloading = false;
          this.downloadProgress = 100;
        }
      })
      .catch((error: object) => {
        console.error('[VideoPlayer] Video download failed:', error);
        this.isDownloading = false;
        this.downloadProgress = 0;
        // Set a timeout to retry download after a short delay
        setTimeout(() => {
          if (!this.videoPath && !this.hasError) {
            console.log('[VideoPlayer] Retrying download after failure');
            this.requestVideoDownload();
          }
        }, 2000);
      });
  }

  private onPlayButtonClick() {

    if (this.mediaType !== MediaType.VIDEO) {
      return;
    }

    // If video is downloading, don't allow play action
    if (this.isDownloading) {
      console.log('[VideoPlayer] Video is downloading, play button disabled');
      return;
    }

    if (!this.videoPath) {
      console.log('[VideoPlayer] No video path, starting download');
      this.requestVideoDownload();
      return;
    }

    this.togglePlayPause();
  }

  private togglePlayPause() {
    try {
      // Additional safety check - don't allow play/pause during download
      if (this.isDownloading) {
        console.log('[VideoPlayer] Cannot toggle play/pause during download');
        return;
      }

      // Don't allow play if no video path
      if (!this.videoPath) {
        console.log('[VideoPlayer] Cannot play without video path');
        return;
      }

      if (this.isPlaying) {
        // Pause the video
        this.videoController.pause();
        console.log('[VideoPlayer] Video paused, controls always visible');
      } else {
        // Start the video
        this.videoController.start();
        console.log('[VideoPlayer] Video started, controls always visible');
      }
    } catch (error) {
      console.error('[VideoPlayer] Error in togglePlayPause:', error);
      // If there's an error, it might be because the video isn't ready
      this.handleError('Video playback failed', error as Error);
    }
  }

  private handleBackClick() {
    if (this.onClose) {
      // Dialog mode - use callback
      this.onClose();
    } else {
      // Router mode - use router back
      router.back();
    }
  }

  private handleError(message: string, error: Error) {
    this.hasError = true;
    this.isLoading = false;
    this.errorMessage = message;
    console.error(`[VideoPlayer] ${message}: ${JSON.stringify(error)}`);
  }

  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  private getPlayButtonIcon(): Resource {
    if (this.isDownloading) {
      // Show play icon but disabled when downloading
      return $rawfile('videoplayer/ic_play.svg');
    } else if (this.isPlaying) {
      return $rawfile('videoplayer/ic_pause.svg');
    } else {
      return $rawfile('videoplayer/ic_play.svg');
    }
  }

  private resetControlsTimer() {
    // Controls are always visible, no timer needed
    console.log('[VideoPlayer] resetControlsTimer called - controls always visible');

    // Clear any existing timer
    if (this.controlsTimerId !== -1) {
      clearTimeout(this.controlsTimerId);
      this.controlsTimerId = -1;
    }

    // Ensure controls remain visible
    this.showControls = true;
  }
}