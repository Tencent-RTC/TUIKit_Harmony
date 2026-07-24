import {
  AudioMessagePayload,
  CustomMessagePayload,
  FaceMessagePayload,
  FileMessagePayload,
  ImageMessagePayload,
  MergedMessagePayload,
  MessagePayload,
  MessageQuoteInfo,
  MessageStatus,
  TextMessagePayload,
  VideoMessagePayload
} from '@tencentcloud/atomicxcore';

export interface MessageQuoteLabels {
  deleted: string;
  revoked: string;
  image: string;
  video: string;
  voice: string;
  file: string;
  face: string;
  custom: string;
  merged: string;
  unknown: string;
}

export interface MessageQuoteThumbnail {
  path: string;
  isVideo: boolean;
}

export interface MessageQuoteDisplayData {
  senderName: string;
  contentText: string;
  thumbnail?: MessageQuoteThumbnail;
  isPartial: boolean;
  isStatusText: boolean;
}

const PARTIAL_CONTENT = '...';
const SECONDS_PER_MINUTE = 60;

export class MessageQuoteDisplayPolicy {
  static resolve(quoteInfo: MessageQuoteInfo, labels: MessageQuoteLabels): MessageQuoteDisplayData {
    const senderName = MessageQuoteDisplayPolicy.resolveSenderName(quoteInfo);
    const payload = quoteInfo.messagePayload;
    if (quoteInfo.status === MessageStatus.DELETED) {
      return {
        senderName: senderName,
        contentText: labels.deleted,
        isPartial: false,
        isStatusText: true
      };
    }
    if (quoteInfo.status === MessageStatus.REVOKED) {
      return {
        senderName: senderName,
        contentText: labels.revoked,
        isPartial: false,
        isStatusText: true
      };
    }
    if (!payload) {
      return {
        senderName: senderName,
        contentText: PARTIAL_CONTENT,
        isPartial: true,
        isStatusText: false
      };
    }
    return {
      senderName: senderName,
      contentText: MessageQuoteDisplayPolicy.resolveContentText(payload, labels),
      thumbnail: MessageQuoteDisplayPolicy.resolveThumbnail(payload),
      isPartial: false,
      isStatusText: false
    };
  }

  private static resolveSenderName(quoteInfo: MessageQuoteInfo): string {
    const sender = quoteInfo.sender;
    if (sender.friendRemark && sender.friendRemark.length > 0) {
      return sender.friendRemark;
    }
    if (sender.nameCard && sender.nameCard.length > 0) {
      return sender.nameCard;
    }
    if (sender.nickname && sender.nickname.length > 0) {
      return sender.nickname;
    }
    return sender.userID;
  }

  private static resolveContentText(payload: MessagePayload, labels: MessageQuoteLabels): string {
    if (payload instanceof TextMessagePayload) {
      return payload.text;
    }
    if (payload instanceof ImageMessagePayload) {
      return labels.image;
    }
    if (payload instanceof VideoMessagePayload) {
      return labels.video;
    }
    if (payload instanceof AudioMessagePayload) {
      return MessageQuoteDisplayPolicy.resolveAudioText(payload, labels);
    }
    if (payload instanceof FileMessagePayload) {
      const name = payload.fileName;
      if (name && name.length > 0) {
        return name;
      }
      return labels.file;
    }
    if (payload instanceof FaceMessagePayload) {
      return labels.face;
    }
    if (payload instanceof CustomMessagePayload) {
      const desc = payload.description;
      if (desc && desc.length > 0) {
        return desc;
      }
      return labels.custom;
    }
    if (payload instanceof MergedMessagePayload) {
      if (payload.title && payload.title.length > 0) {
        return payload.title;
      }
      return labels.merged;
    }
    return labels.unknown;
  }

  private static resolveAudioText(payload: AudioMessagePayload, labels: MessageQuoteLabels): string {
    const duration = payload.audioDuration;
    if (duration <= 0) {
      return labels.voice;
    }
    const minutes = Math.floor(duration / SECONDS_PER_MINUTE);
    const seconds = duration % SECONDS_PER_MINUTE;
    let durationText = '';
    if (minutes > 0) {
      const secStr = seconds < 10 ? `0${seconds}` : `${seconds}`;
      durationText = `${minutes}:${secStr}"`;
    } else {
      durationText = `${seconds}"`;
    }
    return `${labels.voice} ${durationText}`;
  }

  private static resolveThumbnail(payload: MessagePayload): MessageQuoteThumbnail | undefined {
    if (payload instanceof ImageMessagePayload) {
      const path = MessageQuoteDisplayPolicy.firstNonBlank([
        payload.thumbImagePath,
        payload.thumbImageURL,
        payload.originalImagePath,
        payload.originalImageURL
      ]);
      if (path) {
        return { path: MessageQuoteDisplayPolicy.toLocalUri(path), isVideo: false };
      }
      return undefined;
    }
    if (payload instanceof VideoMessagePayload) {
      const path = MessageQuoteDisplayPolicy.firstNonBlank([
        payload.videoSnapshotPath,
        payload.videoSnapshotURL
      ]);
      if (path) {
        return { path: MessageQuoteDisplayPolicy.toLocalUri(path), isVideo: true };
      }
      return undefined;
    }
    return undefined;
  }

  private static toLocalUri(path: string): string {
    if (path.startsWith('file://') || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('datashare://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return 'file://' + path;
    }
    return path;
  }

  private static firstNonBlank(values: (string | undefined)[]): string | undefined {
    for (const value of values) {
      if (value && value.length > 0) {
        return value;
      }
    }
    return undefined;
  }
}