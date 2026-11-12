import { AtomicxNavigator, ThemeState } from '../../basecomponent/Index';
import { SearchListPage, FriendSearchInfo, GroupSearchInfo, MessageSearchResultItem } from '../pages/SearchListPage';

class SearchBackHolder {
  handler?: () => boolean;
}

interface SearchPageArgs {
  onContactSelect?: (contact: FriendSearchInfo) => void;
  onGroupSelect?: (group: GroupSearchInfo) => void;
  onMessageSelect?: (message: MessageSearchResultItem) => void;
  onConversationSelect?: (message: MessageSearchResultItem) => void;
  backHolder: SearchBackHolder;
}

@Builder
function SearchPageBuilder(args: Object) {
  SearchListPage({
    onContactSelect: (contact: FriendSearchInfo) => {
      AtomicxNavigator.pop();
      (args as SearchPageArgs).onContactSelect?.(contact);
    },
    onGroupSelect: (group: GroupSearchInfo) => {
      AtomicxNavigator.pop();
      (args as SearchPageArgs).onGroupSelect?.(group);
    },
    onMessageSelect: (message: MessageSearchResultItem) => {
      AtomicxNavigator.pop();
      (args as SearchPageArgs).onMessageSelect?.(message);
    },
    onConversationSelect: (message: MessageSearchResultItem) => {
      AtomicxNavigator.pop();
      (args as SearchPageArgs).onConversationSelect?.(message);
    },
    onBack: () => {
      AtomicxNavigator.pop();
    },
    onRegisterBackHandler: (handler: () => boolean) => {
      (args as SearchPageArgs).backHolder.handler = handler;
    },
    topInset: 8
  })
}

/**
 * SearchBar - Search Entry Component
 * 
 * This is a standalone search component that can be placed at the top of any page as a search entry.
 * All search logic is encapsulated internally, exposing only necessary callback interfaces.
 * 
 * Usage Example:
 * ```
 * SearchBar({
 *   onContactSelect: (contact) => { 
 *     // Handle contact selection
 *   },
 *   onGroupSelect: (group) => {
 *     // Handle group selection
 *   },
 *   onMessageSelect: (message) => {
 *     // Handle message selection
 *   }
 * })
 * ```
 */
@Component
export struct SearchBar {
  private static readonly SEARCH_HEIGHT: number = 40;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private searchDialogController: CustomDialogController | null = null;
  
  // Callback interfaces
  onContactSelect?: (contact: FriendSearchInfo) => void;
  onGroupSelect?: (group: GroupSearchInfo) => void;
  onMessageSelect?: (message: MessageSearchResultItem) => void;
  onConversationSelect?: (message: MessageSearchResultItem) => void;

  aboutToDisappear() {
    // Clean up dialog controller when component is destroyed
    if (this.searchDialogController) {
      this.searchDialogController.close();
      this.searchDialogController = null;
    }
  }

  build() {
    Row() {
      Row() {
        Image($rawfile('search/search_icon.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorTertiary)
          .margin({ right: 8 })

        Text($r('app.string.search_placeholder'))
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorTertiary)
      }
      .width('100%')
      .height(SearchBar.SEARCH_HEIGHT)
      .borderRadius(10)
      .backgroundColor(this.themeState.colors.bgColorInput)
      .padding({ left: 12, right: 12 })
      .onClick(() => {
        this.openSearch();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 8, bottom: 8 })
  }

  /**
   * Open search dialog
   */
  private openSearch(): void {
    console.info('[SearchBar] Opening search dialog');
    const backHolder = new SearchBackHolder();
    const pageArgs: SearchPageArgs = {
      onContactSelect: this.onContactSelect,
      onGroupSelect: this.onGroupSelect,
      onMessageSelect: this.onMessageSelect,
      onConversationSelect: this.onConversationSelect,
      backHolder: backHolder
    };
    if (AtomicxNavigator.push(wrapBuilder(SearchPageBuilder), pageArgs,
      (): boolean => backHolder.handler ? backHolder.handler() : false)) {
      return;
    }

    // Close existing dialog if any
    if (this.searchDialogController) {
      this.searchDialogController.close();
      this.searchDialogController = null;
    }

    // Create and open new search dialog
    this.searchDialogController = new CustomDialogController({
      builder: this.SearchDialogBuilder,
      autoCancel: false,
      alignment: DialogAlignment.Center,
      customStyle: true,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
      maskColor: 'rgba(0, 0, 0, 0)',
      cancel: () => {
        this.searchDialogController = null;
      }
    });

    this.searchDialogController.open();
  }

  @Builder
  SearchDialogBuilder() {
    Column() {
      SearchListPage({
        onContactSelect: (contact: FriendSearchInfo) => {
          // Trigger callback and close dialog
          if (this.onContactSelect) {
            this.onContactSelect(contact);
          }
          this.searchDialogController?.close();
          this.searchDialogController = null;
        },
        onGroupSelect: (group: GroupSearchInfo) => {
          // Trigger callback and close dialog
          if (this.onGroupSelect) {
            this.onGroupSelect(group);
          }
          this.searchDialogController?.close();
          this.searchDialogController = null;
        },
        onMessageSelect: (message: MessageSearchResultItem) => {
          // Trigger callback and close dialog
          if (this.onMessageSelect) {
            this.onMessageSelect(message);
          }
          this.searchDialogController?.close();
          this.searchDialogController = null;
        },
        onConversationSelect: (message: MessageSearchResultItem) => {
          // Trigger callback and close dialog
          if (this.onConversationSelect) {
            this.onConversationSelect(message);
          }
          this.searchDialogController?.close();
          this.searchDialogController = null;
        },
        onBack: () => {
          // Close dialog when back button is pressed
          this.searchDialogController?.close();
          this.searchDialogController = null;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
