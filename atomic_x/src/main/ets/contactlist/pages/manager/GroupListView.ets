import { ContactInfo } from '@tencentcloud/atomicxcore';
import { GroupInfo, GroupState, GroupStore } from '@tencentcloud/atomicxcore';
import { PinyinUtils } from '../../../basecomponent/utils/PinyinUtils';
import { CompletionHandlerAdapter } from '../../../basecomponent/utils/CompletionHandlers';
import { AppBuilderConfig, BackButton, TextUtils, ThemeState } from '../../../basecomponent/Index';
import { AZOrderedList, AZOrderedListItem, AZOrderedListConfig } from '../../../basecomponent/components/AZOrderedList';

@Component
export struct GroupListView {
  onBack?: () => void;
  // Callback function
  onShowProfile?: (group: ContactInfo) => void;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink groupStore: GroupStore;
  @State private groupState: GroupState = this.groupStore.state as GroupState;
  @State private isLoading: boolean = true;
  @State private searchKeyword: string = '';
  @State private showSearchResults: boolean = false;
  @State private searchResults: AZOrderedListItem<ContactInfo>[] = [];
  @State private groupListItems: AZOrderedListItem<ContactInfo>[] = [];

  aboutToAppear() {
    console.info('MyGroupPage aboutToAppear');
    this.groupState = this.groupStore.state as GroupState;
    this.loadGroupList();
  }

  aboutToDisappear() {
    console.info('MyGroupPage aboutToDisappear');
  }

  onBackPress(): boolean {
    this.handleBack();
    return true;
  }

  build() {
    Column() {
      this.buildNavigationBar()
      this.buildSearchBar()
      Stack() {
        if (this.isLoading) {
          this.buildLoadingState()
        } else if (this.showSearchResults || this.groupState.joinedGroupList.length > 0) {
          this.buildGroupContent()
        } else {
          this.buildEmptyState()
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate) // Figma: #FFFFFF
  }

  // Navigation bar
  @Builder
  buildNavigationBar() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {

        Text($r('app.string.my_group'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeState.colors.textColorPrimary)
          .textAlign(TextAlign.Center)

        Row() {
          BackButton({
            onBack: () => {
            this.handleBack();
          }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height(56)

      // Divider
      Divider()
        .height(0.5)
        .color(this.themeState.colors.strokeColorSecondary) // Figma: #E0E0E0
    }
  }

  @Builder
  buildSearchBar() {
    Row() {
      Row() {
        Image($rawfile('search/search_icon.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorTertiary)
          .margin({ right: 8 })

        TextInput({
          placeholder: $r('app.string.search_placeholder'),
          text: $$this.searchKeyword
        })
          .placeholderColor(this.themeState.colors.textColorTertiary)
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorPrimary)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.performSearch();
          })

        if (this.searchKeyword.length > 0) {
          Image($rawfile('contactlist/contact_del.svg'))
            .width(16)
            .height(16)
            .fillColor(this.themeState.colors.textColorSecondary)
            .onClick(() => {
              this.searchKeyword = '';
              this.clearSearch();
            })
        }
      }
      .width('100%')
      .height(36)
      .backgroundColor(this.themeState.colors.bgColorInput)
      .borderRadius(10)
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 8, bottom: 8 })
  }

  @Builder
  buildGroupContent() {
    if (this.showSearchResults) {
      if (this.searchResults.length > 0) {
        AZOrderedList({
          dataSource: this.searchResults,
          config: { showIndexBar: false },
          onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
            this.handleSelectGroup(item.extraData);
          }
        })
      } else {
        Column() {
          Text($r('app.string.no_results_found'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ top: 50 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    } else {
      AZOrderedList({
        dataSource: this.groupListItems,
        config: { showIndexBar: true },
        onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
          this.handleSelectGroup(item.extraData);
        }
      })
    }
  }


  // Empty state
  @Builder
  buildEmptyState() {
    Column() {
      Text($r('app.string.no_groups_title'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)// Figma: #999999
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })

      Text($r('app.string.no_groups_desc'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorTertiary)// Figma: #CCCCCC
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 32, right: 32 })
  }

  // Loading state
  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
      Text($r('app.string.loading_groups'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorSecondary)// Figma: #999999
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private handleBack() {
    if (this.onBack) {
      this.onBack();
    }
  }

  private handleSelectGroup(group: ContactInfo): void {
    console.log('[MyGroupPage] handleSelectGroup - Returning with group:', group.nickname);


    if (this.onShowProfile) {
      this.onShowProfile(group);
    }
  }

  private loadGroupList() {
    this.isLoading = true;
    this.groupStore.loadJoinedGroups(new CompletionHandlerAdapter(() => {
      this.convertGroupsToAZOrderedListItems();
      this.isLoading = false;
    }, (code: number, desc: string) => {
      console.error('Failed to load group list:', code, desc);
      this.isLoading = false;
    }));
  }

  private convertGroupsToAZOrderedListItems(): void {
    const items: AZOrderedListItem<ContactInfo>[] = [];

    const groups = this.groupState.joinedGroupList;
    for (let i = 0; i < groups.length; i++) {
      const group: GroupInfo = groups[i];
      if (group) {
        const wrapped = new ContactInfo(group.groupID);
        wrapped.nickname = group.groupName;
        wrapped.avatarURL = group.avatarURL;
        items.push({
          key: group.groupID || `group_${i}`,
          label: group.groupName || group.groupID || '',
          avatarUrl: group.avatarURL,
          extraData: wrapped
        });
      }
    }

    this.groupListItems = items;
    console.log('[MyGroupPage] Converted groups to AZOrderedList items:', items.length);
  }

  private performSearch() {
    if (this.searchKeyword.trim().length === 0) {
      this.clearSearch();
      return;
    }

    this.searchResults = this.searchGroups(this.searchKeyword);
    this.showSearchResults = true;
  }

  private clearSearch() {
    this.searchResults = [];
    this.showSearchResults = false;
  }

  private searchGroups(keyword: string): AZOrderedListItem<ContactInfo>[] {
    if (!keyword.trim()) {
      return [];
    }

    const result: AZOrderedListItem<ContactInfo>[] = [];
    const lowerKeyword = keyword.toLowerCase();

    this.groupListItems.forEach(item => {
      const group = item.extraData;
      if ([group.nickname, group.userID]
        .some((value?: string) => value?.toLowerCase().includes(lowerKeyword) ?? false)) {
        result.push(item);
      }
    });

    return result;
  }

}