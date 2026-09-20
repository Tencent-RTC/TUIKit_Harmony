import { Avatar, AvatarContentType, AvatarSize, TextUtils, ThemeState, Toast } from '../../basecomponent/Index';
import { PinyinUtils } from '../../basecomponent/utils/PinyinUtils';

export interface UserPickerData<T> {
  key: string;
  label: string;
  avatarUrl?: string;
  extraData: T;
}

export interface UserPickerState<T> {
  selectedItems: UserPickerData<T>[];
}

// Internal interface for grouped data
interface UserPickerGroup {
  letter: string;
  items: UserPickerData<ESObject>[];
}

@Component
export struct UserPicker {
  dataSource: UserPickerData<ESObject>[] = [];
  state?: UserPickerState<ESObject> = undefined;
  defaultSelectedItems: string[] = [];
  lockedItems: string[] = [];
  maxCount?: number = undefined;
  onMaxCountExceed?: (selectedItems: UserPickerData<ESObject>[]) => void = undefined;
  onSelectedChanged?: (selectedItems: UserPickerData<ESObject>[]) => void = undefined;
  onReachEnd?: () => void = undefined;
  
  showNavigationBar?: boolean = false;
  showBackButton?: boolean = false;
  showSearchBar?: boolean = false;
  showSelectedTags?: boolean = false;
  title: string | Resource = '';
  confirmButtonText: string | Resource = 'Next';
  showHeaderConfirm?: boolean = true;
  showBottomConfirm?: boolean = false;
  allowEmptyConfirm?: boolean = false;
  onCancel?: () => void = undefined;
  
  // Internal state
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State private selectedKeys: Set<string> = new Set();
  @State private selectedKeysOrder: string[] = [];
  @State private searchKeyword: string = '';
  @State private showCenterLetter: string = '';
  private listScroller: Scroller = new Scroller();
  private reachEndTimer: number | null = null;

  aboutToAppear(): void {
    console.log('[UserPicker] aboutToAppear - maxCount:', this.maxCount, 'dataSource length:', this.dataSource.length);
    
    // Initialize selected items from defaultSelectedItems
    this.selectedKeys = new Set(this.defaultSelectedItems);
    this.selectedKeysOrder = [...this.defaultSelectedItems];

    // Initialize state if provided
    if (this.state) {
      this.updateStateSelectedItems();
    }
  }
  
  private updateStateSelectedItems(): void {
    if (!this.state) return;
    
    const selectedItems: UserPickerData<ESObject>[] = [];
    this.selectedKeysOrder.forEach((key: string) => {
      const item: UserPickerData<ESObject> | undefined = this.dataSource.find((d: UserPickerData<ESObject>) => d.key === key);
      if (item) {
        selectedItems.push(item);
      }
    });
    
    this.state.selectedItems = selectedItems;
  }

  build() {
    Column() {
      if (this.showNavigationBar) {
        this.TitleBarBuilder()
        Divider()
          .height(1)
          .color(this.themeState.colors.strokeColorSecondary)
      }

      if (this.showSearchBar) {
        this.SearchBarBuilder()
      }

      if (this.showSelectedTags && this.selectedKeysOrder.length > 0 && (this.maxCount === undefined || this.maxCount > 1)) {
        this.SelectedTagsBuilder()
        Divider()
          .height(0.5)
          .color(this.themeState.colors.strokeColorSecondary)
      }

      this.buildUserList()

      if (this.showBottomConfirm) {
        this.BottomConfirmBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
  
  @Builder
  BottomConfirmBuilder() {
    Row() {
      Blank()

      Button() {
        Row({ space: 2 }) {
          Text(this.confirmButtonText)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeState.colors.textColorButton)

          Text(`(${this.selectedKeysOrder.length})`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeState.colors.textColorButton)
        }
      }
      .height(36)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.selectedKeysOrder.length > 0
        ? this.themeState.colors.buttonColorPrimaryDefault
        : this.themeState.colors.buttonColorPrimaryDisabled)
      .borderRadius(18)
      .enabled(this.selectedKeysOrder.length > 0 || this.allowEmptyConfirm)
      .onClick(() => {
        if ((this.selectedKeysOrder.length > 0 || this.allowEmptyConfirm) && this.onSelectedChanged) {
          this.onSelectedChanged(this.getSelectedItems());
        }
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: this.themeState.colors.strokeColorSecondary })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SearchBarBuilder() {
    Row() {
      Row() {
        Image($rawfile('search/search_icon.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorTertiary)
          .margin({ right: 8 })

        TextInput({
          text: $$this.searchKeyword,
          placeholder: $r('app.string.search_placeholder')
        })
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorPrimary)
          .placeholderColor(this.themeState.colors.textColorTertiary)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.updateSearchResults(value);
          })

        if (this.searchKeyword.length > 0) {
          Image($rawfile('contactlist/contact_del.svg'))
            .width(16)
            .height(16)
            .fillColor(this.themeState.colors.textColorSecondary)
            .onClick(() => {
              this.updateSearchResults('');
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
  buildUserList() {
    if (this.searchKeyword.trim().length > 0 && this.getFilteredDataSource().length === 0) {
      Column() {
        Text($r('app.string.no_results_found'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorSecondary)
          .margin({ top: 50 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      this.GroupedUserListBuilder()
    }
  }
  
  @Builder
  GroupedUserListBuilder() {
    Stack() {
      List({ scroller: this.listScroller }) {
        ForEach(this.getGroupedDataSource(), (group: UserPickerGroup) => {
          ListItemGroup() {
            ListItem() {
              Row() {
                Text(group.letter)
                  .fontSize(14)
                  .fontWeight(600)
                  .fontColor(this.themeState.colors.textColorPrimary)
              }
              .width('100%')
              .height(32)
              .padding({ left: 16, right: 16 })
              .backgroundColor(this.themeState.colors.bgColorDialog)
              .justifyContent(FlexAlign.Start)
              .alignItems(VerticalAlign.Center)
            }

            ForEach(group.items, (userData: UserPickerData<ESObject>) => {
              ListItem() {
                this.CustomUserItemBuilder(userData)
              }
            })
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd(() => {
        console.log('[UserPicker] Main list reached end');
        this.handleReachEnd();
      })

      if (this.getGroupedDataSource().length > 1) {
        this.IndexBarBuilder()
      }

      if (this.showCenterLetter.length > 0) {
        this.CenterLetterBuilder()
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  @Builder
  CustomUserItemBuilder(userData: UserPickerData<ESObject>) {
    Row() {
      Checkbox({
        name: `checkbox_${userData.key}`,
        group: 'userSelection'
      })
        .select(this.selectedKeys.has(userData.key))
        .selectedColor(this.themeState.colors.textColorLink)
        .unselectedColor(this.themeState.colors.strokeColorSecondary)
        .width(16)
        .height(16)
        .margin({ right: 10 })
        .enabled(!this.lockedItems.includes(userData.key))
        .hitTestBehavior(HitTestMode.None)

      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: userData.avatarUrl,
          name: userData.label,
        },
        avatarSize: AvatarSize.M,
      })
      
      Text(userData.label)
        .fontSize(14)
        .fontWeight(400)
        .fontFamily('PingFang SC')
        .fontColor(this.lockedItems.includes(userData.key) ? 
          this.themeState.colors.textColorTertiary : 
          this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 13 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .onClick(() => {
      if (!this.lockedItems.includes(userData.key)) {
        console.log('[UserPicker] Row clicked - key:', userData.key, 'maxCount:', this.maxCount);
        if (this.maxCount === 1) {
          this.handleItemClick(userData);
        } else {
          const isSelected: boolean = this.selectedKeys.has(userData.key);
          console.log('[UserPicker] Multi-select mode - toggling selection for:', userData.key, 'currently selected:', isSelected);
          this.handleItemToggle(userData, !isSelected);
        }
      }
    })
  }
  
  private handleItemClick(item: UserPickerData<ESObject>): void {
    if (this.lockedItems.includes(item.key)) return;
    
    console.log('[UserPicker] handleItemClick - single select mode for:', item.key);
    
    this.selectedKeys.clear();
    this.selectedKeys.add(item.key);
    this.selectedKeysOrder = [item.key];
    
    this.updateStateSelectedItems();
  }
  
  private handleItemToggle(item: UserPickerData<ESObject>, isSelected: boolean): void {
    console.log('[UserPicker] handleItemToggle - key:', item.key, 'isSelected:', isSelected, 'current selectedKeys:', Array.from(this.selectedKeys));
    
    if (isSelected) {
      // Check if already selected to prevent duplicates
      if (this.selectedKeys.has(item.key)) {
        console.log('[UserPicker] Item already selected, skipping:', item.key);
        return;
      }
      
      // Check max count
      if (this.maxCount !== undefined && this.selectedKeysOrder.length >= this.maxCount) {
        const selectedItems: UserPickerData<ESObject>[] = this.getSelectedItems();
        if (this.onMaxCountExceed) {
          this.onMaxCountExceed(selectedItems);
        }
        return;
      }
      
      this.selectedKeys.add(item.key);
      this.selectedKeysOrder.push(item.key);
    } else {
      // Check if not selected to prevent unnecessary operations
      if (!this.selectedKeys.has(item.key)) {
        console.log('[UserPicker] Item not selected, skipping removal:', item.key);
        return;
      }
      
      this.selectedKeys.delete(item.key);
      const index: number = this.selectedKeysOrder.indexOf(item.key);
      if (index > -1) {
        this.selectedKeysOrder.splice(index, 1);
      }
    }
    
    console.log('[UserPicker] After toggle - selectedKeys:', Array.from(this.selectedKeys), 'selectedKeysOrder:', this.selectedKeysOrder);
    this.updateStateSelectedItems();

    if (!this.showNavigationBar && this.onSelectedChanged) {
      this.onSelectedChanged(this.getSelectedItems());
    }
  }
  
  private getSelectedItems(): UserPickerData<ESObject>[] {
    const items: UserPickerData<ESObject>[] = [];
    this.selectedKeysOrder.forEach((key: string) => {
      const item: UserPickerData<ESObject> | undefined = this.dataSource.find((d: UserPickerData<ESObject>) => d.key === key);
      if (item) {
        items.push(item);
      }
    });
    return items;
  }
  
  private updateSearchResults(keyword: string): void {
    this.searchKeyword = keyword;
  }

  private getFilteredDataSource(): UserPickerData<ESObject>[] {
    const keyword = this.searchKeyword.trim().toLowerCase();
    if (!keyword) {
      return this.dataSource;
    }
    return this.dataSource.filter((item: UserPickerData<ESObject>) => {
      return item.label.toLowerCase().includes(keyword) || item.key.toLowerCase().includes(keyword);
    });
  }

  private getGroupedDataSource(): UserPickerGroup[] {
    // Group items by first letter
    const grouped: Map<string, UserPickerData<ESObject>[]> = new Map<string, UserPickerData<ESObject>[]>();
    
    this.getFilteredDataSource().forEach((item: UserPickerData<ESObject>) => {
      const firstLetter = this.getFirstLetter(item.label);
      if (!grouped.has(firstLetter)) {
        grouped.set(firstLetter, []);
      }
      grouped.get(firstLetter)!.push(item);
    });
    
    // Sort items within each group and create UserPickerGroup objects
    const sortedGroups: UserPickerGroup[] = [];
    grouped.forEach((groupItems: UserPickerData<ESObject>[], letter: string) => {
      const sortedItems: UserPickerData<ESObject>[] = groupItems.sort((a: UserPickerData<ESObject>, b: UserPickerData<ESObject>) => a.label.localeCompare(b.label));
      sortedGroups.push({ letter, items: sortedItems });
    });
    
    // Sort groups: letters first, then '#'
    return sortedGroups.sort((a: UserPickerGroup, b: UserPickerGroup) => {
      if (a.letter === '#' && b.letter !== '#') return 1;
      if (a.letter !== '#' && b.letter === '#') return -1;
      return a.letter.localeCompare(b.letter);
    });
  }
  
  private getFirstLetter(name: string): string {
    return PinyinUtils.getSortLetter(name);
  }

  @Builder
  IndexBarBuilder() {
    Column() {
      ForEach(this.getGroupedDataSource(), (group: UserPickerGroup) => {
        Text(group.letter)
          .fontSize(10)
          .fontColor(this.themeState.colors.textColorLink)
          .fontFamily('SF Pro Text')
          .margin({ bottom: 2 })
          .onClick(() => {
            this.scrollToSection(group.letter);
            this.showCenterLetter = group.letter;
            setTimeout(() => {
              this.showCenterLetter = '';
            }, 1000);
          })
      }, (group: UserPickerGroup) => group.letter)
    }
    .width(24)
    .justifyContent(FlexAlign.Center)
    .position({ x: '100%', y: '50%' })
    .translate({ x: -32, y: '-50%' })
  }

  @Builder
  CenterLetterBuilder() {
    Row() {
      Text(this.showCenterLetter)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
    }
    .width(80)
    .height(80)
    .backgroundColor(Color.Black)
    .opacity(0.8)
    .borderRadius(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .position({ x: '50%', y: '50%' })
    .translate({ x: '-50%', y: '-50%' })
  }

  private scrollToSection(letter: string): void {
    const groups = this.getGroupedDataSource();
    const groupIndex = groups.findIndex((group: UserPickerGroup) => group.letter === letter);
    if (groupIndex < 0) {
      return;
    }

    let scrollPosition = 0;
    for (let index = 0; index < groupIndex; index++) {
      scrollPosition += 32 + groups[index].items.length * 56;
    }
    this.listScroller.scrollTo({
      xOffset: 0,
      yOffset: scrollPosition,
      animation: {
        duration: 300,
        curve: Curve.EaseInOut
      }
    });
  }
  
  private handleReachEnd(): void {
    if (this.reachEndTimer) {
      clearTimeout(this.reachEndTimer);
    }
    
    this.reachEndTimer = setTimeout(() => {
      console.log('[UserPicker] Reach end callback triggered');
      if (this.onReachEnd) {
        this.onReachEnd();
      }
      this.reachEndTimer = null;
    }, 300); 
  }

  @Builder
  TitleBarBuilder() {
    Stack() {
      Row() {
        if (this.showBackButton) {
          Button() {
            Image($rawfile('basecomponent/common_back_icon.svg'))
              .width(16)
              .height(16)
              .fillColor(this.themeState.colors.textColorSecondary)
          }
          .type(ButtonType.Normal)
          .backgroundColor(Color.Transparent)
          .width(44)
          .height(44)
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel();
            }
          })
        } else {
          Text($r('app.string.cancel_button'))
            .fontSize(16)
            .fontWeight(400)
            .fontColor(this.themeState.colors.textColorLink)
            .onClick(() => {
              if (this.onCancel) {
                this.onCancel();
              }
            })
        }

        Blank()

        if (this.showHeaderConfirm) {
          Text(this.confirmButtonText)
            .fontSize(16)
            .fontWeight(400)
            .fontColor(this.themeState.colors.textColorLink)
            .onClick(() => {
              if ((this.selectedKeysOrder.length > 0 || this.allowEmptyConfirm) && this.onSelectedChanged) {
                const selectedItems: UserPickerData<ESObject>[] = this.getSelectedItems();
                this.onSelectedChanged(selectedItems);
              }
            })
        } else {
          Blank()
            .width(44)
        }
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .align(Alignment.Center)
    }
    .width('100%')
    .height(56)
    .margin({ top: 24 })
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  SelectedTagsBuilder() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.getSelectedItems(), (user: UserPickerData<ESObject>) => {
          this.UserTagBuilder(user)
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(40)
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  UserTagBuilder(user: UserPickerData<ESObject>) {
    Stack() {
      if (user.avatarUrl && user.avatarUrl.length > 0) {
        Image(user.avatarUrl)
          .width(32)
          .height(32)
          .borderRadius(16)
          .objectFit(ImageFit.Cover)
      } else {
        Circle()
          .width(32)
          .height(32)
          .fill(this.themeState.colors.textColorLink)

        Text(TextUtils.getAvatarLetter(user.label))
          .fontSize(14)
          .fontWeight(500)
          .fontColor(this.themeState.colors.bgColorOperate)
      }

      Row() {
        Image($rawfile('contactlist/contact_del.svg'))
          .width(12)
          .height(12)
          .fillColor(this.themeState.colors.textColorButton)
      }
      .width(12)
      .height(12)
      .backgroundColor(this.themeState.colors.bgColorTopBar)
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .position({ x: '100%', y: 0 })
      .translate({ x: -8, y: -4 })
      .onClick(() => {
        this.handleItemToggle(user, false);
      })
    }
    .width(32)
    .height(32)
    .margin({ right: 8 })
  }
}
