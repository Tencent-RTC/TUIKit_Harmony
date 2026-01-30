import { ErrorInfo, ContactInfo, ContactListState, ContactListStore } from '@tencentcloud/atomicxcore';
import { PinyinUtils } from '../../../basecomponent/utils/PinyinUtils';
import { AppBuilderConfig, TextUtils, ThemeState } from '../../../basecomponent/Index';
import { AZOrderedList, AZOrderedListItem, AZOrderedListConfig } from '../../../basecomponent/components/AZOrderedList';

@Component
export struct GroupListView {
  onBack?: () => void;
  // Callback function
  onShowProfile?: (group: ContactInfo) => void;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink contactListStore: ContactListStore;
  @State private contactListState: ContactListState = this.contactListStore.state;
  @State private isLoading: boolean = true;
  @State private searchKeyword: string = '';
  @State private showSearchResults: boolean = false;
  @State private searchResults: AZOrderedListItem<ContactInfo>[] = [];
  @State private groupListItems: AZOrderedListItem<ContactInfo>[] = [];

  aboutToAppear() {
    console.info('MyGroupPage aboutToAppear');
    this.contactListState = this.contactListStore.state;
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
      // Navigation bar
      this.buildNavigationBar()
      Stack() {
        if (this.isLoading) {
          this.buildLoadingState()
        } else if (this.contactListState.joinedGroupDataSource.totalCount() === 0) {
          this.buildEmptyState()
        } else {
          this.buildGroupContent()
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
      Row() {

        Row() {
          Image($rawfile('contactlist/back_arrow.svg'))
            .width(24)
            .height(24)
            .fillColor(this.themeState.colors.textColorLink)

          Text($r('app.string.back_button'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorLink)
            .margin({ left: 8 })
        }
        .onClick(() => this.handleBack())


        Text($r('app.string.my_group'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeState.colors.textColorPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)


        Text($r('app.string.done_button'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeState.colors.textColorLink)
          .opacity(0)
      }
      .width('100%')
      .height(56)
      .padding({ left: 10, right: 10 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

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
        Image($rawfile('contactlist/search_icon.svg'))
          .width(16)
          .height(16)
          .fillColor(this.themeState.colors.textColorSecondary) // Figma: #DADADA

        TextInput({ placeholder: $r('app.string.search_placeholder') })
          .fontSize(17)
          .fontColor(this.themeState.colors.textColorPrimary)// Figma: rgba(0, 0, 0, 0.9)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.performSearch();
          })
      }
      .width('100%')
      .height(36)
      .backgroundColor(this.themeState.colors.bgColorInput) // Figma: rgba(249, 249, 249, 0.94)
      .borderRadius(10)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width(358)
    .justifyContent(FlexAlign.Center)
    .alignSelf(ItemAlign.Center)
    .margin({ top: 16, bottom: 16 })
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
    console.log('[MyGroupPage] handleSelectGroup - Returning with group:', group.title);


    if (this.onShowProfile) {
      this.onShowProfile(group);
    }
  }

  private async loadGroupList() {
    try {
      this.isLoading = true;
      await this.contactListStore.fetchJoinedGroupList();
      
      this.convertGroupsToAZOrderedListItems();

    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to load group list:', error.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  private convertGroupsToAZOrderedListItems(): void {
    const items: AZOrderedListItem<ContactInfo>[] = [];
    
    for (let i = 0; i < this.contactListState.joinedGroupDataSource.totalCount(); i++) {
      const group = this.contactListState.joinedGroupDataSource.getData(i) as ContactInfo;
      if (group) {
        items.push({
          key: group.contactID || `group_${i}`,
          label: group.title || group.contactID || '',
          avatarUrl: group.avatarURL,
          extraData: group
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
      if (item.label.toLowerCase().includes(lowerKeyword)) {
        result.push(item);
      }
    });

    return result;
  }

}