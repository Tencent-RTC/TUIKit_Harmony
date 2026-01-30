import {
  ContactInfo,
  ContactListState,
  ContactListStore,
  GroupMember,
  ErrorInfo
} from '@tencentcloud/atomicxcore';
import { ThemeState, TextUtils, LanguageState } from '../../basecomponent/Index';
import { ContactDetailPage } from '../../contactlist/pages/dialog/ContactDetailPage';
import { C2CChatSetting } from '../pages/C2CChatSetting';
import { ComponentContent, ImmersiveMode, LevelMode, promptAction } from '@kit.ArkUI';
import { UIContext } from '@ohos.arkui.UIContext';
import { BusinessError } from '@kit.BasicServicesKit';

export interface UserInteractionResult {
  isFriend: boolean;
  userInfo?: ContactInfo;
  conversationID?: string;
}


interface C2CDialogParams {
  userID: string;
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onContactDelete?: () => void;
}


interface ContactDetailDialogParams {
  userInfo: ContactInfo;
}

export class UserInteractionHelper {
  private static currentContentNode: ComponentContent<C2CDialogParams | ContactDetailDialogParams> | null = null;
  private static ctx: UIContext | null = null;
  
  private contactListStore: ContactListStore;
  private contactListState: ContactListState;

  constructor() {
    this.contactListStore = ContactListStore.create();
    this.contactListState = this.contactListStore.state;
  }

  static setUIContext(context: UIContext): void {
    UserInteractionHelper.ctx = context;
  }

  checkFriendStatus(userID: string): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      this.contactListStore.fetchUserInfo(userID)
        .then(() => {
          const userInfo = this.contactListState.addFriendInfo;
          if (userInfo) {
            const isFriend = userInfo.isContact === true;
            resolve(isFriend);
          } else {
            resolve(false);
          }
        })
        .catch((error: ErrorInfo) => {
          console.error(`[UserInteractionHelper] Failed to fetch user info: ${error.message}`);
          reject(error);
        });
    });
  }


  createContactInfoFromMember(member: GroupMember): ContactInfo {
    const contactInfo = new ContactInfo(
      member.userID || '', 
      member.avatarURL || '', 
      member.nameCard || member.nickname || member.userID || ''
    );
    contactInfo.contactID = member.userID || '';
    contactInfo.avatarURL = member.avatarURL || '';
    contactInfo.title = member.nameCard || member.nickname || member.userID || '';
    contactInfo.isContact = false;
    return contactInfo;
  }

  createContactInfoFromUserID(userID: string): ContactInfo {
    const contactInfo = new ContactInfo(userID, '', userID);
    contactInfo.contactID = userID;
    contactInfo.title = userID;
    contactInfo.isContact = false;
    return contactInfo;
  }

  getUserInteractionInfo(userID: string): Promise<UserInteractionResult> {
    return new Promise<UserInteractionResult>((resolve, reject) => {
      console.log(`[UserInteractionHelper] Getting interaction info for user: ${userID}`);
      
      this.checkFriendStatus(userID)
        .then((isFriend: boolean) => {
          const userInfo = this.contactListState.addFriendInfo || this.createContactInfoFromUserID(userID);
          const result: UserInteractionResult = {
            isFriend: isFriend,
            userInfo: userInfo,
            conversationID: isFriend ? 'c2c_' + userID : undefined
          };
          resolve(result);
        })
        .catch((error: ErrorInfo) => {
          console.error(`[UserInteractionHelper] Failed to get user interaction info: ${error.message}`);
          const fallbackUserInfo = this.createContactInfoFromUserID(userID);
          const result: UserInteractionResult = {
            isFriend: false,
            userInfo: fallbackUserInfo,
            conversationID: undefined
          };
          resolve(result); 
        });
    });
  }

  
  showUserProfileByFriendship(
    userID: string,
    context: UIContext,
    onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void,
    onContactDelete?: () => void
  ): void {
    console.log(`[UserInteractionHelper] Show user profile by friendship for user: ${userID}`);
    
    UserInteractionHelper.setUIContext(context);
    
    this.getUserInteractionInfo(userID)
      .then((result: UserInteractionResult) => {
        if (result.isFriend) {
          UserInteractionHelper.showC2CSettingDialog(
            userID,
            onSendMessageClick,
            onContactDelete
          );
        } else if (result.userInfo) {
          UserInteractionHelper.showContactDetailDialog(result.userInfo);
        }
      })
      .catch((error: Error) => {
        console.error(`[UserInteractionHelper] Failed to show user profile by friendship: ${error.message}`);
      });
  }

  static showC2CSettingDialog(
    userID: string,
    onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void,
    onContactDelete?: () => void
  ): void {
    if (!UserInteractionHelper.ctx) {
      console.error('[UserInteractionHelper] UIContext not set. Call setUIContext() first.');
      return;
    }

    if (UserInteractionHelper.currentContentNode) {
      UserInteractionHelper.closeDialog();
    }

    const params: C2CDialogParams = {
      userID: userID,
      onSendMessageClick: onSendMessageClick,
      onContactDelete: onContactDelete
    };

    UserInteractionHelper.currentContentNode = new ComponentContent(
      UserInteractionHelper.ctx,
      wrapBuilder(C2CDialogBuilder),
      params
    );

    const options: promptAction.BaseDialogOptions = {
      alignment: DialogAlignment.TopStart,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      autoCancel: false,
      maskColor: Color.Transparent
    };

    UserInteractionHelper.ctx.getPromptAction()
      .openCustomDialog(UserInteractionHelper.currentContentNode, options)
      .then(() => {
        console.info('[UserInteractionHelper] C2C setting dialog opened successfully');
      })
      .catch((error: BusinessError) => {
        console.error(`[UserInteractionHelper] Failed to open C2C setting dialog: ${error.message}`);
      });
  }

  static showContactDetailDialog(userInfo: ContactInfo): void {
    if (!UserInteractionHelper.ctx) {
      console.error('[UserInteractionHelper] UIContext not set. Call setUIContext() first.');
      return;
    }

    if (UserInteractionHelper.currentContentNode) {
      UserInteractionHelper.closeDialog();
    }

    const params: ContactDetailDialogParams = {
      userInfo: userInfo
    };

    UserInteractionHelper.currentContentNode = new ComponentContent(
      UserInteractionHelper.ctx,
      wrapBuilder(ContactDetailDialogBuilder),
      params
    );

    const options: promptAction.BaseDialogOptions = {
      alignment: DialogAlignment.TopStart,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      autoCancel: false,
      maskColor: Color.Transparent
    };

    UserInteractionHelper.ctx.getPromptAction()
      .openCustomDialog(UserInteractionHelper.currentContentNode, options)
      .then(() => {
        console.info('[UserInteractionHelper] Contact detail dialog opened successfully');
      })
      .catch((error: BusinessError) => {
        console.error(`[UserInteractionHelper] Failed to open contact detail dialog: ${error.message}`);
      });
  }

  static closeDialog(): void {
    if (UserInteractionHelper.currentContentNode && UserInteractionHelper.ctx) {
      UserInteractionHelper.ctx.getPromptAction()
        .closeCustomDialog(UserInteractionHelper.currentContentNode)
        .then(() => {
          console.info('[UserInteractionHelper] Dialog closed successfully');
          UserInteractionHelper.currentContentNode = null;
        })
        .catch((error: BusinessError) => {
          console.error(`[UserInteractionHelper] Failed to close dialog: ${error.message}`);
        });
    }
  }
}

class MockDialogController {
  close(): void {
    UserInteractionHelper.closeDialog();
  }
}

@Component
struct C2CDialogComponent {
  @Prop userID: string = '';
  onSendMessageClick?: (newConversationID?: string, title?: string, avatarUrl?: string) => void;
  onContactDelete?: () => void;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  private mockDialogController: MockDialogController = new MockDialogController();

  build() {
    C2CChatSetting({
      userID: this.userID,
      dialogController: this.mockDialogController as CustomDialogController,
      onSendMessageClick: (newConversationID?: string, title?: string, avatarUrl?: string) => {
        if (this.onSendMessageClick) {
          this.onSendMessageClick(newConversationID, title, avatarUrl);
        }
      },
      onContactDelete: () => {
        console.log('[UserInteractionHelper] Contact deleted, closing dialog');
        if (this.onContactDelete) {
          this.onContactDelete();
        }
      }
    })
  }
}


@Component
struct ContactDetailDialogComponent {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @StorageLink('LanguageState') languageState: LanguageState = LanguageState.getInstance();
  @Prop userInfo?: ContactInfo = undefined;

  @Builder
  NavigationBarBuilder() {
    Row() {
      // Back button
      Image($rawfile('basecomponent/common_back_icon.svg'))
        .width(16)
        .height(16)
        .fillColor(this.themeState.colors.textColorLink)
        .scale({
          x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
          y: 1
        })
        .onClick(() => {
          UserInteractionHelper.closeDialog();
        })

      Blank()

      // Title
      Text($r('app.string.info'))
        .fontSize(18)
        .fontWeight(600)
        .fontFamily('SF Pro Display')
        .fontColor(this.themeState.colors.textColorPrimary)

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: this.themeState.colors.strokeColorSecondary })
  }

  build() {
    Column({ space: 0 }) {
      // Navigation Bar
      this.NavigationBarBuilder()

      // Contact Detail Content
      Column() {
        ContactDetailPage({
          userInfo: this.userInfo,
          onClose: () => {
            UserInteractionHelper.closeDialog();
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.themeState.colors.bgColorOperate)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

@Builder
function C2CDialogBuilder(params: C2CDialogParams) {
  C2CDialogComponent({
    userID: params.userID,
    onSendMessageClick: params.onSendMessageClick,
    onContactDelete: params.onContactDelete
  })
}


@Builder
function ContactDetailDialogBuilder(params: ContactDetailDialogParams) {
  ContactDetailDialogComponent({
    userInfo: params.userInfo
  })
}
