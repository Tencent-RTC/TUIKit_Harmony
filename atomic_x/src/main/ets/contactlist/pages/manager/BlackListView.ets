import { ContactInfo, ContactState, ContactStore } from '@tencentcloud/atomicxcore';
import { Avatar, AvatarContentType, AvatarSize, ThemeState } from '../../../basecomponent/Index';
import { CompletionHandlerAdapter } from '../../../basecomponent/utils/CompletionHandlers';

@Component
export struct BlackListView {
  onBack?: () => void;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  onShowProfile?: (item: ContactInfo) => void;
  @ObjectLink contactStore: ContactStore;
  @State private contactState: ContactState = this.contactStore.state as ContactState;
  @State private isLoading: boolean = true;

  aboutToAppear() {
    console.info('BlackListPage aboutToAppear');
    this.contactState = this.contactStore.state as ContactState;
    this.loadBlackList();
  }

  aboutToDisappear() {
    console.info('BlackListPage aboutToDisappear');
  }

  onBackPress(): boolean {
    this.handleBack();
    return true;
  }

  build() {
    Column() {
      // Navigation bar
      this.buildNavigationBar()


      if (this.isLoading) {
        this.buildLoadingState()
      } else if (this.contactState.blackList.length === 0) {
        this.buildEmptyState()
      } else {
        this.buildBlackList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
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


        Text($r('app.string.the_blacklist'))
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
        .color(this.themeState.colors.strokeColorSecondary)
    }
  }

  @Builder
  buildBlackList() {
    List() {
      ForEach(this.contactState.blackList, (blackListInfo: ContactInfo) => {
        ListItem() {
          this.buildBlackListItem(blackListInfo)
        }
      }, (blackListInfo: ContactInfo) => blackListInfo.userID || '')
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .divider({
      strokeWidth: 1,
      color: this.themeState.colors.shadowColor,
      startMargin: 87,
      endMargin: 0
    })
  }

  @Builder
  buildBlackListItem(blackListInfo: ContactInfo) {
    Row() {
      // Avatar
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: blackListInfo.avatarURL,
          name: blackListInfo.nickname || blackListInfo.userID || '',
        },
        avatarSize: AvatarSize.M,
      })
      // User info
      Column() {
        Text(blackListInfo.nickname || blackListInfo.userID || '')
          .fontSize(14)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontWeight(FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .margin({ left: 13 })
    }
    .width('100%')
    .height(74)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (this.onShowProfile) {
        this.onShowProfile(blackListInfo);
      }
    })
  }

  // Empty state
  @Builder
  buildEmptyState() {
    Column() {
      Text($r('app.string.no_blacklist_users_title'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })

      Text($r('app.string.no_blacklist_users_desc'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorTertiary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
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
      Text($r('app.string.loading_blacklist'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorSecondary)
        .margin({ top: 10 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  private handleBack() {
    if (this.onBack) {
      this.onBack();
    }
  }

  private loadBlackList() {
    this.isLoading = true;
    this.contactStore.loadBlackList(new CompletionHandlerAdapter(() => {
      this.isLoading = false;
    }, (code: number, desc: string) => {
      console.error('Failed to load black list:', code, desc);
      this.isLoading = false;
    }));
  }

  private showUnblockDialog(blackListInfo: ContactInfo) {
    const userName = blackListInfo.nickname || blackListInfo.userID || '';
    AlertDialog.show({
      title: $r('app.string.unblock_user_title'),
      message: `确定要解除黑名单 ${userName}？`,
      primaryButton: {
        value: $r('app.string.cancel_button'),
        action: () => {

        }
      },
      secondaryButton: {
        value: $r('app.string.unblock_button'),
        action: () => {
          this.unblockUser(blackListInfo);
        }
      }
    });
  }

  private unblockUser(blackListInfo: ContactInfo) {
    this.contactStore.removeFromBlacklist(blackListInfo.userID, new CompletionHandlerAdapter(() => {
      this.loadBlackList();
    }, (code: number, desc: string) => {
      console.error('Failed to unblock user:', code, desc);
    }));
  }
}
