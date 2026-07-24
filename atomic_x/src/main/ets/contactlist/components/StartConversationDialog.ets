import { ThemeState } from '../../basecomponent/Index';
import { ContactInfo, ContactState, ContactStore, ContactOnlineStatus } from '@tencentcloud/atomicxcore';
import { CustomSendMessagePayload, MessageInputStore } from '@tencentcloud/atomicxcore';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { CompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
import { UserPickerData, UserPicker } from '../../userpicker/components/UserPicker';
import { GroupCreationComponent, GroupInfo, GroupType } from './GroupCreationComponent';

export enum DialogType {
  START_CONVERSATION = 'startConversation',
  CREATE_GROUP = 'createGroup'
}

enum DialogPageState {
  USER_PICKER = 'userPicker',
  GROUP_CREATION = 'groupCreation'
}

@CustomDialog
export struct StartConversationDialog {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller: CustomDialogController;
  dialogType: DialogType = DialogType.START_CONVERSATION;
  // Callback function
  onCancel?: () => void;
  onSelectUser?: (contact: ContactInfo) => void;
  onCreateGroup?: (groupInfo: GroupInfo) => void;
  // State management
  @State isLoading: boolean = true;
  @State friendList: UserPickerData<ContactInfo>[] = [];
  @State currentPage: DialogPageState = DialogPageState.USER_PICKER;
  @State selectedContactsForGroup: ContactInfo[] = [];
  private contactStore: ContactStore = ContactStore.shared;
  @State private contactState: ContactState = this.contactStore.state as ContactState;

  aboutToAppear() {
    console.info('[StartConversationDialog] Dialog about to appear, type:', this.dialogType);
    this.loadFriendList();
  }

  aboutToDisappear() {
    console.info('[StartConversationDialog] Dialog about to disappear');
  }

  build() {
    Column() {

      Column()
        .height(88)
        .width('100%')
        .backgroundColor(this.themeState.colors.bgColorMask)
        .onClick(() => {
          this.handleCancel();
        })

      Column() {
        if (this.currentPage === DialogPageState.USER_PICKER) {
          this.UserPickerPageBuilder()
        } else if (this.currentPage === DialogPageState.GROUP_CREATION) {
          this.GroupCreationPageBuilder()
        }
      }
      .layoutWeight(1)
      .backgroundColor(this.themeState.colors.bgColorOperate) // Figma: #FFFFFF
      .borderRadius({ topLeft: 10, topRight: 10 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  UserPickerPageBuilder() {
    Column() {
      if (this.isLoading) {
        // Loading state
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
          defaultSelectedItems: [],
          maxCount: this.getMaxSelectCount(),
          showNavigationBar: true,
          title: this.getDialogTitle(),
          confirmButtonText: this.getConfirmButtonText(),
          onCancel: this.handleUserCancelComplete,
          onSelectedChanged: this.handleUserPickerComplete
        })
      }
    }
  }

  @Builder
  GroupCreationPageBuilder() {
    GroupCreationComponent({
      selectedContacts: this.selectedContactsForGroup,
      onCancel: () => {
        this.currentPage = DialogPageState.USER_PICKER;
      },
      onCreate: (groupInfo: GroupInfo) => {
        this.handleGroupCreation(groupInfo);
      }
    })
  }

  private getDialogTitle(): string | Resource {
    return this.dialogType === DialogType.CREATE_GROUP ?
    $r('app.string.create_group_chat_title') :
    $r('app.string.select_contacts_title');
  }

  private getMaxSelectCount(): number {
    return this.dialogType === DialogType.CREATE_GROUP ? 500 : 1;
  }

  private getConfirmButtonText(): string | Resource {
    return this.dialogType === DialogType.CREATE_GROUP ?
    $r('app.string.next_step_button') :
    $r('app.string.start_conversation_button');
  }

  private loadFriendList(): void {
    console.log('[StartConversationDialog] Loading friend list...');

    this.contactStore.loadFriends(new CompletionHandlerAdapter(() => {
      const friendList: UserPickerData<ContactInfo>[] = [];
      const contacts = this.contactState.friendList;
      for (let i = 0; i < contacts.length; i++) {
        const contact = contacts[i];
        if (contact) {
          const userPickerData: UserPickerData<ContactInfo> = {
            key: contact.userID || '',
            label: contact.nickname || contact.userID || '',
            avatarUrl: contact.avatarURL || '',
            extraData: contact
          };
          friendList.push(userPickerData);
        }
      }
      this.friendList = friendList;
      console.log('[StartConversationDialog] Friend list loaded:', this.friendList.length);
      this.isLoading = false;
    }, (code: number, desc: string) => {
      console.error('[StartConversationDialog] Failed to load friend list:', code, desc);
      this.isLoading = false;
    }));
  }

  private handleUserCancelComplete = () => {
    this.handleCancel()
  }

  private handleCancel() {
    console.info('[StartConversationDialog] Dialog cancelled');
    if (this.onCancel) {
      this.onCancel();
    }
    this.controller.close();
  }

  private handleUserPickerComplete = (selectedUsers: UserPickerData<ContactInfo>[]) => {
    console.info('[StartConversationDialog] User picker completed with users:', selectedUsers.length);

    if (this.dialogType === DialogType.START_CONVERSATION) {
      if (selectedUsers.length > 0) {
        const selectedUser = selectedUsers[0];
        const contactInfo = selectedUser.extraData;
        
        if (contactInfo && this.onSelectUser) {
          this.onSelectUser(contactInfo);
        }
      }
    } else if (this.dialogType === DialogType.CREATE_GROUP) {
      const selectedContacts: ContactInfo[] = selectedUsers.map((user: UserPickerData<ContactInfo>) => user.extraData);

      this.selectedContactsForGroup = selectedContacts;
      console.info('[StartConversationDialog] Selected contacts for group:', this.selectedContactsForGroup.length);

      this.currentPage = DialogPageState.GROUP_CREATION;
    }
  }

  private findContactInfoByIdentifier(identifier: string): ContactInfo | null {
    const contacts = this.contactState.friendList;
    for (let i = 0; i < contacts.length; i++) {
      const contact = contacts[i];
      if (contact && contact.userID === identifier) {
        return contact;
      }
    }
    return null;
  }

  private handleGroupCreation(groupInfo: GroupInfo) {
    console.info('[StartConversationDialog] Group creation started:', groupInfo.groupName);
    if (this.onCreateGroup) {
      this.onCreateGroup(groupInfo);
    }

    setTimeout(() => {
      // Send group create message after successful group creation
      if (groupInfo.groupID) {
        this.sendGroupCreateMessage(groupInfo.groupID, groupInfo.groupType);
      }
    }, 1000);

    // Close dialog
    this.controller.close();
  }

  private sendGroupCreateMessage(groupID: string, groupType: GroupType): void {
    const conversationID = `group_${groupID}`;
    const currentUser = LoginStore.shared().state.loginUserInfo;
    const customContent: Record<string, ESObject> = {};
    customContent['version'] = 1;
    customContent['businessID'] = 'group_create';
    customContent['opUser'] = currentUser?.userID || '';
    customContent['content'] = $r('app.string.create_group_chat');
    customContent['cmd'] = groupType === GroupType.COMMUNITY ? 1 : 0;

    const messageInputStore = MessageInputStore.create(conversationID);
    const payload = new CustomSendMessagePayload(JSON.stringify(customContent), 'group_create', '');

    messageInputStore.sendMessage(payload, undefined, new CompletionHandlerAdapter(() => {
      console.info('[StartConversationDialog] Group create message sent successfully');
    }, (code: number, desc: string) => {
      console.error('[StartConversationDialog] Failed to send group create message:', code, desc);
    }));
  }
}
