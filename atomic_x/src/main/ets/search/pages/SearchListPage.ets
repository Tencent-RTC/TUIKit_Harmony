import { AppBuilderConfig, Avatar, AvatarContentType, AvatarSize, ThemeState, LanguageState } from '../../basecomponent/Index';
import {
  FriendSearchInfo,
  GroupSearchInfo,
  MessageSearchResultItem,
  SearchOption,
  SearchStore,
  SearchType,
  MessageInfo
} from '@tencentcloud/atomicxcore';
import { router } from '@kit.ArkUI';
import { SearchContactPage } from './SearchContactPage';
import { SearchGroupPage } from './SearchGroupPage';
import { SearchMessageInAllConversationsPage } from './SearchMessageInAllConversationsPage';
import { SearchMessageInOneConversationPage } from './SearchMessageInOneConversationPage';
import { HighlightText } from '../components/HighlightText';
import { MessageUtils } from '../../messagelist/utils/MessageUtils';

// Re-export SDK types for convenience
export { FriendSearchInfo, GroupSearchInfo, MessageSearchResultItem, MessageInfo } from '@tencentcloud/atomicxcore';

interface SearchCategoryInfo {
  type: SearchType
  title: string
  hasMore: boolean
  totalCount: number
}

@Component
export struct SearchListPage {
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly ITEM_HEIGHT: number = 68;
  private static readonly SEARCH_BAR_HEIGHT: number = 56;
  private static readonly DIVIDER_HEIGHT: number = 0;
  private static readonly MAX_RESULTS_PER_CATEGORY: number = 3;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @State searchKeyword: string = '';
  @State showSearchResults: boolean = false;
  @State searchHistory: string[] = [];
  @State showDetailView: boolean = false;
  @State detailViewType: SearchType = SearchType.Friend;
  @State showConversationDetail: boolean = false;
  @State selectedConversation: MessageSearchResultItem | null = null;
  @State friendCategoryInfo: SearchCategoryInfo | null = null;
  @State groupCategoryInfo: SearchCategoryInfo | null = null;
  @State messageCategoryInfo: SearchCategoryInfo | null = null;
  onContactSelect?: (contact: FriendSearchInfo) => void;
  onGroupSelect?: (group: GroupSearchInfo) => void;
  onMessageSelect?: (message: MessageSearchResultItem) => void;
  onConversationSelect?: (message: MessageSearchResultItem) => void;
  onBack?: () => void;
  onShowMore?: (type: SearchType) => void;
  @State private searchStore: SearchStore = SearchStore.create();

  aboutToAppear() {
    console.info('SearchListPage aboutToAppear');
    this.loadSearchHistory();
  }

  aboutToDisappear() {
    console.info('SearchListPage aboutToDisappear');
  }

  build() {
    Column() {
      Column() {
        if (this.showConversationDetail) {
          this.ConversationDetailBuilder()
        } else if (this.showDetailView) {
          this.DetailViewBuilder()
        } else if (this.showSearchResults) {
          this.SearchResultsBuilder()
        } else {
          this.SearchHistoryBuilder()
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  SearchBarBuilder() {
    Row() {
      if (this.showDetailView || this.showConversationDetail) {
        Button() {
          Image($rawfile('basecomponent/common_back_icon.svg'))
            .width(16)
            .height(16)
            .fillColor(this.themeState.colors.textColorPrimary)
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
          if (this.showConversationDetail) {
            this.showConversationDetail = false;
          } else if (this.showDetailView) {
            this.showDetailView = false;
          } else if (this.onBack) {
            this.onBack();
          } else {
            router.back();
          }
        })
      }

      Row() {
        Image($rawfile('search/search_icon.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorSecondary)
          .margin({ right: 2 })

        TextInput({
          placeholder: $r('app.string.search_search_placeholder'),
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

      Text(this.showDetailView || this.showConversationDetail ? $r('app.string.search_back') :
      $r('app.string.search_cancel'))
        .fontSize(16)
        .fontWeight(400)
        .fontFamily('PingFang SC')
        .fontColor('#1C66E5')
        .margin({ left: 14, right: 16 })
        .onClick(() => {
          if (this.showConversationDetail) {
            this.showConversationDetail = false;
          } else if (this.showDetailView) {
            this.showDetailView = false;
          } else if (this.onBack) {
            this.onBack();
          } else {
            router.back();
          }
        })
    }
    .width('100%')
    .height(SearchListPage.SEARCH_BAR_HEIGHT)
    .padding({ left: 8, right: 0 })
    .margin({ top: 25 + 26 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  SearchHistoryBuilder() {
    Column() {
      if (!AppBuilderConfig.getInstance().hideSearch) {
        this.SearchBarBuilder()
      }

      if (this.searchHistory.length > 0) {
        List() {
          ForEach(this.searchHistory, (item: string, index: number) => {
            ListItem() {
              Row() {
                Image($rawfile('search/search_icon.svg'))
                  .width(20)
                  .height(20)
                  .fillColor(this.themeState.colors.textColorSecondary)
                  .margin({ right: 12 })

                Text(item)
                  .fontSize(16)
                  .fontColor(this.themeState.colors.textColorPrimary)
                  .layoutWeight(1)

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
                  this.removeSearchHistory(index);
                })
              }
              .width('100%')
              .height(SearchListPage.ITEM_HEIGHT)
              .padding({ left: 16, right: 16 })
              .backgroundColor(this.themeState.colors.bgColorOperate)
            }
            .onClick(() => {
              this.searchKeyword = item;
              this.performSearch();
            })
          }, (item: string) => item)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .scrollBar(BarState.Off)
      } else {
        Column() {
          Image($rawfile('search/empty_chat_icon.svg'))
            .width(80)
            .height(80)
            .fillColor(this.themeState.colors.textColorSecondary)
            .margin({ bottom: 16 })

          Text($r('app.string.search_suggest_text'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.themeState.colors.bgColorOperate)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SearchResultsBuilder() {
    Column() {
      if (!AppBuilderConfig.getInstance().hideSearch) {
        this.SearchBarBuilder()
      }

      if (this.hasAnyResults()) {
        List() {
          // Friends section
          if (this.friendCategoryInfo) {
            ListItem() {
              this.CategoryHeaderBuilder(this.friendCategoryInfo)
            }

            ListItem() {
              this.FriendListBuilder()
            }
          }

          // Groups section
          if (this.groupCategoryInfo) {
            ListItem() {
              this.CategoryHeaderBuilder(this.groupCategoryInfo)
            }

            ListItem() {
              this.GroupListBuilder()
            }
          }

          // Messages section
          if (this.messageCategoryInfo) {
            ListItem() {
              this.CategoryHeaderBuilder(this.messageCategoryInfo)
            }

            ListItem() {
              this.MessageListBuilder()
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .scrollBar(BarState.Off)
      } else {
        Column() {
          Image($rawfile('search/empty_chat_icon.svg'))
            .width(80)
            .height(80)
            .fillColor(this.themeState.colors.textColorSecondary)
            .margin({ bottom: 16 })

          Text($r('app.string.search_no_results'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.themeState.colors.bgColorOperate)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CategoryHeaderBuilder(info: SearchCategoryInfo) {
    Row() {
      Text(info.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)

      if (info.hasMore) {
        Button() {
          Text($r('app.string.search_view_more'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorLink)
        }
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showMoreResults(info.type);
        })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  FriendListBuilder() {
    Column() {
      LazyForEach(this.searchStore.state.friendList, (item: FriendSearchInfo, index: number) => {
        if (index < SearchListPage.MAX_RESULTS_PER_CATEGORY) {
          this.FriendItemBuilder(item)
        }
      }, (item: FriendSearchInfo) => item.getKey())
    }
    .width('100%')
  }

  @Builder
  FriendItemBuilder(item: FriendSearchInfo) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: item.userInfo.avatarURL || '',
          name: item.friendRemark || item.userInfo.nickname || item.userID,
        },
        avatarSize: AvatarSize.M,
      }).margin({ right: 12 })

      Column() {
        HighlightText({
          text: item.friendRemark || item.userInfo.nickname || item.userID,
          keyword: this.searchKeyword,
          fontSize: 16,
          fontWeight: FontWeight.Medium,
          textColor: this.themeState.colors.textColorPrimary,
          maxLines: 1
        })

        HighlightText({
          text: `ID: ${item.userID}`,
          keyword: this.searchKeyword,
          fontSize: 14,
          fontWeight: FontWeight.Normal,
          textColor: this.themeState.colors.textColorSecondary,
          maxLines: 1
        })
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($rawfile('search/right_arrow_icon.svg'))
        .width(8)
        .height(12)
        .fillColor(this.themeState.colors.textColorTertiary)
    }
    .width('100%')
    .height(SearchListPage.ITEM_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onClick(() => {
      if (this.onContactSelect) {
        this.onContactSelect(item);
      }
    })
  }

  @Builder
  GroupListBuilder() {
    Column() {
      LazyForEach(this.searchStore.state.groupList, (item: GroupSearchInfo, index: number) => {
        if (index < SearchListPage.MAX_RESULTS_PER_CATEGORY) {
          this.GroupItemBuilder(item)
        }
      }, (item: GroupSearchInfo) => item.getKey())
    }
    .width('100%')
  }

  @Builder
  GroupItemBuilder(item: GroupSearchInfo) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: item.groupAvatarURL,
          name: item.groupName || item.groupID,
        },
        avatarSize: AvatarSize.M,
      }).margin({ right: 12 })

      Column() {
        HighlightText({
          text: item.groupName || item.groupID,
          keyword: this.searchKeyword,
          fontSize: 16,
          fontWeight: FontWeight.Medium,
          textColor: this.themeState.colors.textColorPrimary,
          maxLines: 1
        })

        HighlightText({
          text: `ID: ${item.groupID}`,
          keyword: this.searchKeyword,
          fontSize: 14,
          fontWeight: FontWeight.Normal,
          textColor: this.themeState.colors.textColorSecondary,
          maxLines: 1
        })
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($rawfile('search/right_arrow_icon.svg'))
        .width(8)
        .height(12)
        .fillColor(this.themeState.colors.textColorTertiary)
    }
    .width('100%')
    .height(SearchListPage.ITEM_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onClick(() => {
      if (this.onGroupSelect) {
        this.onGroupSelect(item);
      }
    })
  }

  @Builder
  MessageListBuilder() {
    Column() {
      LazyForEach(this.searchStore.state.messageResults, (item: MessageSearchResultItem, index: number) => {
        if (index < SearchListPage.MAX_RESULTS_PER_CATEGORY) {
          this.MessageItemBuilder(item)
        }
      }, (item: MessageSearchResultItem) => item.getKey())
    }
    .width('100%')
  }

  @Builder
  MessageItemBuilder(item: MessageSearchResultItem) {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: item.conversationAvatarURL,
          name: item.conversationShowName || item.conversationID,
        },
        avatarSize: AvatarSize.M,
      }).margin({ right: 12 })

      Column() {
        HighlightText({
          text: item.conversationShowName || item.conversationID,
          keyword: this.searchKeyword,
          fontSize: 16,
          fontWeight: FontWeight.Medium,
          textColor: this.themeState.colors.textColorPrimary,
          maxLines: 1
        })

        HighlightText({
          text: this.getMessageSubtitle(item),
          keyword: this.searchKeyword,
          fontSize: 14,
          fontWeight: FontWeight.Normal,
          textColor: this.themeState.colors.textColorSecondary,
          maxLines: 2
        })
          .margin({ top: 4 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($rawfile('search/right_arrow_icon.svg'))
        .width(8)
        .height(12)
        .fillColor(this.themeState.colors.textColorTertiary)
    }
    .width('100%')
    .height(SearchListPage.ITEM_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onClick(() => {
      this.selectedConversation = item;
      this.showConversationDetail = true;
    })
  }

  @Builder
  DetailViewBuilder() {
    if (this.detailViewType.value === SearchType.Friend.value) {
      SearchContactPage({
        initialSearchKeyword: this.searchKeyword,
        onSelectContact: (contact: FriendSearchInfo) => {
          if (this.onContactSelect) {
            this.onContactSelect(contact);
          }
        },
        onBack: () => {
          this.showDetailView = false;
        }
      })
    } else if (this.detailViewType.value === SearchType.Group.value) {
      SearchGroupPage({
        initialSearchKeyword: this.searchKeyword,
        onSelectGroup: (group: GroupSearchInfo) => {
          if (this.onGroupSelect) {
            this.onGroupSelect(group);
          }
        },
        onBack: () => {
          this.showDetailView = false;
        }
      })
    } else if (this.detailViewType.value === SearchType.Message.value) {
      SearchMessageInAllConversationsPage({
        initialSearchKeyword: this.searchKeyword,
        onSelectMessage: (message: MessageSearchResultItem) => {
          this.selectedConversation = message;
          this.showConversationDetail = true;
          this.showDetailView = false;
        },
        onBack: () => {
          this.showDetailView = false;
        }
      })
    }
  }

  @Builder
  ConversationDetailBuilder() {
    if (this.selectedConversation) {
      SearchMessageInOneConversationPage({
        initialSearchKeyword: this.searchKeyword,
        conversationInfo: this.selectedConversation,
        onSelectMessage: (message: MessageSearchResultItem) => {
          if (this.onMessageSelect) {
            this.onMessageSelect(message);
          }
        },
        onSelectConversation: (message: MessageSearchResultItem) => {
          if (this.onConversationSelect) {
            this.onConversationSelect(message);
          }
        },
        onBack: () => {
          this.showConversationDetail = false;
        }
      })
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

  private performSearch(): void {
    if (this.searchKeyword.trim().length === 0) {
      return;
    }

    const option = new SearchOption()
    option.searchType = SearchType.combine(SearchType.Friend, SearchType.Group, SearchType.Message)

    this.searchStore.search([this.searchKeyword], option)
      .then(() => {
        this.updateCategoryInfo();
        this.showSearchResults = true;
        this.addSearchHistory(this.searchKeyword);
      })
      .catch((error: Error) => {
        console.error('Search failed:', error.message)
      })
  }

  private updateCategoryInfo(): void {
    const state = this.searchStore.state

    // Friends
    const friendCount = state.friendList.totalCount()
    if (friendCount > 0) {
      this.friendCategoryInfo = {
        type: SearchType.Friend,
        title: getContext().resourceManager.getStringSync($r('app.string.search_contacts_title').id),
        hasMore: friendCount > SearchListPage.MAX_RESULTS_PER_CATEGORY,
        totalCount: friendCount
      }
    } else {
      this.friendCategoryInfo = null
    }

    // Groups
    const groupCount = state.groupList.totalCount()
    if (groupCount > 0) {
      this.groupCategoryInfo = {
        type: SearchType.Group,
        title: getContext().resourceManager.getStringSync($r('app.string.search_groups_title').id),
        hasMore: groupCount > SearchListPage.MAX_RESULTS_PER_CATEGORY,
        totalCount: groupCount
      }
    } else {
      this.groupCategoryInfo = null
    }

    // Messages
    const messageCount = state.messageResults.totalCount()
    if (messageCount > 0) {
      this.messageCategoryInfo = {
        type: SearchType.Message,
        title: getContext().resourceManager.getStringSync($r('app.string.search_messages_title').id),
        hasMore: messageCount > SearchListPage.MAX_RESULTS_PER_CATEGORY,
        totalCount: messageCount
      }
    } else {
      this.messageCategoryInfo = null
    }
  }

  private hasAnyResults(): boolean {
    return this.friendCategoryInfo !== null ||
      this.groupCategoryInfo !== null ||
      this.messageCategoryInfo !== null
  }

  private showMoreResults(type: SearchType): void {
    this.detailViewType = type;
    this.showDetailView = true;
  }

  private clearSearch(): void {
    this.showSearchResults = false;
    this.friendCategoryInfo = null;
    this.groupCategoryInfo = null;
    this.messageCategoryInfo = null;
  }

  private loadSearchHistory(): void {
    // Load from storage if needed
  }

  private addSearchHistory(keyword: string): void {
    if (keyword.trim().length === 0) {
      return;
    }

    const index = this.searchHistory.indexOf(keyword);
    if (index > -1) {
      this.searchHistory.splice(index, 1);
    }

    this.searchHistory.unshift(keyword);

    if (this.searchHistory.length > 10) {
      this.searchHistory = this.searchHistory.slice(0, 10);
    }
  }

  private removeSearchHistory(index: number): void {
    this.searchHistory.splice(index, 1);
  }

  private getMessageSubtitle(item: MessageSearchResultItem): string {
    if (item.messageList.length > 0) {
      return MessageUtils.getMessageAbstractString(item.messageList[0]);
    }
    return getContext().resourceManager.getStringByNameSync('search_related_messages_count', item.messageCount.toString());
  }
}
