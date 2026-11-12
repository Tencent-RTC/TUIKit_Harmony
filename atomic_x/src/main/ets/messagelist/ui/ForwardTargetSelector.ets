import { AtomicxNavigator, Avatar, AvatarContentType, AvatarSize, ThemeState } from '../../basecomponent/Index';
import { MessageCheckBox } from './MessageCheckBox';
import {
  ContactInfo,
  ContactState,
  ContactStore,
  ConversationInfo,
  ConversationListState,
  ConversationListStore,
  ConversationLoadOption
} from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { UserPicker, UserPickerData } from '../../userpicker/components/UserPicker';

enum ForwardTargetSelectorPage {
  CONVERSATIONS = 'conversations',
  CONTACTS = 'contacts'
}

interface ForwardTarget {
  conversationID: string;
  title: string;
  avatarURL: string;
}

interface ForwardTargetSelectorArgs {
  currentConversationID?: string;
  onConfirm?: (conversationIDs: string[]) => void;
  onCancel?: () => void;
}

@Builder
function ForwardTargetSelectorPageBuilder(args: Object) {
  ForwardTargetSelectorContent({
    currentConversationID: (args as ForwardTargetSelectorArgs).currentConversationID,
    onConfirm: (args as ForwardTargetSelectorArgs).onConfirm,
    onCancel: (args as ForwardTargetSelectorArgs).onCancel,
    headerTopMargin: 0,
    onClose: () => {
      AtomicxNavigator.pop();
    }
  })
}

export function pushForwardTargetSelectorPage(currentConversationID: string | undefined,
  onConfirm: (conversationIDs: string[]) => void, onCancel?: () => void): boolean {
  const args: ForwardTargetSelectorArgs = {
    currentConversationID: currentConversationID,
    onConfirm: onConfirm,
    onCancel: onCancel
  };
  return AtomicxNavigator.push(wrapBuilder(ForwardTargetSelectorPageBuilder), args, (): boolean => {
    onCancel?.();
    return false;
  });
}

@CustomDialog
export struct ForwardTargetSelector {
  controller: CustomDialogController;
  currentConversationID?: string;
  onConfirm?: (conversationIDs: string[]) => void;
  onCancel?: () => void;

  build() {
    ForwardTargetSelectorContent({
      currentConversationID: this.currentConversationID,
      onConfirm: this.onConfirm,
      onCancel: this.onCancel,
      onClose: () => {
        this.controller.close();
      }
    })
  }
}

@Component
struct ForwardTargetSelectorContent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State private conversationListStore: ConversationListStore = ConversationListStore.create();
  @State private conversationListState: ConversationListState = this.conversationListStore.state;
  @State private contactListStore: ContactStore = ContactStore.shared;
  @State private contactListState: ContactState = this.contactListStore.state as ContactState;
  @State private selectedConversationIDs: Set<string> = new Set();
  @State private selectedConversations: ForwardTarget[] = [];
  @State private friendList: UserPickerData<ContactInfo>[] = [];
  @State private page: ForwardTargetSelectorPage = ForwardTargetSelectorPage.CONVERSATIONS;
  @State private isLoading: boolean = false;
  @State private isContactLoading: boolean = false;

  currentConversationID?: string;
  onConfirm?: (conversationIDs: string[]) => void;
  onCancel?: () => void;
  onClose?: () => void;
  headerTopMargin: number = 24;

  private readonly HEADER_HEIGHT: number = 56;
  private readonly ITEM_HEIGHT: number = 64;
  private readonly AVATAR_SIZE: number = 40;
  private readonly BOTTOM_BAR_HEIGHT: number = 60;
  private readonly HORIZONTAL_PADDING: number = 16;

  aboutToAppear(): void {
    this.loadConversations();
  }

  build() {
    Column() {
      if (this.page === ForwardTargetSelectorPage.CONTACTS) {
        this.ContactPickerView();
      } else {
        this.ConversationSelectorView();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  private ConversationSelectorView() {
    Column() {
      this.HeaderBar();
      this.ConversationListView();
      if (this.selectedConversationIDs.size > 0) {
        this.SelectedConversationBar();
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private ContactPickerView() {
    if (this.isContactLoading) {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      UserPicker({
        dataSource: this.friendList,
        defaultSelectedItems: this.getSelectedContactUserIDs(),
        showNavigationBar: true,
        showBackButton: true,
        showSearchBar: false,
        title: $r('app.string.forward_select_from_contacts'),
        confirmButtonText: $r('app.string.confirm'),
        showHeaderConfirm: true,
        showBottomConfirm: false,
        titleTopMargin: this.headerTopMargin,
        onCancel: (): void => {
          this.page = ForwardTargetSelectorPage.CONVERSATIONS;
        },
        onSelectedChanged: (selectedUsers: UserPickerData<ContactInfo>[]): void => {
          this.selectContacts(selectedUsers);
          this.page = ForwardTargetSelectorPage.CONVERSATIONS;
        }
      })
    }
  }

  @Builder
  private HeaderBar() {
    Row() {
      Text($r('app.string.cancel'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorLink)
        .onClick((): void => {
          this.onCancel?.();
          this.onClose?.();
        })

      Text($r('app.string.forward_select_conversation'))
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('')
        .width(40)
    }
    .width('100%')
    .height(this.HEADER_HEIGHT)
    .margin({ top: this.headerTopMargin })
    .padding({ left: this.HORIZONTAL_PADDING, right: this.HORIZONTAL_PADDING })
    .alignItems(VerticalAlign.Center)
    .borderWidth({ bottom: 0.5 })
    .borderColor(this.themeState.colors.strokeColorPrimary)
  }

  @Builder
  private ConversationListView() {
    Column() {
      Row() {
        Text($r('app.string.forward_select_from_contacts'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorPrimary)
          .layoutWeight(1)

        Image($rawfile('contactlist/contact_arrow.svg'))
          .width(20)
          .height(20)
          .fillColor(this.themeState.colors.textColorSecondary)
      }
      .width('100%')
      .height(56)
      .padding({ left: this.HORIZONTAL_PADDING, right: this.HORIZONTAL_PADDING })
      .alignItems(VerticalAlign.Center)
      .onClick((): void => {
        this.openContactPicker();
      })

      Text($r('app.string.forward_recent_chats'))
        .fontSize(13)
        .fontColor(this.themeState.colors.textColorSecondary)
        .width('100%')
        .padding({ left: this.HORIZONTAL_PADDING, top: 12, bottom: 8 })

      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 100 })
      } else {
        List() {
          LazyForEach(this.conversationListState.conversationList, (conversation: ConversationInfo) => {
            ListItem() {
              this.ConversationRow(conversation);
            }
          }, (conversation: ConversationInfo) => conversation.conversationID)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 0.5,
          color: this.themeState.colors.strokeColorPrimary,
          startMargin: this.HORIZONTAL_PADDING + this.AVATAR_SIZE + 12,
          endMargin: this.HORIZONTAL_PADDING
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private ConversationRow(conversation: ConversationInfo) {
    Row() {
      MessageCheckBox({
        isSelected: this.selectedConversationIDs.has(conversation.conversationID),
        isEnabled: true,
        onTap: (): void => {
          this.toggleConversation(conversation);
        }
      })
        .margin({ right: 12 })

      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: conversation.avatarURL ?? '',
          name: conversation.title ?? ''
        },
        avatarSize: AvatarSize.M
      })
        .width(this.AVATAR_SIZE)
        .height(this.AVATAR_SIZE)

      Text(conversation.title ?? $r('app.string.forward_unnamed_conversation'))
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: 12 })
    }
    .width('100%')
    .height(this.ITEM_HEIGHT)
    .padding({ left: this.HORIZONTAL_PADDING, right: this.HORIZONTAL_PADDING })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.toggleConversation(conversation);
    })
  }

  @Builder
  private SelectedConversationBar() {
    Column() {
      Divider()
        .width('100%')
        .height(0.5)
        .color(this.themeState.colors.strokeColorPrimary)

      Row() {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.selectedConversations, (conversation: ForwardTarget) => {
              this.ConversationChip(conversation);
            }, (conversation: ForwardTarget) => conversation.conversationID)
          }
          .padding({ left: this.HORIZONTAL_PADDING, right: 8 })
          .justifyContent(FlexAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .align(Alignment.Start)
        .height(40)
        .layoutWeight(1)

        Button() {
          Text() {
            Span($r('app.string.forward_send'))
            Span(` (${this.selectedConversationIDs.size})`)
          }
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        }
        .type(ButtonType.Normal)
        .backgroundColor(this.themeState.colors.buttonColorPrimaryDefault)
        .borderRadius(4)
        .height(36)
        .padding({ left: 16, right: 16 })
        .margin({ right: this.HORIZONTAL_PADDING })
        .onClick((): void => {
          if (this.selectedConversationIDs.size === 0) {
            return;
          }
          this.onConfirm?.(Array.from(this.selectedConversationIDs));
          this.onClose?.();
        })
      }
      .width('100%')
      .height(this.BOTTOM_BAR_HEIGHT)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  private ConversationChip(conversation: ForwardTarget) {
    Avatar({
      content: {
        type: AvatarContentType.Image,
        url: conversation.avatarURL,
        name: conversation.title
      },
      avatarSize: AvatarSize.M
    })
      .width(40)
      .height(40)
      .onClick((): void => {
        this.removeConversation(conversation.conversationID);
      })
  }

  private openContactPicker(): void {
    this.isContactLoading = true;
    this.contactListStore.loadFriends(new CompletionHandlerAdapter((): void => {
      const friends: UserPickerData<ContactInfo>[] = [];
      this.contactListState.friendList.forEach((contact: ContactInfo): void => {
        if (contact.userID) {
          friends.push({
            key: contact.userID,
            label: contact.friendRemark || contact.nickname || contact.userID,
            avatarUrl: contact.avatarURL || '',
            extraData: contact
          });
        }
      });
      this.friendList = friends;
      this.isContactLoading = false;
      this.page = ForwardTargetSelectorPage.CONTACTS;
    }, (_code: number, desc: string): void => {
      console.error('[ForwardTargetSelector] Failed to load friends:', desc);
      this.isContactLoading = false;
    }));
  }

  private selectContacts(contacts: UserPickerData<ContactInfo>[]): void {
    const contactIDs: Set<string> = new Set();
    contacts.forEach((item: UserPickerData<ContactInfo>): void => {
      const contact: ContactInfo = item.extraData;
      const conversationID: string = `c2c_${contact.userID}`;
      contactIDs.add(conversationID);
      this.addTarget({
        conversationID,
        title: contact.friendRemark || contact.nickname || contact.userID || '',
        avatarURL: contact.avatarURL || ''
      });
    });

    const friendConversationIDs: Set<string> = new Set(
      this.friendList.map((item: UserPickerData<ContactInfo>): string => `c2c_${item.key}`)
    );
    this.selectedConversations
      .filter((target: ForwardTarget): boolean =>
        friendConversationIDs.has(target.conversationID) && !contactIDs.has(target.conversationID)
      )
      .forEach((target: ForwardTarget): void => {
        this.removeConversation(target.conversationID);
      });
  }

  private getSelectedContactUserIDs(): string[] {
    return Array.from(this.selectedConversationIDs)
      .filter((conversationID: string): boolean => conversationID.startsWith('c2c_'))
      .map((conversationID: string): string => conversationID.substring(4));
  }

  private toggleConversation(conversation: ConversationInfo): void {
    if (this.selectedConversationIDs.has(conversation.conversationID)) {
      this.removeConversation(conversation.conversationID);
      return;
    }
    this.addTarget({
      conversationID: conversation.conversationID,
      title: conversation.title ?? '',
      avatarURL: conversation.avatarURL ?? ''
    });
  }

  private addTarget(target: ForwardTarget): void {
    if (this.selectedConversationIDs.has(target.conversationID)) {
      return;
    }
    this.selectedConversationIDs.add(target.conversationID);
    this.selectedConversationIDs = new Set(this.selectedConversationIDs);
    this.selectedConversations = [...this.selectedConversations, target];
  }

  private removeConversation(conversationID: string): void {
    this.selectedConversationIDs.delete(conversationID);
    this.selectedConversationIDs = new Set(this.selectedConversationIDs);
    this.selectedConversations = this.selectedConversations.filter((target: ForwardTarget): boolean => target.conversationID !== conversationID);
  }

  private loadConversations(): void {
    this.isLoading = true;
    const option = new ConversationLoadOption();
    this.conversationListStore.loadConversations(option, new CompletionHandlerAdapter((): void => {
      this.isLoading = false;
    }, (_code: number, desc: string): void => {
      this.isLoading = false;
      console.error('[ForwardTargetSelector] Failed to load conversations:', desc);
    }));
  }
}
