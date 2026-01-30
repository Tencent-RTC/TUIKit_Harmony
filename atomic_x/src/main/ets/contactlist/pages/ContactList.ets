import { BadgeControl, BadgeType, ThemeState, AZOrderedList, AZOrderedListItem, AZOrderedListConfig } from '../../basecomponent/Index';
import { ErrorInfo, ContactInfo, ContactListState, ContactListStore } from '@tencentcloud/atomicxcore';
import { GroupListView } from './manager/GroupListView';
import { BlackListView } from './manager/BlackListView';
import { FriendApplicationListView } from './manager/FriendApplicationListView';
import { GroupApplicationListView } from './manager/GroupApplicationListView';
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';


@Component
export struct ContactList {
  private static readonly AVATAR_SIZE: number = 40;
  private static readonly ITEM_HEIGHT: number = 68;
  private static readonly SEARCH_BAR_HEIGHT: number = 36;
  private static readonly NOTIFICATION_BADGE_SIZE: number = 20;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink contactListStore: ContactListStore;
  @State private contactListState: ContactListState = this.contactListStore.state;
  // State management
  @State isLoading: boolean = false;
  @State showSearchResults: boolean = false;
  @State searchResults: ContactInfo[] = [];
  @State currentSelectedLetter: string = '';
  onContactClick?: (item: ContactInfo) => void;
  onGroupClick?: (item: ContactInfo) => void;
  private friendApplicationDialogController: CustomDialogController | null = null;
  private groupApplicationDialogController: CustomDialogController | null = null;
  private groupListDialogController: CustomDialogController | null = null;
  private blackListDialogController: CustomDialogController | null = null;
  @State private dialogAnimationOffset: number = 0;
  private dataChangeListener?: DataChangeListener | undefined;

  aboutToAppear() {
    this.registerDataSourceListener();
    this.contactListState = this.contactListStore.state;
    
    // Initialize contact items
    this.contactItems = this.convertContactsToAZOrderedListItems();

    this.fetchContactList();
    console.info('ContactListPage aboutToAppear');
    this.contactListStore.fetchBlackList();

    this.contactListStore.fetchFriendApplicationList();
    this.contactListStore.fetchGroupApplicationList();
  }

  aboutToDisappear() {
    this.unregisterDataSourceListener();
  }


  @Builder
  ManagementSectionBuilder() {
    Column() {

      Row() {
        Text($r('app.string.new_contacts'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Row() {
          if (this.contactListState.friendApplicationUnreadCount > 0) {
            BadgeControl({
              text: this.contactListState.friendApplicationUnreadCount.toString(),
              type: BadgeType.Text
            })
              .margin({ right: 8 })
          }

          Image($rawfile('contactlist/contact_arrow.svg'))
            .width(12)
            .height(12)
            .fillColor(this.themeState.colors.textColorPrimary)
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to new contacts page');
        this.showFriendApplicationDialogInternal();
      })


      Row() {
        Text($r('app.string.new_group_requests'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Row() {
          if (this.contactListState.groupApplicationUnreadCount > 0) {
            BadgeControl({
              text: this.contactListState.groupApplicationUnreadCount.toString(),
              type: BadgeType.Text
            })
              .margin({ right: 8 })
          }

          Image($rawfile('contactlist/contact_arrow.svg'))
            .width(12)
            .height(12)
            .fillColor(this.themeState.colors.textColorPrimary)
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to new group requests page');
        this.showGroupApplicationDialogInternal();
      })


      Row() {
        Text($r('app.string.my_group'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Image($rawfile('contactlist/contact_arrow.svg'))
          .width(12)
          .height(12)
          .fillColor(this.themeState.colors.textColorPrimary)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to my groups');
        this.showGroupListDialogInternal();
      })


      Row() {
        Text($r('app.string.the_blacklist'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontFamily('PingFang SC')
          .layoutWeight(1)

        Image($rawfile('contactlist/contact_arrow.svg'))
          .width(12)
          .height(12)
          .fillColor(this.themeState.colors.textColorPrimary)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeState.colors.bgColorInput)
      .onClick(() => {
        console.info('Navigate to blacklist management');
        this.showBlackListDialogInternal();
      })
    }
    .margin({ left: 0, right: 0 })
  }


  @Builder
  ContactListBuilder() {
    Column() {
      if (this.showSearchResults) {
        this.SearchResultsBuilder()
      } else {
        this.GroupedContactListBuilder()
      }
    }
  }


  // Helper method to create header builder with context
  getHeaderBuilder(): () => void {
    return () => {
      this.ManagementSectionBuilder()
    }
  }

  @Builder
  GroupedContactListBuilder() {
    AZOrderedList({
      dataSource: this.contactItems,
      config: { showIndexBar: true },
      header: this.getHeaderBuilder(),
      onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
        if (this.onContactClick) {
          this.onContactClick(item.extraData);
        }
      }
    })
  }



  @Builder
  SearchResultsBuilder() {
    if (this.searchResults.length > 0) {
      AZOrderedList({
        dataSource: this.convertSearchResultsToAZOrderedListItems(),
        config: { showIndexBar: false },
        header: this.getHeaderBuilder(),
        onItemClick: (item: AZOrderedListItem<ContactInfo>) => {
          if (this.onContactClick) {
            this.onContactClick(item.extraData);
          }
        }
      })
    } else {
      Column() {
        this.ManagementSectionBuilder()
        
        Column() {
          Text($r('app.string.no_results_found'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ top: 50 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
    }
  }

  @Builder
  EmptyStateBuilder() {
    Column() {
      Text($r('app.string.no_contacts_title'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')

      Text($r('app.string.no_contacts_desc'))
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang SC')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LoadingStateBuilder() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color(this.themeState.colors.textColorLink)

      Text($r('app.string.loading_contacts'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {

      Stack() {

        if (this.isLoading) {
          this.LoadingStateBuilder()
        } else if (this.contactListState.contactDataSource.totalCount() === 0) {
          Column() {
            this.ManagementSectionBuilder()
            this.EmptyStateBuilder()
          }
        } else {
          this.ContactListBuilder()
        }


      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  private registerDataSourceListener() {
    this.dataChangeListener = {
      // BasicDataSource
      onDataReloaded: () => {
        this.onDataSourceChanged();
      },
      onDataAdd: (index: number) => {
        this.onDataSourceChanged();
      },
      onDataChange: (index: number) => {
        this.onDataSourceChanged();
      },
      onDataDelete: (index: number) => {
        this.onDataSourceChanged();
      },
      onDataMove: (from: number, to: number) => {
        this.onDataSourceChanged();
      },
      onDataAdded: (index: number) => {
        this.onDataSourceChanged();
      },
      onDataChanged: (index: number) => {
        this.onDataSourceChanged();
      },
      onDataDeleted: (index: number) => {
        this.onDataSourceChanged();
      },
      onDataMoved: (from: number, to: number) => {
        this.onDataSourceChanged();
      },
      onDatasetChange: () => {
        this.onDataSourceChanged();
      }
    };
    if (this.dataChangeListener) {
      this.contactListState.contactDataSource.registerDataChangeListener(this.dataChangeListener);
    }
  }

  private unregisterDataSourceListener() {
    if (this.dataChangeListener) {
      this.contactListState.contactDataSource.unregisterDataChangeListener(this.dataChangeListener);
      this.dataChangeListener = undefined;
    }
  }

  private onDataSourceChanged() {
    // Update contact items state to trigger UI refresh
    const newItems = this.convertContactsToAZOrderedListItems();
    console.info('[ContactList] Data source changed, old items:', this.contactItems.length, 'new items:', newItems.length);
    this.contactItems = newItems;
    console.info('[ContactList] Contact items updated, first 3:', this.contactItems.slice(0, 3).map(item => item.label));
  }


  private fetchContactList() {

    this.isLoading = true;
    this.contactListStore.fetchFriendList()
      .then(() => {
        this.isLoading = false;
        // Update contact items after successful fetch
        this.contactItems = this.convertContactsToAZOrderedListItems();
      })
      .catch((error: ErrorInfo) => {

        this.isLoading = false;
      });


    setTimeout(() => {
      if (this.isLoading) {
        console.warn('fetchContactList time out');
        this.isLoading = false;
      }
    }, 5000);
  }

  private getContactDisplayName(contact: ContactInfo): string {
    return contact.title || contact.contactID || '';
  }

  // Convert ContactInfo to AZOrderedListItem
  @State private contactItems: AZOrderedListItem<ContactInfo>[] = [];
  
  private convertContactsToAZOrderedListItems(): AZOrderedListItem<ContactInfo>[] {
    const items: AZOrderedListItem<ContactInfo>[] = [];
    
    for (let i = 0; i < this.contactListState.contactDataSource.totalCount(); i++) {
      const contact = this.contactListState.contactDataSource.getData(i);
      if (contact) {
        items.push({
          key: contact.contactID,
          label: this.getContactDisplayName(contact),
          avatarUrl: contact.avatarURL,
          extraData: contact
        });
      }
    }
    
    return items;
  }

  // Convert search results to AZOrderedListItem
  private convertSearchResultsToAZOrderedListItems(): AZOrderedListItem<ContactInfo>[] {
    return this.searchResults.map((contact: ContactInfo): AZOrderedListItem<ContactInfo> => ({
      key: contact.contactID,
      label: this.getContactDisplayName(contact),
      avatarUrl: contact.avatarURL,
      extraData: contact
    }));
  }

  // Dialog builders for sub-pages
  @Builder
  FriendApplicationDialogBuilder() {
    Column() {
      FriendApplicationListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.friendApplicationDialogController?.close();
          this.friendApplicationDialogController = null;
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  @Builder
  GroupApplicationDialogBuilder() {
    Column() {
      GroupApplicationListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.groupApplicationDialogController?.close();
          this.groupApplicationDialogController = null;
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  @Builder
  GroupListDialogBuilder() {
    Column() {
      GroupListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.groupListDialogController?.close();
          this.groupListDialogController = null;
        },
        onShowProfile: (group: ContactInfo) => {
          console.log('[ContactList] Selected group:', group.title);
          this.groupListDialogController?.close();
          this.groupListDialogController = null;
          // Trigger onGroupClick callback
          if (this.onGroupClick) {
            this.onGroupClick(group);
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  @Builder
  BlackListDialogBuilder() {
    Column() {
      BlackListView({
        contactListStore: this.contactListStore,
        onBack: () => {
          this.blackListDialogController?.close();
          this.blackListDialogController = null;
        },
        onShowProfile: (item: ContactInfo) => {
          this.blackListDialogController?.close();
          this.blackListDialogController = null;
          // Trigger onContactClick callback
          if (this.onContactClick) {
            this.onContactClick(item);
          }
        }
      })
    }
    .width('100%')
    .height('100%')
    .translate({ x: `${this.dialogAnimationOffset}%` })
    .onAppear(() => {
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.dialogAnimationOffset = 0;
      });
    })
  }

  // Internal dialog display methods
  private showFriendApplicationDialogInternal(): void {
    try {
      if (this.friendApplicationDialogController) {
        this.friendApplicationDialogController.close();
        this.friendApplicationDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.friendApplicationDialogController = new CustomDialogController({
        builder: this.FriendApplicationDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.friendApplicationDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.friendApplicationDialogController.open();
    } catch (error) {
      console.error('[ContactList] showFriendApplicationDialog error:', error);
    }
  }

  private showGroupApplicationDialogInternal(): void {
    try {
      if (this.groupApplicationDialogController) {
        this.groupApplicationDialogController.close();
        this.groupApplicationDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.groupApplicationDialogController = new CustomDialogController({
        builder: this.GroupApplicationDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.groupApplicationDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.groupApplicationDialogController.open();
    } catch (error) {
      console.error('[ContactList] showGroupApplicationDialog error:', error);
    }
  }

  private showGroupListDialogInternal(): void {
    try {
      if (this.groupListDialogController) {
        this.groupListDialogController.close();
        this.groupListDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.groupListDialogController = new CustomDialogController({
        builder: this.GroupListDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.groupListDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.groupListDialogController.open();
    } catch (error) {
      console.error('[ContactList] showGroupListDialog error:', error);
    }
  }

  private showBlackListDialogInternal(): void {
    try {
      if (this.blackListDialogController) {
        this.blackListDialogController.close();
        this.blackListDialogController = null;
      }

      this.dialogAnimationOffset = 100;

      this.blackListDialogController = new CustomDialogController({
        builder: this.BlackListDialogBuilder.bind(this),
        autoCancel: false,
        alignment: DialogAlignment.Center,
        customStyle: true,
        keyboardAvoidMode: KeyboardAvoidMode.NONE,
        maskColor: 'rgba(0, 0, 0, 0)',
        cancel: () => {
          this.blackListDialogController = null;
        },
        levelMode: LevelMode.EMBEDDED,
        immersiveMode: ImmersiveMode.EXTEND,
        openAnimation: {
          duration: 300,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        },
        closeAnimation: {
          duration: 250,
          curve: Curve.EaseInOut,
          playMode: PlayMode.Normal
        }
      });

      this.blackListDialogController.open();
    } catch (error) {
      console.error('[ContactList] showBlackListDialog error:', error);
    }
  }

}