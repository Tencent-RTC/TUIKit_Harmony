import { MessageInfo, SendMessagePayload, SendMessageOption, TextMessagePayload, TextSendMessagePayload,
  ImageMessagePayload, ImageSendMessagePayload, VideoMessagePayload, VideoSendMessagePayload, AudioMessagePayload,
  AudioSendMessagePayload, FileMessagePayload, FileSendMessagePayload, FaceMessagePayload, FaceSendMessagePayload,
  CustomMessagePayload, CustomSendMessagePayload } from '@tencentcloud/atomicxcore';

export class MessageResendPayloadFactory {
  static buildPayload(message: MessageInfo): SendMessagePayload | undefined {
    const payload = message.messagePayload;

    if (payload instanceof TextMessagePayload) {
      const text = payload.text;
      if (!text || text.length === 0) {
        return undefined;
      }
      return new TextSendMessagePayload(text);
    }

    if (payload instanceof ImageMessagePayload) {
      const imagePath = payload.originalImagePath;
      if (!imagePath || imagePath.length === 0) {
        return undefined;
      }
      return new ImageSendMessagePayload(imagePath, payload.originalImageWidth, payload.originalImageHeight);
    }

    if (payload instanceof VideoMessagePayload) {
      const videoPath = payload.videoPath;
      if (!videoPath || videoPath.length === 0) {
        return undefined;
      }
      return new VideoSendMessagePayload(
        videoPath,
        payload.videoType ?? '',
        payload.videoDuration,
        payload.videoSnapshotPath ?? '',
        payload.videoSnapshotWidth,
        payload.videoSnapshotHeight
      );
    }

    if (payload instanceof AudioMessagePayload) {
      const audioPath = payload.audioPath;
      if (!audioPath || audioPath.length === 0) {
        return undefined;
      }
      return new AudioSendMessagePayload(audioPath, payload.audioDuration);
    }

    if (payload instanceof FileMessagePayload) {
      const filePath = payload.filePath;
      if (!filePath || filePath.length === 0) {
        return undefined;
      }
      return new FileSendMessagePayload(filePath, payload.fileName ?? '', payload.fileSize);
    }

    if (payload instanceof FaceMessagePayload) {
      return new FaceSendMessagePayload(payload.faceIndex, payload.faceData ?? '');
    }

    if (payload instanceof CustomMessagePayload) {
      const customData = payload.customData;
      if (!customData || customData.length === 0) {
        return undefined;
      }
      return new CustomSendMessagePayload(customData, payload.description ?? '', payload.extensionInfo ?? '');
    }

    return undefined;
  }

  static buildOption(message: MessageInfo): SendMessageOption {
    const option = new SendMessageOption();
    option.atUserList = message.atUserList && message.atUserList.length > 0 ? message.atUserList : undefined;
    option.quotedMessage = undefined;
    option.needReadReceipt = message.needReadReceipt;
    option.isExtensionEnabled = message.isExtensionEnabled;
    option.onlineUserOnly = false;
    option.offlinePushInfo = message.offlinePushInfo;
    return option;
  }
}
