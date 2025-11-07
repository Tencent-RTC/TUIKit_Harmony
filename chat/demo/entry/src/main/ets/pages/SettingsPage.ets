import { MMKV } from '@tencent/mmkv';
import { ErrorInfo, LoginStore, UserProfile, Gender, LoginState } from '@tencentcloud/atomicxcore';
import { ImageSizeUtil, ThemeState, Log, Toast, TextUtils, ToastType, Avatar, AvatarSize , AvatarContentType,AvatarShape } from '@tencentcloud/atomicx';

import Prompt from '@system.prompt';
import router from '@ohos.router';
import DemoConstants from '../utils/DemoConstants';
import { i18n } from '@kit.LocalizationKit';
import systemDateTime from '@ohos.systemDateTime';
import { Configuration, ImmersiveMode, LengthMetrics, LevelMode } from '@kit.ArkUI';
import { Want, common } from '@kit.AbilityKit';
import { ThemeMode } from '@tencentcloud/atomicx';
import { AvatarSelector } from '@tencentcloud/atomicx';


class LanguageModel {
  languageID: string = "";        
  languageName: string = "";      
  nameInCurrentLanguage: Resource = $r('app.string.language_chinese'); 
  selected: boolean = false;      

  constructor(languageID: string, languageName: string, nameInCurrentLanguage: Resource, selected: boolean = false) {
    this.languageID = languageID;
    this.languageName = languageName;
    this.nameInCurrentLanguage = nameInCurrentLanguage;
    this.selected = selected;
  }
}

@Component
@Preview
@Entry
export struct SettingsPage {
  private static readonly LARGE_TITLE_HEIGHT: number = 52;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @State loginState: LoginState = LoginStore.shared().state;
  
  private profileDetailDialogController?: CustomDialogController;

  build() {
    Column() {
      // TitleBar({ propTitle: "", title: $r('app.string.demo_profile_tab_name'), canBack: false })
      this.LargeTitleBuilder();
      Scroll() {
        Column() {
          SelfInfoView({ 
            loginState: this.loginState,
            onProfileClick: () => {
              this.showProfileDetailDialog();
            }
          })
          SettingItemView({ 
            loginState: this.loginState
          })
          Column() {
            Button($r("app.string.demo_logout_button_name"), { type: ButtonType.Normal, stateEffect: true })
              .fontColor(Color.White)
              .backgroundColor(this.themeState.colors.buttonColorPrimaryDefault)
              .width('90%')
              .borderRadius(8)
              .height(56)
              .margin({ top: 16, bottom: 38 })
              .onClick(() => {
                LoginStore.shared().logout().then(() => {
                  let mmkv = MMKV.defaultMMKV();
                  mmkv.removeValueForKey(DemoConstants.AUTO_LOGIN);
                  mmkv.removeValueForKey(DemoConstants.LOGIN_USER_SIG);
                  return router.replaceUrl({ url: "pages/DevLoginPage" });
                }).catch((reason: Object) => {
                  Log.e("Profile", "logout failed, " + reason);
                })
              })

          }
          .width('100%')
          .margin({ top: "10vp" })
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
  
  private showProfileDetailDialog() {
    this.profileDetailDialogController = new CustomDialogController({
      builder: ProfileDetailDialog({
        onClose: () => {
          if (this.profileDetailDialogController) {
            this.profileDetailDialogController.close();
            this.profileDetailDialogController = undefined;
          }
        }
      }),
      alignment: DialogAlignment.Default,
      customStyle: true,
      autoCancel: true,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      cancel: () => {
        this.profileDetailDialogController = undefined;
      }
    });
    this.profileDetailDialogController.open();
  }

  @Builder
  LargeTitleBuilder() {
    Row() {
      Text($r('app.string.setting_title'))
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontFamily('PingFang HK')
        .layoutWeight(1)
    }
    .width('100%')
    .height(SettingsPage.LARGE_TITLE_HEIGHT)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

@Component
struct SelfInfoView {
  @Prop @Watch('onLoginStateChange') loginState: LoginState;
  onProfileClick?: () => void;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  onLoginStateChange() {
    // This will be called when loginState changes
  }

  build() {
    RelativeContainer() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: this.loginState.loginUserInfo?.avatarURL,
          name: TextUtils.getAvatarLetter(this.loginState.loginUserInfo?.nickname || this.loginState.loginUserInfo?.userID) || '',
        },
        avatarSize: AvatarSize.XL,
        shape:AvatarShape.Round
      })
        .id("faceUrl")
        .alignRules({
          start: { anchor: "__container__", align: HorizontalAlign.Start },
        })

      Text(this.loginState.loginUserInfo?.nickname || this.loginState.loginUserInfo?.userID)
        .id("userName")
        .fontSize($r("app.float.demo_profile_name_font_size"))
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({
          left: 16
        })
        .alignRules({
          left: { anchor: "faceUrl", align: HorizontalAlign.End },
          top: { anchor: "faceUrl", align: VerticalAlign.Top }
        })

      Row() {
        Text("ID:")
          .id("userIDLabel")
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontSize($r("app.float.demo_profile_id_font_size"))

        Text(this.loginState.loginUserInfo?.userID)
          .id("userID")
          .fontColor(this.themeState.colors.textColorPrimary)
          .fontSize($r("app.float.demo_profile_id_font_size"))
      }
      .id("idRow")
      .margin({ top: 10 })
      .alignRules({
        left: { anchor: "userName", align: HorizontalAlign.Start },
        top: { anchor: "userName", align: VerticalAlign.Bottom },
      })

      Text($r("app.string.demo_profile_signature_label"))
        .id("signatureLabel")
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontSize($r("app.float.demo_profile_id_font_size"))
        .margin({ top: 10 })
        .alignRules({
          left: { anchor: "idRow", align: HorizontalAlign.Start },
          top: { anchor: "idRow", align: VerticalAlign.Bottom }
        })

      Text(this.loginState.loginUserInfo?.selfSignature)
        .id("signature")
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontSize($r("app.float.demo_profile_id_font_size"))
        .alignRules({
          left: { anchor: "signatureLabel", align: HorizontalAlign.End },
          top: { anchor: "signatureLabel", align: VerticalAlign.Top }
        })

      Image($rawfile("basecomponent/common_forward_icon.svg"))
        .id("forwardIcon")
        .width(14)
        .height(14)
        .objectFit(ImageFit.Contain)
        .alignRules({
          right: { anchor: "__container__", align: HorizontalAlign.End },
          center: { anchor: "idRow", align: VerticalAlign.Center }
        })
    }
    .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    .id("selfInfoSettings")
    .width('100%')
    .height('auto')
    .padding({
      top: $r("app.float.demo_profile_face_image_margin_top"),
      bottom: $r("app.float.demo_profile_face_image_margin_top"),
      left: 16,
      right: 16
    })
    .borderRadius(12)
    .margin({ top: 16, left: 16, right: 16 })
        .onClick(() => {
          this.onProfileClick?.();
        })
  }
}

@Component
struct SettingItemView {
  @State themeSelectVisible: boolean = false;
  @State friendRequestVisible: boolean = false;
  @State languageSelectVisible: boolean = false;
  @State currentAllowTypeText: string | Resource = '';
  @State currentThemeText: string | Resource= '';
  @State currentLanguageText: string | Resource = '';
  @Prop @Watch('onLoginStateChange') loginState: LoginState;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  // Language models array
  @State languageModels: LanguageModel[] = [];
  dialogController: CustomDialogController = new CustomDialogController({
    builder: ThemeSelectDialog({
      onClose: () => {
        this.themeSelectVisible = false;
      },
      onSelectTheme: (theme: string) => {
        switch (theme) {
          case 'light':
            this.themeState.setThemeMode(ThemeMode.light);
            break;
          case 'dark':
            this.themeState.setThemeMode(ThemeMode.dark);
            break;
          case 'system':
            this.themeState.setThemeMode(ThemeMode.system);
            break;
          case 'custom':
            this.themeState.setPrimaryColor(this.generateRandomColor())
            break;
        }
        this.themeSelectVisible = false;
        // Update theme text immediately
        this.currentThemeText = this.getThemeText(this.themeState.currentMode);
      }
    }),
    cancel: () => {
      this.themeSelectVisible = false;
    },
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    maskColor: 'rgba(0, 0, 0, 0.6)'
  });

  friendRequestDialogController: CustomDialogController = new CustomDialogController({
    builder: FriendRequestDialog({
      currentAllowType: this.getCurrentAllowType(),
      onClose: () => {
        this.friendRequestVisible = false;
      },
      onSelectAllowType: (allowType: number) => {
        this.updateAllowType(allowType);
        this.friendRequestVisible = false;
      }
    }),
    cancel: () => {
      this.friendRequestVisible = false;
    },
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    maskColor: 'rgba(0, 0, 0, 0.6)'
  });

  languageDialogController: CustomDialogController = new CustomDialogController({
    builder: LanguageSelectDialog({
      languageModels: this.languageModels,
      onClose: () => {
        this.languageSelectVisible = false;
      },
      onSelectLanguage: (language: string) => {
        this.updateLanguage(language);
        this.languageSelectVisible = false;
      }
    }),
    cancel: () => {
      this.languageSelectVisible = false;
    },
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    maskColor: 'rgba(0, 0, 0, 0.6)'
  });

  aboutToAppear() {
    this.initializeLanguageModels();
    this.updateStatusTexts();
  }


  private initializeLanguageModels() {
    this.languageModels = [
      new LanguageModel("zh-CN", "简体中文", $r('app.string.language_chinese')),
      new LanguageModel("en-US", "English", $r('app.string.language_english')),
      new LanguageModel("ar-SA", "العربية", $r('app.string.language_arabic'))
    ];
    this.updateLanguageSelection();
  }

  private updateLanguageSelection() {
    const currentLang = this.getCurrentLanguage();
    this.languageModels.forEach(model => {
      model.selected = currentLang.startsWith(model.languageID.split('-')[0]);
    });
  }

  onLoginStateChange() {
    // This will be called when loginState changes
    this.updateStatusTexts();
  }

  private getCurrentAllowType(): number {
    return this.loginState.loginUserInfo?.allowType || 0;
  }

  private updateStatusTexts() {
    // Update allow type text
    const allowType = this.getCurrentAllowType();
    this.currentAllowTypeText = this.getAllowTypeText(allowType);
    // Update theme text
    this.currentThemeText = this.getThemeText(this.themeState.currentMode);
    // Update language text
    this.currentLanguageText = this.getLanguageText(this.getCurrentLanguage());
  }

  build() {
    Column() {
      SettingItem({ 
        text: $r("app.string.friend_request_setting"),
        status: this.currentAllowTypeText
      })
        .onClick(() => {
          this.friendRequestDialogController.open();
          this.friendRequestVisible = true;
        })
      SettingItem({ 
        text: $r("app.string.demo_theme_button_name"),
        status: this.currentThemeText
      })
        .onClick(() => {
          this.dialogController.open();
          this.themeSelectVisible = true;
        })

      Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')

      SettingItem({ 
        text: $r("app.string.demo_switch_language_button_name"),
        status: this.currentLanguageText
      })
        .onClick(() => {
          this.languageDialogController.open();
          this.languageSelectVisible = true;
        })

      Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')

      SettingItem({ text: $r("app.string.demo_about_button_name") })
        .onClick(() => {
          Toast.info($r("app.string.demo_title"), this.getUIContext());
        })

      Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')
    }
    .width('100%')
    .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
    .borderRadius(12)
    .margin({ top: 16, left: 16, right: 16 })
  }

  private generateRandomColor(): string {

    const colorPalettes = [

      '#1E88E5', '#2196F3', '#42A5F5', '#64B5F6', '#0D47A1', '#1565C0',

      '#43A047', '#4CAF50', '#66BB6A', '#81C784', '#2E7D32', '#388E3C',

      '#E53935', '#F44336', '#EF5350', '#E57373', '#C62828', '#D32F2F',

      '#FB8C00', '#FF9800', '#FFA726', '#FFB74D', '#E65100', '#F57C00',

      '#8E24AA', '#9C27B0', '#AB47BC', '#BA68C8', '#6A1B9A', '#7B1FA2',

      '#00ACC1', '#00BCD4', '#26C6DA', '#4DD0E1', '#006064', '#00838F',

      '#00695C', '#00796B', '#26A69A', '#4DB6AC', '#004D40', '#00695C',

      '#3F51B5', '#5C6BC0', '#7986CB', '#9FA8DA', '#283593', '#303F9F'
    ];
    const randomIndex = Math.floor(Math.random() * colorPalettes.length);
    return colorPalettes[randomIndex];
  }

  private restartApplication() {
    try {
      const context = getContext() as common.UIAbilityContext;


      setTimeout(() => {

        context.terminateSelf().then(() => {
          console.info('Application terminated successfully');

          context.startAbility({
            bundleName: context.applicationInfo.name,
            abilityName: 'EntryAbility'
          }).then(() => {
            console.info('Application restarted successfully');
          }).catch((error: Error) => {
            console.error('Failed to restart application:', error);
          });
        }).catch((error: Error) => {
          console.error('Failed to terminate application:', error);
          this.fallbackRestart();
        });
      }, 500);

    } catch (error) {
      console.error('Error during application restart:', error);
      this.fallbackRestart();
    }
  }

  private fallbackRestart() {
    try {

      router.clear();


      router.replaceUrl({
        url: 'pages/SplashScreenPage'
      }).then(() => {
        console.info('Page reloaded successfully');
      }).catch((error: Error) => {
        console.error('Failed to reload page:', error);
      });

    } catch (error) {
      console.error('Fallback restart failed:', error);
    }
  }

  private updateAllowType(allowType: number) {
    // Get current user info
    const currentUserInfo = this.loginState.loginUserInfo;
    if (currentUserInfo) {
      // Create updated user profile
      const updatedUserInfo = new UserProfile(
        currentUserInfo.userID,
        currentUserInfo.nickname,
        currentUserInfo.avatarURL
      );
      updatedUserInfo.selfSignature = currentUserInfo.selfSignature;
      updatedUserInfo.gender = currentUserInfo.gender;
      updatedUserInfo.role = currentUserInfo.role;
      updatedUserInfo.level = currentUserInfo.level;
      updatedUserInfo.birthday = currentUserInfo.birthday;
      updatedUserInfo.allowType = allowType;
      updatedUserInfo.customInfo = currentUserInfo.customInfo;

      // Update user info via LoginStore
      LoginStore.shared().setSelfInfo(updatedUserInfo).then(() => {
        const allowTypeText = this.getAllowTypeText(allowType);
        const updateMessage = getContext().resourceManager.getStringSync($r('app.string.friend_request_updated'));
        Toast.success(allowTypeText, this.getUIContext());
      }).catch((error:ErrorInfo) => {
        console.error('Failed to update allowType:', error);
        Toast.error($r('app.string.friend_request_update_failed'), this.getUIContext());
      });
    }
  }

  private getAllowTypeText(allowType: number): Resource {
    switch (allowType) {
      case 0:
        return $r('app.string.friend_request_allow_any');
      case 1:
        return $r('app.string.friend_request_need_confirm');
      case 2:
        return $r('app.string.friend_request_deny_any');
      default:
        return $r('app.string.friend_request_need_confirm');
    }
  }

  private getThemeText(themeMode: ThemeMode): string | Resource {
    switch (themeMode) {
      case ThemeMode.light:
        return $r('app.string.theme_light');
      case ThemeMode.dark:
        return $r('app.string.theme_dark');
      case ThemeMode.system:
        return $r('app.string.theme_system');
      default:
        return $r('app.string.theme_system');
    }
  }

  private getCurrentLanguage(): string {
    let mmkv = MMKV.defaultMMKV();
    let currentLanguage = mmkv.decodeString("currentLanguage") ?? Configuration.getLocale().language;
    let preferredLanguage = i18n.System.getAppPreferredLanguage();
    if (preferredLanguage && preferredLanguage.length > 0) {
      currentLanguage = preferredLanguage;
    } else {
      currentLanguage = Configuration.getLocale().language;
    }
    return currentLanguage;
  }

  private getDisplayLanguageText(language: string): string | Resource {
    const model = this.languageModels.find(model => 
      language.startsWith(model.languageID.split('-')[0])
    );
    return model ? model.nameInCurrentLanguage : this.languageModels[0]?.nameInCurrentLanguage || '';
  }

  private getLanguageText(language: string): string | Resource {
    const model = this.languageModels.find(model => 
      language.startsWith(model.languageID.split('-')[0])
    );
    
    if (model) {
      try {
        return model.nameInCurrentLanguage;
      } catch (error) {
        // Fallback to display text if resource strings are not available
        return model.languageName;
      }
    }
    
    return this.languageModels[0]?.languageName || '';
  }

  private updateLanguage(language: string) {
    let appContext = getContext().getApplicationContext();
    let mmkv = MMKV.defaultMMKV();

    mmkv.encodeString("currentLanguage", language);

    try {
      appContext.setLanguage(language);
      i18n.System.setAppPreferredLanguage(language);
      console.info("Configuration.getLocale().language ", Configuration.getLocale().language);
      console.info(`App preferred language set to: ${language}`);

      // Update language selection and text immediately for UI display
      this.updateLanguageSelection();
      this.currentLanguageText = this.getDisplayLanguageText(language);

      // this.restartApplication();

    } catch (error) {
      console.error('Failed to set app preferred language:', error);
    }
  }


}

@Component
struct SettingItem {
  text: string | Resource = "";
  @Prop  status?: string | Resource = undefined; // Optional status text to show on the right
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Column() {
      Row() {
        Text(this.text)
          .fontSize(17)
          .fontColor(this.themeState.colors.textColorPrimary)
          .layoutWeight(1)
          .margin({ left: 16 })
          .fontFamily('PingFang HK')

        // Status text (if provided)
          Text(this.status)
            .fontSize(15)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ right: 8 })
            .fontFamily('PingFang HK')
            .textAlign(TextAlign.End)

        Image($rawfile("basecomponent/common_forward_icon.svg"))
          .id("forwardIcon")
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
          .margin({ right: 16 })
      }
      .width('100%')
      .height(56)
      .padding({
        top: 8,
        bottom: 8
      })
    }
  }
}

@CustomDialog
struct FriendRequestDialog {
  private static readonly BUTTON_HEIGHT: number = 56;
  private static readonly BOTTOM_RADIUS: number = 14;
  controller?: CustomDialogController;
  currentAllowType: number = 1;
  onClose?: () => void;
  onSelectAllowType?: (allowType: number) => void;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Column() {
      // Title
      Text($r('app.string.friend_request_title'))
        .fontSize(18)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 16, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center)

      Column() {
        // Allow Any
        Row() {
          Text($r('app.string.friend_request_allow_any'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)

          if (this.currentAllowType === 0) {
            Image($r('app.media.ic_public_check'))
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
        }
        .width('100%')
        .height(FriendRequestDialog.BUTTON_HEIGHT)
        .padding({ start: LengthMetrics.vp(16), end: LengthMetrics.vp(16) })
        .onClick(() => {
          this.onSelectAllowType?.(0);
          this.controller?.close();
        })

        Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')

        // Need Confirm
        Row() {
          Text($r('app.string.friend_request_need_confirm'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)

          if (this.currentAllowType === 1) {
            Image($r('app.media.ic_public_check'))
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
        }
        .width('100%')
        .height(FriendRequestDialog.BUTTON_HEIGHT)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onSelectAllowType?.(1);
          this.controller?.close();
        })

        Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')

        // Deny Any
        Row() {
          Text($r('app.string.friend_request_deny_any'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)

          if (this.currentAllowType === 2) {
            Image($r('app.media.ic_public_check'))
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
        }
        .width('100%')
        .height(FriendRequestDialog.BUTTON_HEIGHT)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onSelectAllowType?.(2);
          this.controller?.close();
        })
      }
      .width('100%')
      .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius(12)

      // Cancel Button
      Button($r('app.string.cancel'))
        .width('100%')
        .height(FriendRequestDialog.BUTTON_HEIGHT)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.buttonColorPrimaryDefault)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .borderRadius(FriendRequestDialog.BOTTOM_RADIUS)
        .margin({ top: 12, bottom: 38 })
        .onClick(() => {
          this.onClose?.();
          this.controller?.close();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

@CustomDialog
struct LanguageSelectDialog {
  private static readonly BUTTON_HEIGHT: number = 56;
  private static readonly BOTTOM_RADIUS: number = 14;
  controller?: CustomDialogController;
  @Prop languageModels: LanguageModel[] = [];
  onClose?: () => void;
  onSelectLanguage?: (language: string) => void;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Column() {
      // Title
      Text($r('app.string.language_select_title'))
        .fontSize(18)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 16, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center)

      Column() {
        // Dynamic language options using language models
        ForEach(this.languageModels, (model: LanguageModel, index: number) => {
          Column() {
            Row() {
              Text(model.nameInCurrentLanguage)
                .fontSize(17)
                .fontColor(this.themeState.colors.textColorPrimary)
                .fontFamily('PingFang HK')
                .fontWeight(400)
                .layoutWeight(1)

              if (model.selected) {
                Image($r('app.media.ic_public_check'))
                  .width(24)
                  .height(24)
                  .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
              }
            }
            .width('100%')
            .height(LanguageSelectDialog.BUTTON_HEIGHT)
            .padding({ start: LengthMetrics.vp(16), end: LengthMetrics.vp(16) })
            .onClick(() => {
              this.onSelectLanguage?.(model.languageID);
              this.controller?.close();
            })

            // Add divider except for the last item
            if (index < this.languageModels.length - 1) {
              Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')
            }
          }
        }, (model: LanguageModel) => model.languageID)
      }
      .width('100%')
      .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius(12)

      // Cancel Button
      Button($r('app.string.cancel'))
        .width('100%')
        .height(LanguageSelectDialog.BUTTON_HEIGHT)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.buttonColorPrimaryDefault)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .borderRadius(LanguageSelectDialog.BOTTOM_RADIUS)
        .margin({ top: 12, bottom: 38 })
        .onClick(() => {
          this.onClose?.();
          this.controller?.close();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

@CustomDialog
struct ThemeSelectDialog {
  private static readonly BUTTON_HEIGHT: number = 56;
  private static readonly BOTTOM_RADIUS: number = 14;
  controller?: CustomDialogController;
  onClose?: () => void;
  onSelectTheme?: (theme: string) => void;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Column() {
      // Title
      Text($r('app.string.theme_select_title'))
        .fontSize(18)
        .fontColor(this.themeState.colors.textColorPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 16, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center)


      Column() {

        Row() {
          Text($r('app.string.theme_light'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)

          if (this.themeState.getCurrentThemeType() === 'light') {
            Image($r('app.media.ic_public_check'))
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
        }
        .width('100%')
        .height(ThemeSelectDialog.BUTTON_HEIGHT)
        .padding({ start: LengthMetrics.vp(16), end: LengthMetrics.vp(16) })
        .onClick(() => {
          this.onSelectTheme?.('light');
          this.controller?.close();
        })

        Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')


        Row() {
          Text($r('app.string.theme_dark'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)

          if (this.themeState.getCurrentThemeType() === 'dark') {
            Image($r('app.media.ic_public_check'))
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
        }
        .width('100%')
        .height(ThemeSelectDialog.BUTTON_HEIGHT)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onSelectTheme?.('dark');
          this.controller?.close();
        })

        Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')


        Row() {
          Text($r('app.string.theme_system'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)

          if (this.themeState.getCurrentThemeType() === 'system') {
            Image($r('app.media.ic_public_check'))
              .width(24)
              .height(24)
              .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
          }
        }
        .width('100%')
        .height(ThemeSelectDialog.BUTTON_HEIGHT)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onSelectTheme?.('system');
          this.controller?.close();
        })

        Divider().height(0.4).color(this.themeState.colors.strokeColorPrimary).width('100%')


        Row() {
          Text($r('app.string.theme_random_color'))
            .fontSize(17)
            .fontColor(this.themeState.colors.textColorPrimary)
            .fontFamily('PingFang HK')
            .fontWeight(400)
            .layoutWeight(1)
        }
        .width('100%')
        .height(ThemeSelectDialog.BUTTON_HEIGHT)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onSelectTheme?.('custom');
          this.controller?.close();
        })
      }
      .width('100%')
      .backgroundColor(this.themeState.colors.bgColorBubbleReciprocal)
      .borderRadius(12)


      Button($r('app.string.cancel'))
        .width('100%')
        .height(ThemeSelectDialog.BUTTON_HEIGHT)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.buttonColorPrimaryDefault)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .borderRadius(ThemeSelectDialog.BOTTOM_RADIUS)
        .margin({ top: 12, bottom: 38 })
        .onClick(() => {
          this.onClose?.();
          this.controller?.close();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }
}

@CustomDialog
struct ProfileDetailDialog {
  @State nickname: string = '';
  @State avatarURL: string = '';
  @State selfSignature: string = '';
  @State gender: Gender = Gender.UNKNOWN;
  @State birthday: number = 0;
  @State showNicknameDialog: boolean = false;
  @State showSignatureDialog: boolean = false;
  @State showGenderDialog: boolean = false;
  @State showBirthdayPicker: boolean = false;
  @State showAvatarSelector: boolean = false;
  // Reactive display texts
  @State displaySignature: string = '';
  @State displayGender: string | Resource = '';
  @State displayBirthday: string = '';
  controller?: CustomDialogController;
  onClose?: () => void;
  @State loginStore: LoginStore = LoginStore.shared();
  @State @Watch('onLoginStateChange') loginState?: LoginState = this.loginStore.state;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  
  private nicknameDialogController?: CustomDialogController;
  private signatureDialogController?: CustomDialogController;
  private genderDialogController?: CustomDialogController;
  private birthdayDialogController?: CustomDialogController;

  aboutToAppear() {
    // Initialize with current user info
    const loginUserInfo = this.loginState?.loginUserInfo;
    if (loginUserInfo) {
      this.nickname = loginUserInfo.nickname || '';
      this.avatarURL = loginUserInfo.avatarURL || '';
      this.selfSignature = loginUserInfo.selfSignature || '';
      this.gender = loginUserInfo.gender || Gender.UNKNOWN;
      this.birthday = loginUserInfo.birthday || 0;
    }
    this.updateDisplayTexts();
  }

  onLoginStateChange() {
    // Called when loginState changes - update display texts
    console.log('[ProfileDetailDialog] loginState changed, updating display texts');
    const loginUserInfo = this.loginState?.loginUserInfo;
    
    // Sync local state with new loginState
    if (loginUserInfo) {
      this.nickname = loginUserInfo.nickname || '';
      this.avatarURL = loginUserInfo.avatarURL || '';
      this.selfSignature = loginUserInfo.selfSignature || '';
      this.gender = loginUserInfo.gender || Gender.UNKNOWN;
      this.birthday = loginUserInfo.birthday || 0;
    }
    
    this.updateDisplayTexts();
  }

  private updateDisplayTexts() {
    // Update reactive display texts using loginState data directly
    const loginUserInfo = this.loginState?.loginUserInfo;
    
    // Force update each display text separately to ensure reactivity
    const newSignature = loginUserInfo?.selfSignature || getContext().resourceManager.getStringSync($r('app.string.no_self_signature'));
    const newGender = this.getGenderTextFromValue(loginUserInfo?.gender || Gender.UNKNOWN);
    const newBirthday = this.getBirthdayTextFromValue(loginUserInfo?.birthday || 0);
    
    // Only update if values actually changed
    if (this.displaySignature !== newSignature) {
      this.displaySignature = newSignature;
      console.log('[ProfileDetailDialog] Signature updated to:', newSignature);
    }
    
    if (this.displayGender !== newGender) {
      this.displayGender = newGender;
      console.log('[ProfileDetailDialog] Gender updated to:', newGender);
    }
    
    if (this.displayBirthday !== newBirthday) {
      this.displayBirthday = newBirthday;
      console.log('[ProfileDetailDialog] Birthday updated to:', newBirthday);
    }
    
    console.log('[ProfileDetailDialog] Display texts state:', {
      signature: this.displaySignature,
      gender: this.displayGender,
      birthday: this.displayBirthday,
      rawData: loginUserInfo
    });
  }

  aboutToDisappear() {
    // Clean up dialog controllers
    this.nicknameDialogController = undefined;
    this.signatureDialogController = undefined;
    this.genderDialogController = undefined;
    this.birthdayDialogController = undefined;
  }

  build() {
    Column() {
      // Header
      this.buildHeader()
      
      // Profile Avatar and Name Section
      this.buildProfileSection()
      
      // Profile Details List
      this.buildDetailsList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorDefault)
  }

  @Builder
  private buildHeader() {
    Row() {
      Button() {
        Image($rawfile("basecomponent/common_back_icon.svg"))
          .width(16)
          .height(16)
          .fillColor(this.themeState.colors.textColorPrimary)
      }
      .width(20)
      .height(20)
      .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.onClose) {
            this.onClose();
          } else if (this.controller) {
            this.controller.close();
          }
        })

      Text($r('app.string.profile_details'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // Placeholder for right button
      Row().width(44).height(44)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeState.colors.bgColorDefault)
  }

  @Builder
  private buildProfileSection() {
    Column({ space: 16 }) {
      // Avatar
      Button() {
        Avatar({
          content: {
            type: AvatarContentType.Image,
            url: this.avatarURL,
            name: TextUtils.getAvatarLetter(this.getNickName()) || '',
          },
          avatarSize: AvatarSize.XXL,
          shape:AvatarShape.Round
        })
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.showAvatarPickerDialog();
      })

      // Nickname with edit button
      Row({ space: 8 }) {
        Text(this.getNickName())
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeState.colors.textColorPrimary)

        Button() {
          Image($rawfile("basecomponent/common_forward_icon.svg"))
            .width(16)
            .height(16)
            .fillColor(this.themeState.colors.textColorLink)
        }
        .width(24)
        .height(24)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showNicknameEditDialog();
        })
      }
    }
    .width('100%')
    .padding({ top: 40, bottom: 30 })
  }

  @Builder
  private buildDetailsList() {
    List() {
      ListItem() {
        this.buildDetailItem($r('app.string.profile_account'), this.loginState?.loginUserInfo?.userID || '', false)
      }
      .backgroundColor(this.themeState.colors.listColorDefault)

      ListItem() {
        Row() {
          Text($r('app.string.profile_signature'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .layoutWeight(1)

          Text(this.displaySignature)
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Image($rawfile("basecomponent/common_forward_icon.svg"))
            .width(14)
            .height(14)
            .fillColor(this.themeState.colors.textColorSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.showSignatureEditDialog();
        })
      }
      .backgroundColor(this.themeState.colors.listColorDefault)

      ListItem() {
        Row() {
          Text($r('app.string.profile_gender'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .layoutWeight(1)

          Text(this.displayGender)
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Image($rawfile("basecomponent/common_forward_icon.svg"))
            .width(14)
            .height(14)
            .fillColor(this.themeState.colors.textColorSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.showGenderSelectDialog();
        })
      }
      .backgroundColor(this.themeState.colors.listColorDefault)

      ListItem() {
        Row() {
          Text($r('app.string.profile_birthday'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorPrimary)
            .layoutWeight(1)

          Text(this.displayBirthday)
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Image($rawfile("basecomponent/common_forward_icon.svg"))
            .width(14)
            .height(14)
            .fillColor(this.themeState.colors.textColorSecondary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.showBirthdayPickerDialog();
        })
      }
      .backgroundColor(this.themeState.colors.listColorDefault)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.themeState.colors.bgColorDefault)
    .divider({
      strokeWidth: 0.5,
      color: this.themeState.colors.strokeColorPrimary,
      startMargin: 16,
      endMargin: 16
    })
  }

  @Builder
  private buildDetailItem(title: Resource, value: string, clickable: boolean, onClick?: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)

      Text(value)
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .key(`detail_value_${value}`) // Add unique key to force re-render

      if (clickable) {
        Image($rawfile("basecomponent/common_forward_icon.svg"))
          .width(14)
          .height(14)
          .fillColor(this.themeState.colors.textColorSecondary)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      if (clickable && onClick) {
        onClick();
      }
    })
  }

  private getNickName(): string {
    if (this.nickname && this.nickname.length > 0) {
      return this.nickname;
    }
    return this.loginState?.loginUserInfo?.userID || '';
  }

  private getGenderTextFromValue(gender: Gender): string | Resource{
    switch (gender) {
      case Gender.MALE:
        return $r('app.string.gender_male')
      case Gender.FEMALE:
        return $r('app.string.gender_female');
      default:
        return $r('app.string.gender_unknown');
    }
  }

  private getBirthdayTextFromValue(birthday: number): string {
    if (birthday === 0) {
      return getContext().resourceManager.getStringSync($r('app.string.unsetted'));
    }
    const date = new Date(birthday * 1000);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  }

  private showNicknameEditDialog() {
    this.nicknameDialogController = new CustomDialogController({
      builder: TextEditDialog({
        title: $r('app.string.profile_edit_name'),
        currentText: this.nickname,
        placeholder: $r('app.string.profile_edit_name'),
        helpText: $r('app.string.profile_edit_name_desc'),
        onSave: (newText: string) => {
          this.updateNickname(newText);
        },
        onCancel: () => {
          this.showNicknameDialog = false;
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)'
    });
    this.nicknameDialogController.open();
    this.showNicknameDialog = true;
  }

  private showSignatureEditDialog() {
    this.signatureDialogController = new CustomDialogController({
      builder: TextEditDialog({
        title: $r('app.string.profile_edit_signature'),
        currentText: this.selfSignature,
        placeholder: $r('app.string.profile_edit_signature'),
        helpText: $r('app.string.profile_edit_name_desc'),
        onSave: (newText: string) => {
          this.updateSignature(newText);
        },
        onCancel: () => {
          this.showSignatureDialog = false;
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)'
    });
    this.signatureDialogController.open();
    this.showSignatureDialog = true;
  }

  private showGenderSelectDialog() {
    this.genderDialogController = new CustomDialogController({
      builder: GenderSelectDialog({
        currentGender: this.gender,
        onSelect: (gender: Gender) => {
          this.updateGender(gender);
        },
        onCancel: () => {
          this.showGenderDialog = false;
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true,
      maskColor: 'rgba(0, 0, 0, 0.6)'
    });
    this.genderDialogController.open();
    this.showGenderDialog = true;
  }

  private updateNickname(newNickname: string) {
    const userID = this.loginState?.loginUserInfo?.userID;
    if (userID) {
      const user = new UserProfile(userID);
      user.nickname = newNickname;
      
      LoginStore.shared().setSelfInfo(user).then(() => {
        this.nickname = newNickname;
        this.updateDisplayTexts();
        Toast.show($r('app.string.update_profile_success'), ToastType.Success, this.getUIContext(), 2000);
      }).catch((error: Error) => {
        Toast.show($r('app.string.update_profile_failed'), ToastType.Error, this.getUIContext(), 3000);
      });
    }
    this.showNicknameDialog = false;
  }

  private updateSignature(newSignature: string) {
    const userID = this.loginState?.loginUserInfo?.userID;
    if (userID) {
      const user = new UserProfile(userID);
      user.selfSignature = newSignature;
      
      LoginStore.shared().setSelfInfo(user).then(() => {
        this.selfSignature = newSignature;
        this.updateDisplayTexts();
        Toast.show($r('app.string.update_profile_success'), ToastType.Success, this.getUIContext(), 2000);
      }).catch((error: Error) => {
        Toast.show($r('app.string.update_profile_failed'), ToastType.Error, this.getUIContext(), 3000);
      });
    }
    this.showSignatureDialog = false;
  }

  private updateGender(newGender: Gender) {
    const userID = this.loginState?.loginUserInfo?.userID;
    if (userID) {
      const user = new UserProfile(userID);
      user.gender = newGender;
      
      LoginStore.shared().setSelfInfo(user).then(() => {
        this.gender = newGender;
        this.updateDisplayTexts();
        Toast.show($r('app.string.update_profile_success'), ToastType.Success, this.getUIContext(), 2000);
      }).catch((error: Error) => {
        const errorMessage = getContext().resourceManager.getStringSync($r('app.string.update_profile_failed'));
        Toast.show($r('app.string.update_profile_failed'), ToastType.Error, this.getUIContext(), 3000);
      });
    }
    this.showGenderDialog = false;
  }

  private showBirthdayPickerDialog() {
    // Use DatePickerDialog for birthday selection
    DatePickerDialog.show({
      start: new Date('1900-1-1'),
      end: new Date(),
      selected: this.birthday > 0 ? new Date(this.birthday * 1000) : new Date(),
      onAccept: (value: DatePickerResult) => {
        const selectedDate = new Date(value.year, value.month, value.day);
        const timestamp = Math.floor(selectedDate.getTime() / 1000);
        this.updateBirthday(timestamp);
      }
    });
  }

  private updateBirthday(newBirthday: number) {
    const userID = this.loginState?.loginUserInfo?.userID;
    if (userID) {
      const user = new UserProfile(userID);
      user.birthday = newBirthday;
      
      LoginStore.shared().setSelfInfo(user).then(() => {
        this.birthday = newBirthday;
        this.updateDisplayTexts();
        Toast.show($r('app.string.update_profile_success'), ToastType.Success, this.getUIContext(), 2000);
      }).catch((error: Error) => {
        Toast.show($r('app.string.update_profile_failed'), ToastType.Error, this.getUIContext(), 3000);
      });
    }
  }

  private showAvatarPickerDialog() {
    // Create user avatar URL list (1-26)
    const avatarUrls: string[] = Array.from<undefined, string>({ length: 26 }, (_: undefined, index: number): string =>
      `https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_${index + 1}.png`
    );

    // Create AvatarPickerDialog
    let avatarPickerController: CustomDialogController | undefined = undefined;
    
    avatarPickerController = new CustomDialogController({
      builder: AvatarPickerDialog({
        title: $r('app.string.profile_select_avatar'),
        urlList: avatarUrls,
        onConfirm: (selectedUrl: string, selectedIndex: number) => {
          this.updateAvatar(selectedUrl);
        },
        onCancel: () => {
          console.log('[ProfileDetailDialog] Avatar picker cancelled');
        },
        onClose: () => {
          // 由外部关闭对话框
          if (avatarPickerController) {
            avatarPickerController.close();
            avatarPickerController = undefined;
          }
        }
      }),
      alignment: DialogAlignment.Default,
      customStyle: true,
      autoCancel: true,
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      cancel: () => {
        console.log('[ProfileDetailDialog] Avatar picker dialog cancelled');
        avatarPickerController = undefined;
      }
    });
    
    avatarPickerController.open();
  }

  private updateAvatar(newAvatarURL: string) {
    const userID = this.loginState?.loginUserInfo?.userID;
    if (userID) {
      const user = new UserProfile(userID);
      user.avatarURL = newAvatarURL;
      
      LoginStore.shared().setSelfInfo(user).then(() => {
        this.avatarURL = newAvatarURL;
        this.updateDisplayTexts();
        Toast.show($r('app.string.update_profile_success'), ToastType.Success, this.getUIContext(), 2000);
      }).catch((error: Error) => {
        Toast.show($r('app.string.update_profile_failed'), ToastType.Error, this.getUIContext(), 3000);
      });
    }
  }
}

@CustomDialog
struct AvatarPickerDialog {
  controller?: CustomDialogController;
  title: string | Resource = $r('app.string.profile_select_avatar');
  urlList: string[] = [];
  onConfirm?: (selectedUrl: string, selectedIndex: number) => void;
  onCancel?: () => void;
  onClose?: () => void;

  build() {
    AvatarSelector({
      title: this.title,
      urlList: this.urlList,
      onConfirm: (selectedUrl: string, selectedIndex: number) => {
        if (this.onConfirm) {
          this.onConfirm(selectedUrl, selectedIndex);
        }
        if (this.onClose) {
          this.onClose();
        }
      },
      onBack: () => {
        if (this.onClose) {
          this.onClose();
        }
        if (this.onCancel) {
          this.onCancel();
        }
      }
    })
  }
}

@CustomDialog
struct TextEditDialog {
  title: Resource = $r('app.string.edit');
  currentText: string = '';
  placeholder: Resource = $r('app.string.please_input');
  helpText: Resource = $r('app.string.profile_edit_name_desc');
  onSave?: (text: string) => void;
  onCancel?: () => void;
  controller?: CustomDialogController;
  @State inputText: string = '';
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  aboutToAppear() {
    this.inputText = this.currentText;
  }

  build() {
    Column({ space: 20 }) {
      // Title
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)

      // Input
      TextInput({ text: this.inputText, placeholder: this.placeholder })
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor(this.themeState.colors.textColorPrimary)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.inputText = value;
        })

      // Help text
      Text(this.helpText)
        .fontSize(14)
        .fontColor(this.themeState.colors.textColorSecondary)
        .width('100%')
        .textAlign(TextAlign.Start)

      // Buttons
      Row({ space: 12 }) {
        Button($r('app.string.cancel'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorSecondary)
          .backgroundColor(this.themeState.colors.bgColorOperate)
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onCancel?.();
            this.controller?.close();
          })

        Button($r('app.string.confirm'))
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(this.themeState.colors.buttonColorPrimaryDefault)
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onSave?.(this.inputText);
            this.controller?.close();
          })
      }
      .width('100%')
    }
    .width(280)
    .padding(24)
    .backgroundColor(this.themeState.colors.bgColorDefault)
    .borderRadius(12)
  }
}

@CustomDialog
struct GenderSelectDialog {
  currentGender: Gender = Gender.UNKNOWN;
  onSelect?: (gender: Gender) => void;
  onCancel?: () => void;
  controller?: CustomDialogController;
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();

  build() {
    Column() {
      // Title
      Text($r('app.string.profile_edit_gender'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeState.colors.textColorPrimary)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 16, bottom: 16 })

      Column() {
        // Male option
        this.buildGenderOption($r('app.string.gender_male'), Gender.MALE)
        
        Divider().height(0.5).color(this.themeState.colors.strokeColorPrimary).width('100%')
        
        // Female option
        this.buildGenderOption($r('app.string.gender_female'), Gender.FEMALE)
        
        Divider().height(0.5).color(this.themeState.colors.strokeColorPrimary).width('100%')
        
      }
      .backgroundColor(this.themeState.colors.bgColorDefault)
      .borderRadius(12)

      // Cancel Button
      Button($r('app.string.cancel'))
        .width('100%')
        .height(56)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeState.colors.buttonColorPrimaryDefault)
        .backgroundColor(this.themeState.colors.bgColorOperate)
        .borderRadius(12)
        .margin({ top: 12, bottom: 38 })
        .onClick(() => {
          this.onCancel?.();
          this.controller?.close();
        })
    }
    .width('90%')
    .backgroundColor(Color.Transparent)
  }

  @Builder
  private buildGenderOption(title: Resource, gender: Gender) {
    Row() {
      Text(title)
        .fontSize(17)
        .fontColor(this.themeState.colors.textColorPrimary)
        .layoutWeight(1)

      if (this.currentGender === gender) {
        Image($r('app.media.ic_public_check'))
          .width(24)
          .height(24)
          .fillColor(this.themeState.colors.buttonColorPrimaryDefault)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.onSelect?.(gender);
      this.controller?.close();
    })
  }
}