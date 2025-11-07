import { Avatar, AvatarContentType, AvatarSize, ThemeState } from '../../../basecomponent/Index';
import { ErrorInfo, ContactInfo, ContactListState, ContactListStore, LoginStore, } from '@tencentcloud/atomicxcore';
import { ContactDetailPage } from './ContactDetailPage';
import { GroupDetailPage } from './GroupDetailPage';
import { C2CChatSetting } from '../../../chatsetting/pages/C2CChatSetting';
import { GroupChatSetting } from '../../../chatsetting/pages/GroupChatSetting';

export enum SearchResultType {
  USER = 'user',
  GROUP = 'group'
}

interface SearchResultItem {
  id: string;
  name: string;
  avatar: string;
  subtitle: string;
  type: SearchResultType;
  rawData: ContactInfo;
}

@CustomDialog
export struct AddContactDialog {
  private static readonly USER_ID: string = '';
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller: CustomDialogController;
  @State userIdInput: string = '';
  @State isSearching: boolean = false;
  @State hasSearched: boolean = false;
  @State searchResults: SearchResultItem[] = [];
  @State searchType: SearchResultType = SearchResultType.USER;
  initialSearchType?: SearchResultType;
  @State showDetailPage: boolean = false;
  @State selectedUserInfo: ContactInfo | null = null;
  @State selectedGroupInfo: ContactInfo | null = null;
  @State isAddingFriend: boolean = false;
  @State isJoiningGroup: boolean = false;
  // Callback function
  onCancel?: () => void;
  onSearchUser?: (keyword: string) => void;
  private contactListStore: ContactListStore = ContactListStore.create();
  @State private contactListState: ContactListState = this.contactListStore.state;

  setSearchType(type: SearchResultType) {
    this.searchType = type;
  }

  aboutToAppear() {
    console.info('[AddContactDialog] Dialog about to appear');
    if (this.initialSearchType) {
      this.searchType = this.initialSearchType;
    }
  }

  aboutToDisappear() {
    console.info('[AddContactDialog] Dialog about to disappear');
  }

  @Builder
  SeparatorBuilder() {
    Divider()
      .color(this.themeState.colors.strokeColorSecondary)
      .strokeWidth(0.5)
      .width('100%')
  }

  @Builder
  CancelButtonBuilder() {
    if (this.showDetailPage) {

      Row() {
        Image($rawfile('contactlist/back_arrow.svg'))
          .width(24)
          .height(24)
          .fillColor(this.themeState.colors.textColorLink)
          .margin({ right: 8 })

        Text($r('app.string.back_button'))
          .fontSize(17)
          .fontColor(this.themeState.colors.textColorLink)
          .fontFamily('PingFang SC')
      }
      .margin({ left: 16 })
      .onClick(() => {
        this.handleBackToSearch();
      })
    } else {

      Text($r('app.string.cancel'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorLink)
        .fontFamily('PingFang SC')
        .margin({ left: 30 })
        .onClick(() => {
          this.handleCancel();
        })
    }
  }

  @Builder
  TitleBuilder() {
    if (this.showDetailPage) {
      Text(this.selectedUserInfo ? $r('app.string.user_detail_title') : $r('app.string.group_detail_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')
        .letterSpacing(0.37)
    } else {
      Text(this.searchType === SearchResultType.USER ?
      $r('app.string.add_contacts_title') : $r('app.string.add_group_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')
        .letterSpacing(0.37)
    }
  }

  @Builder
  NavigationBarBuilder() {
    Row() {
      // Cancel/Back button
      Row() {
        this.CancelButtonBuilder()
      }
      .width(120)
      .height(74)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      // Title
      Row() {
        this.TitleBuilder()
      }
      .layoutWeight(1)
      .height(74)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // Right spacer
      Row()
        .width(120)
        .height(74)
    }
    .width('100%')
    .height(74)

    // Divider
    this.SeparatorBuilder()
  }

  @Builder
  UserIdDisplayBuilder() {

    Row() {
      Text($r('app.string.my_user_id_label'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')
        .textAlign(TextAlign.Center)
        .height(44)
      Text((LoginStore.shared().state.loginUserInfo?.userID ?? ""))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')
        .textAlign(TextAlign.Center)
        .height(44)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(44)
  }

  @Builder
  SearchTypeSelectorBuilder() {
    Row() {

      Row() {
        Text($r('app.string.search_users'))
          .fontSize(14)
          .fontColor(this.searchType === SearchResultType.USER ?
          this.themeState.colors.textColorLink :
          this.themeState.colors.textColorSecondary)
          .fontFamily('PingFang SC')
      }
      .height(32)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.searchType === SearchResultType.USER ? '#E3F2FD' : 'transparent')
      .borderRadius(16)
      .onClick(() => {
        this.searchType = SearchResultType.USER;
        if (this.hasSearched) {
          this.handleSearch();
        }
      })


      Row() {
        Text($r('app.string.search_groups'))
          .fontSize(14)
          .fontColor(this.searchType === SearchResultType.GROUP ? '#0365F9' : '#666666')
          .fontFamily('PingFang SC')
      }
      .height(32)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.searchType === SearchResultType.GROUP ? '#E3F2FD' : 'transparent')
      .borderRadius(16)
      .margin({ left: 8 })
      .onClick(() => {
        this.searchType = SearchResultType.GROUP;
        if (this.hasSearched) {
          this.handleSearch();
        }
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 8, bottom: 8 })
  }

  @Builder
  SearchFieldBuilder() {
    Row() {
      Image($rawfile('contactlist/search_icon.svg'))
        .width(16)
        .height(16)
        .fillColor(this.themeState.colors.textColorTertiary)
        .margin({ left: 16 })

      TextInput({
        placeholder: this.searchType === SearchResultType.USER ?
        $r('app.string.user_id_placeholder') :
        $r('app.string.group_id_placeholder'),
        text: this.userIdInput
      })
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .fontSize(17)
        .fontColor(this.themeState.colors.textColorPrimary)
        .placeholderColor(this.themeState.colors.textColorTertiary)// Figma: rgba(255, 255, 255, 0.3)
        .fontFamily('PingFang HK')
        .layoutWeight(1)
        .onChange((value: string) => {
          this.userIdInput = value;

          if (value.trim() === '') {
            this.hasSearched = false;
            this.searchResults = [];
          }
        })
        .onSubmit(() => {
          this.handleSearch();
        })
    }
    .height(36)
    .backgroundColor(this.themeState.colors.bgColorInput)
    .borderRadius(10)
    .padding({ left: 16, right: 16 })
    .margin({
      left: 16,
      right: 16,
      top: 16,
      bottom: 16
    })
  }

  @Builder
  SearchResultsBuilder() {
    if (this.hasSearched) {
      if (this.isSearching) {

        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#0365F9')

          Text($r('app.string.searching'))
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.searchResults.length === 0) {
        Blank();

        Column() {
          Image($rawfile('contactlist/contact_searchempty.svg'))
            .width(42)
            .height(42)
            .fillColor(this.themeState.colors.textColorSecondary)

          Text($r('app.string.no_users_found'))
            .fontSize(16)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ top: 19 })
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 16, right: 16 })

        Blank();

      } else {

        List() {
          ForEach(this.searchResults, (item: SearchResultItem) => {
            ListItem() {
              this.SearchResultItemBuilder(item)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
  }

  @Builder
  SearchResultItemBuilder(item: SearchResultItem) {
    Row() {
      // Avatar
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: item.avatar,
          name: item.name || item.id,
        },
        avatarSize: AvatarSize.M,
      })

      Column() {
        Row() {
          Text(item.name)
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (item.id) {
          Text(`ID: ${item.id}`)
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .margin({ left: 12, right: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({
      left: 18,
      right: 16,
      top: 12,
      bottom: 12
    })
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  build() {
    Column() {

      Column()
        .height(88)
        .backgroundColor(this.themeState.colors.bgColorMask)
        .onClick(() => {
          this.handleCancel();
        })


      Column() {
        this.NavigationBarBuilder()


        if (this.showDetailPage) {

          if (this.selectedUserInfo) {
              ContactDetailPage({
                userInfo: this.selectedUserInfo,
                onClose: () => {
                  this.handleCancel();
                }
              })
          } else if (this.selectedGroupInfo) {
              GroupDetailPage({
                groupInfo: this.selectedGroupInfo,
                onClose: () => {
                  this.handleCancel();
                }
              })
          }
        } else {


          // this.SearchTypeSelectorBuilder()


          this.SearchFieldBuilder()


          if (!this.hasSearched) {
            this.UserIdDisplayBuilder()
          }


          this.SearchResultsBuilder()
        }

      }
      .layoutWeight(1)
      .backgroundColor(this.themeState.colors.bgColorOperate) // Figma: #1F2024
      .borderRadius({ topLeft: 10, topRight: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.6)')
  }

  private handleCancel() {
    console.info('[AddContactDialog] Cancel button clicked');
    if (this.onCancel) {
      this.onCancel();
    }
    this.controller.close();
  }

  private handleSearch() {
    if (this.userIdInput.trim().length === 0) {
      return;
    }

    console.info(`[AddContactDialog] Search for: ${this.userIdInput}`);


    this.isSearching = true;
    this.hasSearched = true;
    this.searchResults = [];

    if (this.onSearchUser) {
      this.onSearchUser(this.userIdInput);
    }


    this.performSearch(this.userIdInput);
  }

  private performSearch(keyword: string) {
    if (this.searchType === SearchResultType.USER) {
      this.searchUsers(keyword);
    } else {
      this.searchGroups(keyword);
    }
  }

  private searchUsers(keyword: string) {
    // Clear previous result to avoid showing stale data
    this.contactListStore.fetchUserInfo(keyword)
      .then(() => {
        const result = this.contactListState.addFriendInfo;
        const resultItems: SearchResultItem[] = result ? [
          {
            id: result.contactID || '',
            name: result.title || '',
            avatar: result.avatarURL || '',
            subtitle: '',
            type: SearchResultType.USER,
            rawData: result
          } as SearchResultItem
        ] : [];

        this.isSearching = false;
        this.searchResults = resultItems;
      })
      .catch((error: ErrorInfo) => {
        this.isSearching = false;
        this.searchResults = [];
      });
  }

  private searchGroups(keyword: string) {
    // Clear previous result to avoid showing stale data

    this.contactListStore.fetchGroupInfo(keyword)
      .then(() => {
        const result = this.contactListState.joinGroupInfo;
        const resultItems: SearchResultItem[] = result ? [
          {
            id: result.contactID || '',
            name: result.title || '',
            avatar: result.avatarURL || '',
            subtitle: '',
            type: SearchResultType.GROUP,
            rawData: result
          } as SearchResultItem
        ] : [];

        this.isSearching = false;
        this.searchResults = resultItems;
      })
      .catch((error: ErrorInfo) => {
        this.isSearching = false;
        this.searchResults = [];
      });
  }

  private handleItemClick(item: SearchResultItem) {
    console.info(`[AddContactDialog] Item clicked: ${item.name} (${item.type})`);

    if (item.type === SearchResultType.USER) {

      this.selectedUserInfo = item.rawData as ContactInfo;
      this.selectedGroupInfo = null;
      this.showDetailPage = true;
    } else {

      this.selectedGroupInfo = item.rawData as ContactInfo;
      this.selectedUserInfo = null;
      this.showDetailPage = true;
    }
  }

  private handleBackToSearch() {
    console.info('[AddContactDialog] Back to search page');
    this.showDetailPage = false;
    this.selectedUserInfo = null;
    this.selectedGroupInfo = null;
    this.isAddingFriend = false;
    this.isJoiningGroup = false;
  }
}