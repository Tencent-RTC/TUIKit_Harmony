import {
  MessageListStore,
  MessageInfo,
  MessageListType,
  MessageFetchOption,
  MessageFetchDirection,
  MessageListState,
  MessageDataSource,
  MessageEvent,
  V2TIMManager,
  V2TIMMessage
} from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MessageItem, MessageDisplayMode } from './MessageItem';
import { MergedMessageListConfig } from '../config/MessageListConfig';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';

/**
 * Merged message detail page component
 * Displays the sub-messages of a merged message
 */
@CustomDialog
export struct MergedMessageDetailPage {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State private messageListStore: MessageListStore = MessageListStore.create('', MessageListType.merged);
  @State private messageListState?: MessageListState = undefined;
  @State private isLoading: boolean = true;
  @State private subMessages: MessageInfo[] = [];
  @State private title: string = '';
  @State private asrDisplayManager: AsrDisplayManager = new AsrDisplayManager();
  @State private translationDisplayManager: TranslationDisplayManager = new TranslationDisplayManager();
  
  controller: CustomDialogController;
  mergedMessage: MessageInfo | undefined = undefined;
  depth: number = 0;
  
  private readonly HEADER_HEIGHT: number = 56;
  private readonly config: MergedMessageListConfig = new MergedMessageListConfig();
  
  aboutToAppear() {
    // Set title from merged message
    this.title = this.mergedMessage?.messageBody?.mergedMessage?.title ?? '';
    this.initializeStore();
    this.loadSubMessages();
  }
  
  aboutToDisappear() {
    // Clean up subscriptions if needed
  }
  
  private initializeStore() {
    // Create a store for merged messages
    this.messageListStore = MessageListStore.create('', MessageListType.merged);
    this.messageListState = this.messageListStore.state;
    
    // Subscribe to message events
    this.messageListStore.messageEventEmitter.subscribe(this, (event: MessageEvent) => {
      if (event.type === 'fetchMessages' && event.messageList) {
        // Sort messages by timestamp in ascending order (oldest first)
        const sortedMessages = [...event.messageList].sort((a, b) => (a.timestamp ?? 0) - (b.timestamp ?? 0));
        this.subMessages = sortedMessages;
        this.isLoading = false;
      }
    });
  }
  
  private async loadSubMessages() {
    if (!this.mergedMessage) {
      console.error('[MergedMessageDetailPage] No mergedMessage provided');
      this.isLoading = false;
      return;
    }
    
    console.info('[MergedMessageDetailPage] Loading sub messages for merged message:', {
      messageID: this.mergedMessage.ID,
      messageType: this.mergedMessage.messageType,
      hasRawMessage: !!this.mergedMessage.rawMessage,
      hasMessageBody: !!this.mergedMessage.messageBody,
      hasMergedMessage: !!this.mergedMessage.messageBody?.mergedMessage,
      rawMessageElemType: this.mergedMessage.rawMessage?.elemType
    });
    
    try {
      // First, ensure we have the complete message with relay key
      // If this message comes from search, it may have incomplete mergerElem
      let completeMessage = this.mergedMessage;
      
      if (this.mergedMessage.ID) {
        console.info('[MergedMessageDetailPage] Fetching complete message via findMessages for ID:', this.mergedMessage.ID);
        try {
          const messages = await V2TIMManager.getMessageManager().findMessages([this.mergedMessage.ID]);
          if (messages && messages.length > 0) {
            console.info('[MergedMessageDetailPage] Found complete message, updating rawMessage');
            // Update the rawMessage with the complete one
            completeMessage.rawMessage = messages[0];
          } else {
            console.warn('[MergedMessageDetailPage] findMessages returned empty, using original message');
          }
        } catch (error) {
          console.error('[MergedMessageDetailPage] findMessages failed:', error, '- continuing with original message');
        }
      }
      
      const option: MessageFetchOption = {
        message: completeMessage,
        direction: MessageFetchDirection.Older,
        pageCount: 100
      };
      
      await this.messageListStore.fetchMessageList(option);
      
      // Messages will be updated via messageEventEmitter
      // Get messages from messageDataSource
      if (this.messageListState) {
        const dataSource = this.messageListState.messageDataSource;
        const messages: MessageInfo[] = [];
        for (let i = 0; i < dataSource.totalCount(); i++) {
          const msg = dataSource.getData(i);
          if (msg) {
            messages.push(msg);
          }
        }
        console.info('[MergedMessageDetailPage] Loaded', messages.length, 'sub messages');
        // Sort messages by timestamp in ascending order (oldest first)
        messages.sort((a, b) => (a.timestamp ?? 0) - (b.timestamp ?? 0));
        this.subMessages = messages;
        
        // Fetch reactions for sub-messages 
        this.fetchMessageReactions(messages);
      }
      this.isLoading = false;
    } catch (error) {
      console.error('[MergedMessageDetailPage] Failed to fetch sub messages:', error);
      this.isLoading = false;
    }
  }
  
  private fetchMessageReactions(messages: MessageInfo[]) {
    if (messages.length === 0) {
      return;
    }
    
    this.messageListStore.fetchMessageReactions(messages, 3)
      .then(() => {
        console.info('[MergedMessageDetailPage] Fetched reactions for', messages.length, 'messages');
      })
      .catch((error: Error) => {
        console.error('[MergedMessageDetailPage] Failed to fetch reactions:', error.message);
      });
  }
  
  build() {
    Column() {
      // Header
      this.buildHeader()
      
      // Content
      if (this.isLoading) {
        this.buildLoadingView()
      } else if (this.subMessages.length === 0) {
        this.buildEmptyView()
      } else {
        this.buildMessageList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
  
  @Builder
  private buildHeader() {
    Row() {
      // Back button
      Image($rawfile('messagelist/back_icon.svg'))
        .width(12)
        .height(20)
        .fillColor(this.themeState.colors.textColorLink)
        .onClick(() => {
          this.controller.close();
        })
      
      // Title
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      // Placeholder for symmetry
      Row()
        .width(24)
        .height(24)
    }
    .width('100%')
    .height(this.HEADER_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
  
  @Builder
  private buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.themeState.colors.textColorSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  
  @Builder
  private buildEmptyView() {
    Column() {
      Text($r('app.string.search_no_messages'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorSecondary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  
  @Builder
  private buildMessageList() {
    Scroll() {
      Column({ space: 8 }) {
        ForEach(this.subMessages, (message: MessageInfo) => {
          this.buildMessageItem(message)
        }, (message: MessageInfo) => message.ID)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .align(Alignment.Top)
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
  
  @Builder
  private buildMessageItem(message: MessageInfo) {
    MessageItem({
      message: message,
      messageListStore: this.messageListStore,
      config: this.config,
      initialShowAvatar: true,
      displayMode: MessageDisplayMode.Merged,
      asrDisplayManager: this.asrDisplayManager,
      translationDisplayManager: this.translationDisplayManager,
      onTranslationBubbleLongPress: (message: MessageInfo) => {
      }
    })
      .padding({ left: this.config.horizontalPadding, right: this.config.horizontalPadding })
  }
}
