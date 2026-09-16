import { MessageInfo, MessageListState, MessageStatus, MessageType } from '@tencentcloud/atomicxcore';

export class MessageListSelectionState {
  isMultiSelectMode: boolean = false;
  selectedMessageIDs: Set<string> = new Set();

  constructor(isMultiSelectMode: boolean, selectedMessageIDs: Set<string>) {
    this.isMultiSelectMode = isMultiSelectMode;
    this.selectedMessageIDs = selectedMessageIDs;
  }
}

export interface MessageListSelectionHost {
  getState(): MessageListState | undefined;

  onSelectionChanged(state: MessageListSelectionState): void;
}

export class MessageListSelectionController {
  private host?: MessageListSelectionHost;
  private multiSelectMode: boolean = false;
  private selectedIDs: Set<string> = new Set();

  attach(host: MessageListSelectionHost): void {
    this.host = host;
  }

  get isMultiSelectMode(): boolean {
    return this.multiSelectMode;
  }

  get selectedMessageIDs(): Set<string> {
    return this.selectedIDs;
  }

  get selectedCount(): number {
    return this.selectedIDs.size;
  }

  canSelectMessage(message: MessageInfo): boolean {
    if (message.status === MessageStatus.REVOKED) {
      return false;
    }
    if (message.messageType === MessageType.TIPS) {
      return false;
    }
    return true;
  }

  enterMultiSelectMode(initialMessage?: MessageInfo): void {
    this.multiSelectMode = true;
    this.selectedIDs = new Set();
    if (initialMessage && this.canSelectMessage(initialMessage)) {
      this.selectedIDs.add(initialMessage.ID);
    }
    this.notifySelectionChanged();
  }

  exitMultiSelectMode(): void {
    this.multiSelectMode = false;
    this.selectedIDs = new Set();
    this.notifySelectionChanged();
  }

  toggleMessageSelection(message: MessageInfo): void {
    if (!this.canSelectMessage(message)) {
      return;
    }
    if (this.selectedIDs.has(message.msgID)) {
      this.selectedIDs.delete(message.msgID);
    } else {
      this.selectedIDs.add(message.msgID);
    }
    this.selectedIDs = new Set(this.selectedIDs);
    this.notifySelectionChanged();
  }

  isSelected(msgID: string): boolean {
    return this.selectedIDs.has(msgID);
  }

  getSelectedMessages(): MessageInfo[] {
    const state = this.host?.getState();
    if (!state) {
      return [];
    }

    const selectedMessages: MessageInfo[] = [];
    state.messageList.forEach((message: MessageInfo) => {
      if (this.selectedIDs.has(message.msgID)) {
        selectedMessages.push(message);
      }
    });

    return selectedMessages.sort((a: MessageInfo, b: MessageInfo) => (a.timestamp ?? 0) - (b.timestamp ?? 0));
  }

  hasFailedMessages(): boolean {
    return this.getSelectedMessages().some((msg: MessageInfo) => msg.status === MessageStatus.SEND_FAIL);
  }

  hasViolationMessages(): boolean {
    return this.getSelectedMessages().some((msg: MessageInfo) => msg.status === MessageStatus.VIOLATION);
  }

  selectSingleMessage(message: MessageInfo): void {
    this.selectedIDs = new Set<string>([message.msgID]);
    this.notifySelectionChanged();
  }

  clearTransientSelection(): void {
    if (this.multiSelectMode) {
      return;
    }
    this.selectedIDs = new Set();
    this.notifySelectionChanged();
  }

  private notifySelectionChanged(): void {
    this.host?.onSelectionChanged(new MessageListSelectionState(this.multiSelectMode, this.selectedIDs));
  }
}
