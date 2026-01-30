import { Avatar, AvatarContentType, AvatarSize, TextUtils, ThemeState, Toast } from '../../basecomponent/Index';
import { AZOrderedList, AZOrderedListItem, AZOrderedListConfig } from '../../basecomponent/components/AZOrderedList';

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
  
  // UI customization (Harmony-specific)
  showNavigationBar?: boolean = false;
  showSelectedTags?: boolean = false;
  title: string | Resource = '';
  confirmButtonText: string | Resource = 'Next';
  onCancel?: () => void = undefined;
  
  // Internal state
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State private selectedKeys: Set<string> = new Set();
  @State private selectedKeysOrder: string[] = [];
  @State private searchKeyword: string = '';
  @State private showSearchResults: boolean = false;
  @State private searchResults: AZOrderedListItem<UserPickerData<ESObject>>[] = [];
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

      if (this.showSelectedTags && this.selectedKeysOrder.length > 0 && (this.maxCount === undefined || this.maxCount > 1)) {
        this.SelectedTagsBuilder()
        Divider()
          .height(0.5)
          .color(this.themeState.colors.strokeColorSecondary)
      }

      // Main content with AZOrderedList
      this.buildUserList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
  
  @Builder
  buildUserList() {
    if (this.showSearchResults) {
      if (this.searchResults.length > 0) {
        List() {
          ForEach(this.searchResults, (item: AZOrderedListItem<UserPickerData<ESObject>>) => {
            ListItem() {
              this.CustomUserItemBuilder(item.extraData)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .onReachEnd(() => {
          console.log('[UserPicker] Search results reached end');
          this.handleReachEnd();
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
      // Use custom grouped list with checkboxes support
      this.GroupedUserListBuilder()
    }
  }
  
  @Builder
  GroupedUserListBuilder() {
    List() {
      ForEach(this.getGroupedDataSource(), (group: UserPickerGroup) => {
        ListItemGroup() {
          // Group header
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
          
          // Group items
          ForEach(group.items, (userData: UserPickerData<ESObject>) => {
            ListItem() {
              this.CustomUserItemBuilder(userData)
            }
          })
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .onReachEnd(() => {
      console.log('[UserPicker] Main list reached end');
      this.handleReachEnd();
    })
  }
  
  @Builder
  CustomUserItemBuilder(userData: UserPickerData<ESObject>) {
    Row({ space: 13 }) {
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
      
      if (this.maxCount !== 1) {
        Checkbox({
          name: `checkbox_${userData.key}`,
          group: 'userSelection'
        })
          .select(this.selectedKeys.has(userData.key))
          .selectedColor(this.themeState.colors.textColorLink)
          .unselectedColor(this.themeState.colors.strokeColorSecondary)
          .width(20)
          .height(20)
          .enabled(!this.lockedItems.includes(userData.key))
          .hitTestBehavior(HitTestMode.None) // Ignore touch events, let them pass through to Row
      }
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
    
    if (this.onSelectedChanged) {
      this.onSelectedChanged([item]);
    }
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
  
  private getGroupedDataSource(): UserPickerGroup[] {
    // Group items by first letter
    const grouped: Map<string, UserPickerData<ESObject>[]> = new Map<string, UserPickerData<ESObject>[]>();
    
    this.dataSource.forEach((item: UserPickerData<ESObject>) => {
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
    if (!name || name.length === 0) return '#';
    const firstChar = name[0].toUpperCase();
    return /^[A-Z]$/.test(firstChar) ? firstChar : '#';
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
    Column() {
      Row() {
        Text($r('app.string.cancel_button'))
          .fontSize(16)
          .fontWeight(400)
          .fontColor(this.themeState.colors.textColorLink)
          .onClick(() => {
            if (this.onCancel) {
              this.onCancel();
            }
          })

        Blank()

        Text(this.title)
          .fontSize(20)
          .fontWeight(600)
          .fontColor(this.themeState.colors.textColorPrimary)

        Blank()

        if (this.maxCount !== 1) {
          Text(this.confirmButtonText)
            .fontSize(16)
            .fontWeight(400)
            .fontColor(this.selectedKeysOrder.length > 0 ? 
              this.themeState.colors.textColorLink : 
            this.themeState.colors.textColorSecondary)
            .enabled(this.selectedKeysOrder.length > 0)
            .onClick(() => {
              if (this.selectedKeysOrder.length > 0 && this.onSelectedChanged) {
                const selectedItems: UserPickerData<ESObject>[] = this.getSelectedItems();
                this.onSelectedChanged(selectedItems);
              }
            })
        } else {
          Text('')
            .width(60)
        }
      }
      .width('100%')
      .height(44)
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Text(`${this.selectedKeysOrder.length}/${this.maxCount !== undefined ? this.maxCount : 512}`)
          .fontSize(12)
          .fontWeight(400)
          .fontColor(this.themeState.colors.textColorTertiary)
      }
      .width('100%')
      .height(30)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(74)
    .padding({ left: 16, right: 16 })
    .margin({ top: 22 })
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
