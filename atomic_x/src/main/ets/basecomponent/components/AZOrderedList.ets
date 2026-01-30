import { TextUtils, ThemeState, LanguageState } from '../Index';
import { PinyinUtils } from '../utils/PinyinUtils';

export interface AZOrderedListItem<T> {
  key: string;
  label: string;
  avatarUrl?: string;
  extraData: T;
}

export interface AZOrderedListConfig {
  showIndexBar?: boolean;
}

interface AZGroup<T> {
  letter: string;
  items: AZOrderedListItem<T>[];
}

@Component
export struct AZOrderedList {
  private static readonly ITEM_HEIGHT: number = 56;
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly HORIZONTAL_PADDING: number = 16;
  private static readonly INDEX_BAR_WIDTH: number = 24;
  private static readonly HEADER_HEIGHT: number = 32;

  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();

  @Builder
  HeaderBuilder() {

  }

  @Builder
  FooterBuilder() {

  }
  // Parameters following Android AZOrderedList
  @Prop @Watch('onDataSourceChanged') dataSource: AZOrderedListItem<ESObject>[] = [];
  config: AZOrderedListConfig = { showIndexBar: true };
  @BuilderParam header?: () => void = this.HeaderBuilder ;
  @BuilderParam footer?: () => void = this.FooterBuilder ;
  onItemClick?: (item: AZOrderedListItem<ESObject>) => void;

  // Internal state
  @State private groups: AZGroup<ESObject>[] = [];
  @State private indexLetters: string[] = [];
  @State private showCenterLetter: string = '';

  // Scroller for navigation
  private listScroller: Scroller = new Scroller();

  private static getFirstLetter(name: string): string {
    if (!name || name.length === 0) return '#';
    return PinyinUtils.getSortLetter(name);
  }

  private static groupAndSort<T>(items: AZOrderedListItem<T>[]): AZGroup<T>[] {
    // Group items by first letter
    const grouped = new Map<string, AZOrderedListItem<T>[]>();
    
    items.forEach(item => {
      const letter = AZOrderedList.getFirstLetter(item.label);
      if (!grouped.has(letter)) {
        grouped.set(letter, []);
      }
      grouped.get(letter)!.push(item);
    });
    
    // Sort items within each group and create AZGroup objects
    const sortedGroups: AZGroup<T>[] = [];
    grouped.forEach((groupItems, letter) => {
      const sortedItems = groupItems.sort((a, b) => a.label.localeCompare(b.label));
      sortedGroups.push({ letter, items: sortedItems });
    });
    
    // Sort groups: letters first, then '#'
    return sortedGroups.sort((a, b) => {
      if (a.letter === '#' && b.letter !== '#') return 1;
      if (a.letter !== '#' && b.letter === '#') return -1;
      return a.letter.localeCompare(b.letter);
    });
  }

  aboutToAppear(): void {
    this.updateGroupsAndIndexes();
    console.log('[AZOrderedList] aboutToAppear - Items:', this.dataSource?.length || 0);
  }

  onDataSourceChanged(): void {
    // Force update by creating new array reference for internal groups
    console.log('[AZOrderedList] dataSource changed - Items:', this.dataSource?.length || 0);
    this.updateGroupsAndIndexes();
  }

  private updateGroupsAndIndexes(dataSource?: AZOrderedListItem<ESObject>[]): void {
    const sourceData: AZOrderedListItem<ESObject>[] = dataSource || this.dataSource;
    if (sourceData && sourceData.length > 0) {
      this.groups = AZOrderedList.groupAndSort(sourceData);
      this.indexLetters = this.groups.map((group: AZGroup<ESObject>) => group.letter);
    } else {
      this.groups = [];
      this.indexLetters = [];
    }
  }

  build() {
    Stack() {
      // Main list with header and footer inside scroll container
      this.ListBuilder()

      // Index bar
      if (this.config.showIndexBar && this.indexLetters.length > 1) {
        this.IndexBarBuilder()
      }

      // Center letter indicator
      if (this.showCenterLetter && this.showCenterLetter.length > 0) {
        this.CenterLetterBuilder()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ListBuilder() {
    Scroll(this.listScroller) {
      Column({ space: 0 }) {
        // Header section - inside scroll container
        if (this.header) {
          this.header()
        }
        
        ForEach(this.groups, (group: AZGroup<ESObject>) => {
          // Group header (sticky header effect)
          this.DefaultAZHeaderBuilder(group.letter)
          
          // Group items
          ForEach(group.items, (item: AZOrderedListItem<ESObject>) => {
            this.DefaultItemBuilder(item)
          })
        })
        
        // Footer section - inside scroll container
        if (this.footer) {
          this.footer()
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.TopStart)
    .onScrollFrameBegin((offset: number, state: ScrollState) => {
      // Handle scroll for index bar tracking
      return { offsetRemain: offset };
    })
  }

  @Builder
  DefaultAZHeaderBuilder(letter: string) {
    Row() {
      Text(letter)
        .fontSize(14)
        .fontWeight(600)
        .fontColor(this.themeState.colors.textColorPrimary)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
    }
    .width('100%')
    .height(AZOrderedList.HEADER_HEIGHT)
    .padding({ left: AZOrderedList.HORIZONTAL_PADDING, right: AZOrderedList.HORIZONTAL_PADDING })
    .backgroundColor(this.themeState.colors.bgColorDialog)
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  DefaultItemBuilder(item: AZOrderedListItem<ESObject>) {
    Row({ space: 13 }) {
      // Avatar
      Stack() {
        if (item.avatarUrl && item.avatarUrl.length > 0) {
          Image(item.avatarUrl)
            .width(AZOrderedList.AVATAR_SIZE)
            .height(AZOrderedList.AVATAR_SIZE)
            .borderRadius(AZOrderedList.AVATAR_SIZE / 2)
            .objectFit(ImageFit.Cover)
        } else {
          Circle()
            .width(AZOrderedList.AVATAR_SIZE)
            .height(AZOrderedList.AVATAR_SIZE)
            .fill(this.themeState.colors.textColorLink)

          Text(TextUtils.getAvatarLetter(item.label))
            .fontSize(16)
            .fontWeight(500)
            .fontColor(this.themeState.colors.textColorButton)
        }
      }

      // Label
      Text(item.label)
        .fontSize(14)
        .fontWeight(400)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .direction(this.languageState.getLayoutDirection() === LayoutDirection.RTL ? Direction.Rtl : Direction.Ltr)
    }
    .width('100%')
    .height(AZOrderedList.ITEM_HEIGHT)
    .padding({
      left: AZOrderedList.HORIZONTAL_PADDING,
      right: AZOrderedList.HORIZONTAL_PADDING
    })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(item);
      }
    })
  }

  @Builder
  IndexBarBuilder() {
    Column() {
      ForEach(this.indexLetters, (letter: string) => {
        // 统一样式，恢复点击事件，但不高亮
        Text(letter)
          .fontSize(10)
          .fontColor(this.themeState.colors.textColorLink)
          .fontFamily('SF Pro Text')
          .margin({ bottom: 2 })
          .onClick(() => {
            this.scrollToSection(letter);
            // 显示中心字母提示
            this.showCenterLetter = letter;
            setTimeout(() => {
              this.showCenterLetter = '';
            }, 1000);
          })
      })
    }
    .width(AZOrderedList.INDEX_BAR_WIDTH)
    .justifyContent(FlexAlign.Center)
    .position({ 
      x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? '0%' : '100%', 
      y: '50%' 
    })
    .translate({ 
      x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? 32 : -32, 
      y: '-50%' 
    })
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

  // Index bar helper methods
  private scrollToSection(letter: string): void {
    
    // Find the group index
    const groupIndex = this.groups.findIndex((group: AZGroup<ESObject>) => group.letter === letter);
    if (groupIndex >= 0) {
      // Calculate scroll position
      let scrollPosition = 0;
      
      // Add header height if exists
      if (this.header) {
        scrollPosition += 220; // Header height estimation
      }
      
      // Add heights of previous groups
      for (let i = 0; i < groupIndex; i++) {
        scrollPosition += AZOrderedList.HEADER_HEIGHT; // Group header
        scrollPosition += this.groups[i].items.length * AZOrderedList.ITEM_HEIGHT; // Group items
      }
      
      // Scroll to the calculated position
      this.listScroller.scrollTo({ 
        xOffset: 0, 
        yOffset: scrollPosition, 
        animation: {
          duration: 300,
          curve: Curve.EaseInOut
        }
      });
    }
    
    console.log('[AZOrderedList] Scroll to section:', letter);
  }
}
