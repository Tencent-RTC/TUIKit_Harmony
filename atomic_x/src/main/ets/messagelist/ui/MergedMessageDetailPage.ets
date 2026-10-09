import { MessageListStore, MessageInfo } from '@tencentcloud/atomicxcore';
import { MessageActionStore } from '@tencentcloud/atomicxcore';
import { ThemeState } from '../../basecomponent/Index';
import { MergedMessageListCompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { MessageItem, MessageDisplayMode } from './MessageItem';
import { MergedMessageListConfig } from '../config/MessageListConfig';
import { MergedMessageEnrichment } from '../adapter/MergedMessageEnrichment';
import { MessageUtils } from '../utils/MessageUtils';
import { AsrDisplayManager } from '../utils/AsrDisplayManager';
import { TranslationDisplayManager } from '../utils/TranslationDisplayManager';

@CustomDialog
export struct MergedMessageDetailPage {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State private isLoading: boolean = true;
  @State private subMessages: MessageInfo[] = [];
  @State private title: string = '';
  @State private asrDisplayManager: AsrDisplayManager = new AsrDisplayManager();
  @State private translationDisplayManager: TranslationDisplayManager = new TranslationDisplayManager();
  @State private placeholderStore: MessageListStore = MessageListStore.create('');

  controller: CustomDialogController;
  mergedMessage: MessageInfo | undefined = undefined;
  depth: number = 0;

  private readonly HEADER_HEIGHT: number = 56;
  private readonly ENRICHMENT_TIMEOUT_MS: number = 5000;
  private readonly config: MergedMessageListConfig = new MergedMessageListConfig();
  private loadVersion: number = 0;
  private enrichmentTimeoutID?: number;

  aboutToAppear() {
    this.loadVersion++;
    if (this.enrichmentTimeoutID !== undefined) {
      clearTimeout(this.enrichmentTimeoutID);
      this.enrichmentTimeoutID = undefined;
    }
    this.isLoading = true;
    this.subMessages = [];
    this.title = this.mergedMessage?.rawMessage?.mergerElem?.title ?? '';
    this.loadSubMessages();
  }

  aboutToDisappear() {
    this.loadVersion++;
    if (this.enrichmentTimeoutID !== undefined) {
      clearTimeout(this.enrichmentTimeoutID);
      this.enrichmentTimeoutID = undefined;
    }
  }

  private loadSubMessages() {
    if (!this.mergedMessage) {
      this.isLoading = false;
      return;
    }

    const loadVersion = this.loadVersion;
    const actionStore = MessageActionStore.create(this.mergedMessage);
    actionStore.downloadMergedMessageList(new MergedMessageListCompletionHandlerAdapter((messageList: MessageInfo[]) => {
      if (this.loadVersion !== loadVersion) {
        return;
      }
      const sortedMessages = Array.from(messageList);
      sortedMessages.sort((a: MessageInfo, b: MessageInfo) => (a.timestamp ?? 0) - (b.timestamp ?? 0));
      const showMessages = (): void => {
        if (this.loadVersion !== loadVersion) {
          return;
        }
        this.subMessages = Array.from(sortedMessages);
        this.isLoading = false;
      };
      this.enrichmentTimeoutID = setTimeout(() => {
        if (this.loadVersion !== loadVersion) {
          return;
        }
        this.enrichmentTimeoutID = undefined;
        showMessages();
      }, this.ENRICHMENT_TIMEOUT_MS);
      MergedMessageEnrichment.fill(sortedMessages).then(() => {
        if (this.loadVersion !== loadVersion) {
          return;
        }
        if (this.enrichmentTimeoutID !== undefined) {
          clearTimeout(this.enrichmentTimeoutID);
          this.enrichmentTimeoutID = undefined;
        }
        showMessages();
      });
    }, (code: number, desc: string) => {
      if (this.loadVersion !== loadVersion) {
        return;
      }
      console.error('[MergedMessageDetailPage] downloadMergedMessageList failed:', code, desc);
      this.subMessages = [];
      this.isLoading = false;
    }));
  }

  build() {
    Column() {
      this.buildHeader()

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
      Image($rawfile('messagelist/back_icon.svg'))
        .width(12)
        .height(20)
        .fillColor(this.themeState.colors.textColorLink)
        .onClick(() => {
          this.controller.close();
        })

      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

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
        }, (message: MessageInfo, index: number) =>
          `${message.msgID}_${MessageUtils.getMessageStateHash(message)}_${index}`)
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
      messageListStore: this.placeholderStore,
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