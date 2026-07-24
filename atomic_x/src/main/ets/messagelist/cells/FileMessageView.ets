import { MessageInfo, MessageStatus, FileMessagePayload, MessageListStore } from '@tencentcloud/atomicxcore';
import { MessageActionStore, MediaQuality } from '@tencentcloud/atomicxcore';
import { ThemeState, Toast } from '../../basecomponent/Index';
import { AppBuilderConfig } from '../../basecomponent/utils/AppBuilderHelper';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { MessageListStyleProtocol } from '../config/MessageListConfig';
import { MessageUtils } from '../utils/MessageUtils';
import { filePreview } from '@kit.PreviewKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';
import { MessageRenderContext } from '../context/MessageRenderContext';

@Component
export struct FileMessageViewContent {
  @State message?: MessageInfo = undefined;
  @ObjectLink messagePayload: FileMessagePayload;
  @ObjectLink messageListStore: MessageListStore;
  @Prop config?: MessageListStyleProtocol = undefined;
  @Prop isInMergedDetailView: boolean = false;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Column() {
      Row() {
        Image($rawfile('messagelist/icon_message_file.svg'))
          .width(22)
          .height(22)
          .margin({ right: 10 })
        Column() {
          Text(this.messagePayload?.fileName || $r('app.string.messagelist_unknown_file'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('80%')

        }
        .alignItems(HorizontalAlign.Start)
      }
      .padding(10)
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .borderRadius(8)
      .margin({ left: 5, right: 5, top: 8 })
      .width('90%')
      .onClick(() => {
        this.handleFileClick();
      })

      Row() {
        Text(this.formatFileSize(this.messagePayload?.fileSize))
          .fontSize(12)
          .fontColor(this.message?.isSentBySelf ? this.themeState.colors.textColorAntiSecondary :
          this.themeState.colors.textColorPrimary)
          .margin({ left: 1, top: 4 })
        Row() {
          if (this.message && MessageUtils.shouldShowReadReceipt(this.message,
            this.config?.enableReadReceipt ?? AppBuilderConfig.getInstance().enableReadReceipt,
            this.isInMergedDetailView)) {
            Image(MessageUtils.getReadReceiptIconResource(this.message))
              .width(14)
              .height(14)
              .margin({ right: 4 })
          }

          if (this.message?.status === MessageStatus.SENDING) {
            LoadingProgress()
              .width(12)
              .height(12)
              .margin({ right: 4 })
          }
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        top: 10,
        bottom: 8,
        left: 16,
        right: 16
      })
    }
    .width(240)
  }

  private handleFileClick() {
    if (!this.message || !this.message.msgID) {
      return;
    }

    if (!this.messagePayload?.fileName) {
      return;
    }

    const latestPath = this.getLatestFilePath(this.message.msgID);
    if (latestPath && latestPath.length > 0) {
      this.openFile(latestPath);
      return;
    }

    this.downloadAndOpenFile();
  }

  private downloadAndOpenFile() {
    if (!this.message) {
      return;
    }

    this.showDownloadToast($r('app.string.messagelist_downloading'));

    const msgID = this.message.msgID;
    const actionStore = MessageActionStore.create(this.message);
    actionStore.downloadMedia(MediaQuality.ORIGINAL, new CompletionHandlerAdapter(() => {
      const latestPath = this.getLatestFilePath(msgID);
      if (latestPath && latestPath.length > 0) {
        this.openFile(latestPath);
      } else {
        this.showDownloadToast($r('app.string.messagelist_file_download_failed'));
      }
    }, (code: number, desc: string) => {
      console.error('[FileMessageView] download failure:', code, desc);
      this.showDownloadToast($r('app.string.messagelist_file_download_failed'));
    }));
  }

  private getLatestFilePath(msgID?: string): string {
    if (!msgID) {
      return this.messagePayload?.filePath ?? '';
    }
    const list: MessageInfo[] = this.messageListStore?.state?.messageList ?? [];
    for (let i = list.length - 1; i >= 0; i--) {
      const m: MessageInfo = list[i];
      if (m && m.msgID === msgID) {
        const payload = m.messagePayload as FileMessagePayload | undefined;
        return payload?.filePath ?? '';
      }
    }
    return this.messagePayload?.filePath ?? '';
  }

  private openFile(filePath: string) {
    try {
      const cleanPath = filePath.startsWith('file://') ? filePath.substring(7) : filePath;
      this.openWithSystemApp(cleanPath);
    } catch (error) {
    }
  }

  private openWithSystemApp(filePath: string) {
    try {
      let uiContext = this.getUIContext().getHostContext() as Context;
      let uri = fileUri.getUriFromPath(filePath);

      filePreview.canPreview(uiContext, uri).then((result: boolean) => {
        let displayInfo: filePreview.DisplayInfo = {
          x: 100,
          y: 100,
          width: 800,
          height: 800
        };
        let fileInfo: filePreview.PreviewInfo = {
          title: this.messagePayload?.fileName,
          uri: uri,
          mimeType: this.getMimeType(filePath)
        };
        filePreview.openPreview(uiContext, fileInfo, displayInfo).then(() => {
        }).catch((err: BusinessError) => {
          console.error(`Failed to open preview, err.code = ${err.code}, err.message = ${err.message}`);
        });
      }).catch((err: BusinessError) => {
        console.error(`Failed to obtain canPreview, err.code = ${err.code}, err.message = ${err.message}`);
      });

    } catch (error) {
      console.error('[FileMessageView] error:', error);
    }
  }

  private getMimeType(fileName: string): string {
    const extension = this.getFileExtension(fileName).toLowerCase();

    const mimeTypes: Record<string, string> = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      '3gp': 'video/3gpp',
      'webm': 'video/webm',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'aac': 'audio/aac',
      'flac': 'audio/flac',
      'ogg': 'audio/ogg',
      'm4a': 'audio/mp4',
      'wma': 'audio/x-ms-wma',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'json': 'application/json',
      'xml': 'application/xml',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript'
    };

    return mimeTypes[extension] || 'application/octet-stream';
  }

  private getFileExtension(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    return lastDotIndex !== -1 ? fileName.substring(lastDotIndex + 1) : '';
  }

  private showDownloadToast(message: string | Resource) {
    try {
      Toast.info(message, this.getUIContext());
    } catch (error) {
      console.error('[FileMessageView] Toast error:', error);
    }
  }

  private formatFileSize(bytes?: number): string | Resource {
    if (!bytes) {
      return $r('app.string.messagelist_unknown_size');
    }
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return `${size.toFixed(1)} ${units[unitIndex]}`;
  }
}

@Builder
export function FileMessageView(context: MessageRenderContext) {
  if (context.message && context.message.messagePayload && context.messageListStore) {
    FileMessageViewContent({
      message: context.message,
      messagePayload: context.message.messagePayload as FileMessagePayload,
      messageListStore: context.messageListStore,
      config: context.config,
      isInMergedDetailView: context.isInMergedDetailView ?? false
    })
  }
}