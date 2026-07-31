import { ContactInfo, ContactState, ContactStore } from '@tencentcloud/atomicxcore';
import { GroupMember } from '@tencentcloud/atomicxcore';
import { ThemeState, LanguageState } from '../../basecomponent/Index';
import { GetContactInfoCompletionHandlerAdapter } from '../../basecomponent/utils/CompletionHandlers';
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

  private contactStore: ContactStore;
  private contactState: ContactState;

  constructor() {
    this.contactStore = ContactStore.shared;
    this.contactState = this.contactStore.state as ContactState;
  }

  static setUIContext(context: UIContext): void {
    UserInteractionHelper.ctx = context;
  }

  checkFriendStatus(userID: string): Promise<ContactInfo | undefined> {
    return new Promise<ContactInfo | undefined>((resolve: (info: ContactInfo | undefined) => void, reject: (e: Error) => void) => {
      const completion = new GetContactInfoCompletionHandlerAdapter((contactInfoList: ContactInfo[]) => {
        const userInfo: ContactInfo | undefined = contactInfoList && contactInfoList.length > 0 ? contactInfoList[0] : undefined;
        resolve(userInfo);
      }, (code: number, desc: string) => {
        console.error(`[UserInteractionHelper] Failed to fetch user info: code=${code}, desc=${desc}`);
        reject(new Error(`getContactInfo failed: code=${code}, desc=${desc}`));
      });
      this.contactStore.getContactInfo([userID], completion);
    });
  }


  createContactInfoFromMember(member: GroupMember): ContactInfo {
    const contactInfo = new ContactInfo(member.userID || '');
    contactInfo.avatarURL = member.avatarURL || '';
    contactInfo.nickname = member.nameCard || member.nickname || member.userID || '';
    contactInfo.isFriend = false;
    return contactInfo;
  }

  createContactInfoFromUserID(userID: string): ContactInfo {
    const contactInfo = new ContactInfo(userID);
    contactInfo.nickname = userID;
    contactInfo.isFriend = false;
    return contactInfo;
  }

  getUserInteractionInfo(userID: string): Promise<UserInteractionResult> {
    return new Promise<UserInteractionResult>((resolve: (r: UserInteractionResult) => void, _reject: (e: Error) => void) => {
      console.log(`[UserInteractionHelper] Getting interaction info for user: ${userID}`);

      this.checkFriendStatus(userID)
        .then((userInfo: ContactInfo | undefined) => {
          const finalUserInfo: ContactInfo = userInfo || this.createContactInfoFromUserID(userID);
          const isFriend: boolean = finalUserInfo.isFriend === true;
          const result: UserInteractionResult = {
            isFriend: isFriend,
            userInfo: finalUserInfo,
            conversationID: isFriend ? 'c2c_' + userID : undefined
          };
          resolve(result);
        })
        .catch((error: Error) => {
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
      Row() {
        Image($rawfile('basecomponent/common_back_icon.svg'))
          .width(16)
          .height(16)
          .fillColor(this.themeState.colors.textColorLink)
          .scale({
            x: this.languageState.getLayoutDirection() === LayoutDirection.RTL ? -1 : 1,
            y: 1
          })
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
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