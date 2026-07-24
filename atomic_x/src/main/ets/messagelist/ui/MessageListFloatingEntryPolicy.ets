import { GroupAtInfo, GroupAtType } from '@tencentcloud/atomicxcore';

export enum MessageListMentionKind {
  AT_ME = 0,
  AT_ALL = 1,
}

export class MessageListMentionTarget {
  sequence: number = 0;
  kind: MessageListMentionKind = MessageListMentionKind.AT_ME;

  constructor(sequence: number, kind: MessageListMentionKind) {
    this.sequence = sequence;
    this.kind = kind;
  }
}

export enum MessageListMentionTargetVisibility {
  UNKNOWN = 0,
  VISIBLE = 1,
  HIDDEN = 2,
}

export enum MessageListFloatingEntryType {
  NONE = 0,
  BACK_TO_LATEST = 1,
  NEW_MESSAGES = 2,
  MENTION = 3,
}

export class MessageListFloatingEntry {
  type: MessageListFloatingEntryType = MessageListFloatingEntryType.NONE;
  count: number = 0;
  firstMessageId: string = '';
  target?: MessageListMentionTarget = undefined;

  static backToLatest(): MessageListFloatingEntry {
    const entry = new MessageListFloatingEntry();
    entry.type = MessageListFloatingEntryType.BACK_TO_LATEST;
    return entry;
  }

  static newMessages(count: number, firstMessageId: string): MessageListFloatingEntry {
    const entry = new MessageListFloatingEntry();
    entry.type = MessageListFloatingEntryType.NEW_MESSAGES;
    entry.count = count;
    entry.firstMessageId = firstMessageId;
    return entry;
  }

  static mention(target: MessageListMentionTarget): MessageListFloatingEntry {
    const entry = new MessageListFloatingEntry();
    entry.type = MessageListFloatingEntryType.MENTION;
    entry.target = target;
    return entry;
  }
}

export class MessageListFloatingEntryPolicy {
  private static readonly BACK_TO_LATEST_THRESHOLD_SCREEN_MULTIPLIER: number = 1.5;

  static shouldShowBackToLatest(distanceFromLatestItems: number, visibleItemCount: number): boolean {
    if (visibleItemCount <= 0 || distanceFromLatestItems <= 0) {
      return false;
    }
    return distanceFromLatestItems >= visibleItemCount * MessageListFloatingEntryPolicy.BACK_TO_LATEST_THRESHOLD_SCREEN_MULTIPLIER;
  }

  static findOldestMentionTarget(groupAtInfoList?: GroupAtInfo[]): MessageListMentionTarget | undefined {
    if (!groupAtInfoList || groupAtInfoList.length === 0) {
      return undefined;
    }
    let oldestAtInfo: GroupAtInfo | undefined = undefined;
    for (const info of groupAtInfoList) {
      if (!oldestAtInfo || info.msgSeq < oldestAtInfo.msgSeq) {
        oldestAtInfo = info;
      }
    }
    if (!oldestAtInfo) {
      return undefined;
    }
    const finalAtInfo: GroupAtInfo = oldestAtInfo;
    const kind: MessageListMentionKind =
      finalAtInfo.atType === GroupAtType.AT_ALL || finalAtInfo.atType === GroupAtType.AT_ALL_AT_ME ?
      MessageListMentionKind.AT_ALL : MessageListMentionKind.AT_ME;
    return new MessageListMentionTarget(finalAtInfo.msgSeq, kind);
  }
}

export class MessageListFloatingEntryStateController {
  private firstNewMessageId: string = '';
  private newMessageCount: number = 0;
  private mentionTarget?: MessageListMentionTarget = undefined;
  private mentionTargetVisibility: MessageListMentionTargetVisibility = MessageListMentionTargetVisibility.UNKNOWN;
  private shouldShowBackToLatest: boolean = false;
  private isBeyondDisplayThreshold: boolean = false;

  reset(): void {
    this.firstNewMessageId = '';
    this.newMessageCount = 0;
    this.mentionTarget = undefined;
    this.mentionTargetVisibility = MessageListMentionTargetVisibility.UNKNOWN;
    this.shouldShowBackToLatest = false;
    this.isBeyondDisplayThreshold = false;
  }

  onInitialMentionTarget(target?: MessageListMentionTarget, visibility: MessageListMentionTargetVisibility = MessageListMentionTargetVisibility.HIDDEN): void {
    if (!target) {
      this.mentionTarget = undefined;
      this.mentionTargetVisibility = MessageListMentionTargetVisibility.UNKNOWN;
      return;
    }
    this.mentionTarget = target;
    this.mentionTargetVisibility = visibility;
  }

  onMentionTargetVisibilityChanged(visibility: MessageListMentionTargetVisibility): void {
    if (!this.mentionTarget) {
      this.mentionTargetVisibility = MessageListMentionTargetVisibility.UNKNOWN;
      return;
    }
    if (visibility === MessageListMentionTargetVisibility.UNKNOWN) {
      return;
    }
    this.mentionTargetVisibility = visibility;
  }

  currentMentionTarget(): MessageListMentionTarget | undefined {
    return this.mentionTarget;
  }

  onNewMessage(messageId: string, isLatestVisible: boolean): void {
    if (!messageId) {
      return;
    }
    if (isLatestVisible) {
      this.clearNewMessages();
      return;
    }
    if (!this.firstNewMessageId) {
      this.firstNewMessageId = messageId;
    }
    this.newMessageCount += 1;
  }

  onScroll(distanceFromLatestItems: number, visibleItemCount: number, isLatestVisible: boolean): void {
    if (isLatestVisible) {
      this.clearNewMessages();
      this.isBeyondDisplayThreshold = false;
      this.shouldShowBackToLatest = false;
      return;
    }
    if (MessageListFloatingEntryPolicy.shouldShowBackToLatest(distanceFromLatestItems, visibleItemCount)) {
      this.isBeyondDisplayThreshold = true;
    }
    this.shouldShowBackToLatest = this.isBeyondDisplayThreshold;
  }

  currentEntry(): MessageListFloatingEntry | undefined {
    if (this.isBeyondDisplayThreshold && this.newMessageCount > 0 && this.firstNewMessageId.length > 0) {
      return MessageListFloatingEntry.newMessages(this.newMessageCount, this.firstNewMessageId);
    }
    if (this.mentionTarget) {
      return MessageListFloatingEntry.mention(this.mentionTarget);
    }
    if (!this.isBeyondDisplayThreshold) {
      return undefined;
    }
    return this.shouldShowBackToLatest ? MessageListFloatingEntry.backToLatest() : undefined;
  }

  consume(entry: MessageListFloatingEntry): void {
    if (entry.type === MessageListFloatingEntryType.NEW_MESSAGES) {
      this.clearNewMessages();
    } else if (entry.type === MessageListFloatingEntryType.MENTION) {
      this.mentionTarget = undefined;
    }
  }

  private clearNewMessages(): void {
    this.firstNewMessageId = '';
    this.newMessageCount = 0;
  }
}
