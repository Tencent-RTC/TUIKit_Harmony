import { AppBuilderConfig, Avatar, AvatarContentType, AvatarSize, ThemeState, LanguageState } from '../../basecomponent/Index';
import {
  MessageSearchResultItem,
  MessageInfo,
  SearchOption,
  SearchStore,
  SearchType,
  MessageSearchFilter,
  BasicDataSource
} from '@tencentcloud/atomicxcore';
import { HighlightText } from '../components/HighlightText';
import { MessageUtils } from '../../messagelist/utils/MessageUtils';

@Component
export struct SearchMessageInOneConversationPage {
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly ITEM_HEIGHT: number = 68;
  private static readonly SEARCH_BAR_HEIGHT: number = 56;
  private static readonly DIVIDER_HEIGHT: number = 0;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State searchKeyword: string = '';
  @Prop initialSearchKeyword?: string;
  @Prop conversationInfo: MessageSearchResultItem | null = null;
  @State isLoading: boolean = false;
  @State isLoadingMore: boolean = false;
  private messageDataSource: BasicDataSource<MessageInfo> = new BasicDataSource<MessageInfo>();
  onSelectMessage?: (message: MessageSearchResultItem) => void;
  onSelectConversation?: (message: MessageSearchResultItem) => void;
  onBack?: () => void;
  @State private searchStore: SearchStore = SearchStore.create();

  aboutToAppear() {
    console.info('SearchMessageInOneConversationPage aboutToAppear');

    if (this.initialSearchKeyword && this.initialSearchKeyword.trim().length > 0) {
      this.searchKeyword = this.initialSearchKeyword;
      this.performSearch();
    }
  }

  aboutToDisappear() {
    console.info('SearchMessageInOneConversationPage aboutToDisappear');
  }

  build() {
    Column() {
      if (!AppBuilderConfig.getInstance().hideSearch) {
        this.SearchBarBuilder()
      }

      if (this.isLoading) {
        this.LoadingStateBuilder()
      } else if (this.messageDataSource.totalCount() > 0) {
        this.MessageListBuilder()
      } else {
        this.EmptyStateBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  SearchBarBuilder() {
    Row() {
      Button() {
        Image($rawfile('basecomponent/common_back_icon.svg'))
          .width(16)
          .height(16)
          .fillColor(this.themeState.colors.textColorLink)
          .scale({
            x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
            y: 1
          })
      }
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
      .width(44)
      .height(44)
      .onClick(() => {
        if (this.onBack) {
          this.onBack();
        }
      })

      Row() {
        Image($rawfile('search/search_icon.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorSecondary)
          .margin({ right: 2 })

        TextInput({
          placeholder: $r('app.string.search_search_in_conversation_placeholder'),
          text: this.searchKeyword
        })
          .placeholderColor(this.themeState.colors.textColorTertiary)
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.handleSearchInputChange(value);
          })
          .onSubmit(() => {
            this.performSearch();
          })

        if (this.searchKeyword.length > 0) {
          Button() {
            Image($rawfile('contactlist/contact_del.svg'))
              .width(16)
              .height(16)
              .fillColor(this.themeState.colors.textColorSecondary)
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .onClick(() => {
            this.searchKeyword = '';
            this.clearSearch();
          })
        }
      }
      .backgroundColor(this.themeState.colors.bgColorInput)
      .borderRadius(20)
      .padding({ left: 12, right: 8 })
      .height(40)
      .layoutWeight(1)
      .margin({ left: 8 })

      Text($r('app.string.search_cancel'))
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('PingFang SC')
        .fontColor('#1C66E5')
        .margin({ left: 14, right: 16 })
        .onClick(() => {
          if (this.onBack) {
            this.onBack();
          }
        })
    }
    .width('100%')
    .height(SearchMessageInOneConversationPage.SEARCH_BAR_HEIGHT)
    .padding({ left: 8, right: 0 })
    .margin({ top: 25 + 26 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  MessageListBuilder() {
    List() {
      ListItem() {
        this.ConversationHeaderBuilder()
      }

      LazyForEach(this.messageDataSource, (message: MessageInfo) => {
        ListItem() {
          this.MessageItemBuilder(message)
        }
        .onClick(() => {
          this.handleMessageClick(message);
        })
      }, (message: MessageInfo) => message.ID ?? message.msgID ?? `${message.timestamp}`)

      if (this.isLoadingMore) {
        ListItem() {
          Row() {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(this.themeState.colors.textColorPrimary)

            Text($r('app.string.search_loading_more'))
              .fontSize(12)
              .fontColor(this.themeState.colors.textColorSecondary)
              .margin({ left: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 16, bottom: 16 })
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .scrollBar(BarState.Off)
    .onReachEnd(() => {
      if (this.searchStore.state.hasMoreMessageResults && !this.isLoadingMore && !this.isLoading) {
        this.loadMoreMessages();
      }
    })
  }

  @Builder
  ConversationHeaderBuilder() {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: this.conversationInfo?.conversationAvatarURL ?? '',
          name: this.conversationInfo?.conversationShowName ?? '',
        },
        avatarSize: AvatarSize.M,
      }).margin({ right: 12 })

      Text(this.conversationInfo?.conversationShowName ?? '')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Image($rawfile('search/right_arrow_icon.svg'))
        .width(8)
        .height(12)
        .fillColor(this.themeState.colors.textColorTertiary)
    }
    .width('100%')
    .height(SearchMessageInOneConversationPage.ITEM_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onClick(() => {
      this.handleConversationHeaderClick();
    })
  }

  @Builder
  MessageItemBuilder(message: MessageInfo) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: message.sender?.avatarURL || '',
          name: this.getSenderDisplayName(message),
        },
        avatarSize: AvatarSize.M,
      }).margin({ right: 12 })

      Column() {
        Row() {
          Text(this.getSenderDisplayName(message))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorSecondary)
        }.margin({ bottom: 5 })

        Row() {
          HighlightText({
            text: MessageUtils.getMessageAbstractString(message),
            keyword: this.searchKeyword,
            fontSize: 14,
            fontWeight: FontWeight.Normal,
            textColor: this.themeState.colors.textColorSecondary,
            maxLines: 2
          })
            .layoutWeight(1)

          Text(this.formatTime(message.timestamp ?? 0))
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(SearchMessageInOneConversationPage.ITEM_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(this.themeState.colors.textColorLink)

      Text($r('app.string.search_loading'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Image($rawfile('search/empty_chat_icon.svg'))
        .width(80)
        .height(80)
        .fillColor(this.themeState.colors.textColorSecondary)
        .margin({ bottom: 16 })

      Text($r('app.string.search_no_matched_messages'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  private performSearch(): void {
    if (this.searchKeyword.trim().length === 0) {
      this.clearSearch();
      return;
    }

    if (!this.conversationInfo?.conversationID) {
      console.warn('[SearchMessageInOneConversationPage] Missing conversation ID');
      return;
    }

    this.isLoading = true;

    const option = new SearchOption()
    option.searchType = SearchType.Message
    option.messageFilter = new MessageSearchFilter()
    option.messageFilter.conversationID = this.conversationInfo.conversationID

    this.searchStore.search([this.searchKeyword], option)
      .then(() => {
        this.isLoading = false;
        this.updateMessageList();
      })
      .catch((error: Error) => {
        this.isLoading = false;
        console.error('Search messages in conversation failed:', error.message)
      })
  }

  private loadMoreMessages(): void {
    if (this.isLoadingMore || !this.searchStore.state.hasMoreMessageResults) {
      return;
    }

    this.isLoadingMore = true;

    this.searchStore.searchMore(SearchType.Message)
      .then(() => {
        this.isLoadingMore = false;
        this.updateMessageList();
      })
      .catch((error: Error) => {
        this.isLoadingMore = false;
        console.error('Load more messages failed:', error.message)
      })
  }

  private updateMessageList(): void {
    const resultItem = this.searchStore.state.messageResults.getData(0);
    if (resultItem) {
      this.messageDataSource.setData(resultItem.messageList);
    } else {
      this.messageDataSource.clear();
      this.messageDataSource.notifyDataReload();
    }
  }

  private handleMessageClick(message: MessageInfo): void {
    if (this.onSelectMessage && this.conversationInfo) {
      // Create a MessageSearchResultItem with the selected message
      const result = new MessageSearchResultItem(
        this.conversationInfo.conversationID,
        this.conversationInfo.conversationShowName,
        this.conversationInfo.conversationAvatarURL,
        1,
        [message]
      );
      this.onSelectMessage(result);
    }
  }

  private handleConversationHeaderClick(): void {
    if (this.onSelectConversation && this.conversationInfo) {
      this.onSelectConversation(this.conversationInfo);
    }
  }

  private handleSearchInputChange(value: string): void {
    if (value.trim().length === 0) {
      this.clearSearch();
    } else {
      this.debounceSearch(value);
    }
  }

  private debounceSearch(keyword: string): void {
    if (keyword.trim().length > 0) {
      this.performSearch();
    }
  }

  private clearSearch(): void {
    this.messageDataSource.clear();
    this.messageDataSource.notifyDataReload();
    this.searchStore.state.messageResults.clear()
    this.searchStore.state.messageResults.notifyDataReload()
    this.isLoadingMore = false;
  }

  private formatTime(timestamp: number): string {
    if (timestamp === 0) {
      return '';
    }

    const date = new Date(timestamp * 1000);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const messageDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    if (messageDate.getTime() === today.getTime()) {
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    } else {
      return `${(date.getMonth() + 1).toString().padStart(2, '0')}/${date.getDate().toString().padStart(2, '0')}`;
    }
  }

  private getSenderDisplayName(message: MessageInfo): string {
    const senderInfo = message.sender;
    if (!senderInfo) {
      return '';
    }
    // Priority: nameCard > friendRemark > nickname > userID
    return senderInfo.nameCard || senderInfo.friendRemark || senderInfo.nickname || senderInfo.userID || '';
  }
}
