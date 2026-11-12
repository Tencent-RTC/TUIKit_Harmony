import { AppBuilderConfig, ThemeState } from '@tencentcloud/atomicx/src/main/ets/basecomponent/Index';
import { SearchBar } from '@tencentcloud/atomicx/src/main/ets/search/Index';
import { FriendSearchInfo, GroupSearchInfo, MessageSearchResultItem } from '@tencentcloud/atomicxcore';
import { ConversationList } from '@tencentcloud/atomicx/src/main/ets/conversationlist/Index';
import { ConversationInfo } from '@tencentcloud/atomicxcore';
import { ContactInfo } from '@tencentcloud/atomicxcore';
import { MessageInfo } from '@tencentcloud/atomicxcore';
import { StartConversationDialog, DialogType, GroupInfo, pushStartConversationPage } from '@tencentcloud/atomicx/src/main/ets/contactlist/Index';
import { ImmersiveMode, LevelMode } from '@kit.ArkUI';

@Component
export struct ConversationsPage {
  private static readonly LARGE_TITLE_HEIGHT: number = 56;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State showAddMenu: boolean = false;
  private startConversationDialogController: CustomDialogController | null = null;
  private createGroupDialogController: CustomDialogController | null = null;
  onConversationClick?: (item: ConversationInfo) => void;
  onConversationClickWithMessage?: (item: ConversationInfo, locateMessage?: MessageInfo) => void;

  @Builder
  LargeTitleBuilder() {
    Row() {
      Row()
        .width(24)
        .height(24)

      Text($r('app.string.chat_title'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .textAlign(TextAlign.Center)
        .layoutWeight(1)

      Row() {
        Image($r('app.media.new_chat_icon'))
          .width(24)
          .height(24)
          .fillColor(this.themeState.colors.textColorPrimary)
          .onClick(() => {
            this.showAddMenu = true;
          })
      }
      .width(24)
      .height(24)
    }
    .width('100%')
    .height(ConversationsPage.LARGE_TITLE_HEIGHT)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  @Builder
  AddMenuDialog() {
    Column() {

      Polygon({ width: 12, height: 6 })
        .points([[6, 0], [0, 6], [12, 6]])
        .fill(this.themeState.colors.bgColorOperate)// .stroke('#E5E5E5')
        .strokeWidth(1)
        .margin({ bottom: -1 })
        .alignSelf(ItemAlign.End)
        .margin({ right: 18 })


      Column() {

        Row() {
          Image($r('app.media.start_conversation_c2c'))
            .width(24)
            .height(24)
            .margin({ right: 12 })
            .fillColor(this.themeState.colors.textColorPrimary)

          Text($r('app.string.start_conversation'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
        }
        .width('100%')
        .height(48)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.showAddMenu = false;
          this.handleStartConversation();
        })

        // Divider
        Divider()
          .color('#E5E5E5')
          .strokeWidth(0.5)
          .margin({ left: 52 })


        if (AppBuilderConfig.getInstance().enableCreateConversation) {
          Row() {
            Image($r('app.media.start_conversation_group'))
              .width(24)
              .height(24)
              .margin({ right: 12 })
              .fillColor(this.themeState.colors.textColorPrimary)

            Text($r('app.string.create_group_chat'))
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorPrimary)
              .fontFamily('PingFang HK')
          }
          .width('100%')
          .height(48)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.showAddMenu = false;
            this.handleCreateGroup();
          })
        }

      }
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .borderRadius(12)
      .border({ width: 1, color: '#E5E5E5' })
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetX: 0,
        offsetY: 2
      })
      .width(160)
    }
    .position({ x: '100%', y: ConversationsPage.LARGE_TITLE_HEIGHT + 8 })
    .markAnchor({ x: 168, y: 0 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.LargeTitleBuilder()
        if (!AppBuilderConfig.getInstance().hideSearch) {
          SearchBar({
            onContactSelect: (contact: FriendSearchInfo) => {
              if (contact.userID) {
                this.showChatDialog(
                  `c2c_${contact.userID}`,
                  contact.friendRemark || contact.userInfo.nickname || contact.userID,
                  contact.userInfo.avatarURL || ''
                );
              }
            },
            onGroupSelect: (group: GroupSearchInfo) => {
              if (group.groupID) {
                this.showChatDialog(
                  `group_${group.groupID}`,
                  group.groupName || group.groupID,
                  group.groupAvatarURL
                );
              }
            },
            onMessageSelect: (result: MessageSearchResultItem) => {
              if (result.conversationID && result.messageList.length > 0) {
                this.showChatDialog(
                  result.conversationID,
                  result.conversationShowName || 'Chat',
                  result.conversationAvatarURL,
                  result.messageList[0]
                );
              }
            },
            onConversationSelect: (result: MessageSearchResultItem) => {
              if (result.conversationID) {
                this.showChatDialog(
                  result.conversationID,
                  result.conversationShowName || 'Chat',
                  result.conversationAvatarURL
                );
              }
            }
          })
        }
        ConversationList({
          onConversationClick: (item: ConversationInfo) => {
            console.info(`Navigate to conversation detail with ID: ${item.conversationID}`);
            if (this.onConversationClick) {
              this.onConversationClick(item);
            }
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
      .onClick(() => {

        if (this.showAddMenu) {
          this.showAddMenu = false;
        }
      })


      if (this.showAddMenu) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0)')
          .onClick(() => {
            this.showAddMenu = false;
          })
      }


      if (this.showAddMenu) {
        this.AddMenuDialog()
      }
    }
    .width('100%')
    .height('100%')
  }


  private handleStartConversation(): void {
    console.info('[ConversationPage] handleStartConversation')
    if (pushStartConversationPage(DialogType.START_CONVERSATION, (contact: ContactInfo) => {
      this.openConversationWithContact(contact);
    })) {
      return;
    }


    if (this.startConversationDialogController) {
      this.startConversationDialogController.close();
      this.startConversationDialogController = null;
    }


    this.startConversationDialogController = new CustomDialogController({
      builder: StartConversationDialog({
        dialogType: DialogType.START_CONVERSATION,
        onCancel: () => {

          this.startConversationDialogController = null;
        },
        onSelectUser: (contact: ContactInfo) => {

          if (contact.userID && this.onConversationClick) {
            const conversationInfo = new ConversationInfo();
            conversationInfo.conversationID = `c2c_${contact.userID}`;
            conversationInfo.title = contact.friendRemark || contact.nickname || contact.userID;
            conversationInfo.avatarURL = contact.avatarURL;
            this.onConversationClick(conversationInfo);
          }
          this.startConversationDialogController?.close();
          this.startConversationDialogController = null;
        }
      }),
      autoCancel: false,
      alignment: DialogAlignment.Default,
      customStyle: true,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      maskColor: Color.Transparent,
      cancel: () => {
        this.startConversationDialogController = null;
      }
    });


    this.startConversationDialogController.open();
  }

  private handleCreateGroup(): void {
    console.info('[ConversationPage] handleCreateGroup')
    if (pushStartConversationPage(DialogType.CREATE_GROUP, undefined, (groupInfo: GroupInfo) => {
      this.openConversationWithGroup(groupInfo);
    })) {
      return;
    }


    if (this.createGroupDialogController) {
      this.createGroupDialogController.close();
      this.createGroupDialogController = null;
    }


    this.createGroupDialogController = new CustomDialogController({
      builder: StartConversationDialog({
        dialogType: DialogType.CREATE_GROUP,
        onCancel: () => {

          this.createGroupDialogController = null;
        },
        onCreateGroup: (groupInfo: GroupInfo) => {
          if (groupInfo.groupID && this.onConversationClick) {
            const conversationInfo = new ConversationInfo();
            conversationInfo.conversationID = `group_${groupInfo.groupID}`;
            conversationInfo.title = groupInfo.groupName || groupInfo.groupID;
            conversationInfo.avatarURL = groupInfo.avatarUrl;
            this.onConversationClick(conversationInfo);
          }
          this.createGroupDialogController = null;
        }
      }),
      autoCancel: false,
      alignment: DialogAlignment.Default,
      customStyle: true,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      maskColor: Color.Transparent,
      cancel: () => {
        this.createGroupDialogController = null;
      }
    });


    this.createGroupDialogController.open();
  }

  private openConversationWithContact(contact: ContactInfo): void {
    if (contact.userID && this.onConversationClick) {
      const conversationInfo = new ConversationInfo();
      conversationInfo.conversationID = `c2c_${contact.userID}`;
      conversationInfo.title = contact.friendRemark || contact.nickname || contact.userID;
      conversationInfo.avatarURL = contact.avatarURL;
      this.onConversationClick(conversationInfo);
    }
  }

  private openConversationWithGroup(groupInfo: GroupInfo): void {
    if (groupInfo.groupID && this.onConversationClick) {
      const conversationInfo = new ConversationInfo();
      conversationInfo.conversationID = `group_${groupInfo.groupID}`;
      conversationInfo.title = groupInfo.groupName || groupInfo.groupID;
      conversationInfo.avatarURL = groupInfo.avatarUrl;
      this.onConversationClick(conversationInfo);
    }
  }

  private showChatDialog(conversationID: string, title: string, avatarURL?: string, message?: MessageInfo): void {
    const conversationInfo = new ConversationInfo();
    conversationInfo.conversationID = conversationID;
    conversationInfo.title = title;
    conversationInfo.avatarURL = avatarURL ?? '';
    
    if (message && this.onConversationClickWithMessage) {
      this.onConversationClickWithMessage(conversationInfo, message);
    } else if (this.onConversationClick) {
      this.onConversationClick(conversationInfo);
    }
  }

}
