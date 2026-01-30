import { ErrorInfo, ContactListState, ContactListStore, FriendApplicationInfo, } from '@tencentcloud/atomicxcore';
import {
  Avatar,
  AvatarContentType,
  AvatarShape,
  AvatarSize,
  TextUtils,
  ThemeState
} from '../../../basecomponent/Index';
import { ImmersiveMode, LevelMode } from '@ohos.promptAction';

@CustomDialog
struct FriendRequestInfoDialog {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller: CustomDialogController;
  @Prop application: FriendApplicationInfo;
  @Prop contactListStore: ContactListStore;
  onClose?: () => void;
  onProcessed?: () => void;
  @State private isProcessing: boolean = false;

  build() {
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
            .fontColor(this.themeState.colors.textColorLink)// Figma: #1C66E5
            .margin({ left: 8 })
        }
        .onClick(() => {
          this.handleClose();
        })


        Text($r('app.string.friend_request_info'))
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
        .color(this.themeState.colors.strokeColorSecondary) // Figma: #E0E0E0


      Row() {
        // Avatar
        Avatar({
          content: {
            type: AvatarContentType.Image,
            name: TextUtils.getAvatarLetter(this.application.title || this.application.applicationID || ''),
          },
          avatarSize: AvatarSize.L
        })
        // User info
        Column() {
          Text(this.application.title || this.application.applicationID || '')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorPrimary)// Figma: rgba(0, 0, 0, 0.9)
            .textAlign(TextAlign.Start)
            .width('100%')

          Text(`ID：${this.application.applicationID || ''}`)
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorSecondary)// Figma: rgba(0, 0, 0, 0.55)
            .textAlign(TextAlign.Start)
            .width('100%')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .layoutWeight(1)
        .margin({ left: 18 })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 10,
        bottom: 10
      })
      .alignItems(VerticalAlign.Center)


      if (this.application.addWording) {
        Column() {
          // Title
          Row() {
            Text($r('app.string.validation_message'))
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorSecondary) // Figma: rgba(0, 0, 0, 0.55)
            Blank().width(35);

            Text(this.application.addWording)
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorPrimary)// Figma: rgba(0, 0, 0, 0.9)
              .textAlign(TextAlign.Center)
          }
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 12,
          bottom: 12
        })
        .alignItems(HorizontalAlign.Start)
      }

      Row() {
        // Agree button
        Button($r('app.string.agree_button'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorButton)// Figma: #FFFFFF
          .backgroundColor(this.themeState.colors.textColorLink)// Figma: #147AFF
          .borderRadius(10)
          .width(160)
          .height(44)
          .enabled(!this.isProcessing)
          .onClick(() => this.handleFriendApplication(true))

        // Refuse button
        Button($r('app.string.refuse_button'))
          .fontSize(16)
          .fontColor(this.themeState.colors.textColorError)// Figma: #FF584C
          .backgroundColor(this.themeState.colors.bgColorInput)// Figma: rgba(249, 249, 249, 0.94)
          .borderRadius(10)
          .width(160)
          .height(44)
          .enabled(!this.isProcessing)
          .onClick(() => this.handleFriendApplication(false))
          .margin({ left: 20 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: 16,
        right: 16,
        top: 40,
        bottom: 34
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate) // Figma: #FFFFFF
  }

  private handleClose() {
    if (this.onClose) {
      this.onClose();
    }

    // this.controller.close();
  }

  private async handleFriendApplication(accept: boolean) {
    if (this.isProcessing) {
      return;
    }

    try {
      this.isProcessing = true;

      if (accept) {
        await this.contactListStore.acceptFriendApplication(this.application);
      } else {
        await this.contactListStore.refuseFriendApplication(this.application);
      }

      if (this.onProcessed) {
        this.onProcessed();
      }
      this.handleClose();
    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to process friend application:', error.errorMessage);
      if (this.onProcessed) {
        this.onProcessed();
      }
      this.handleClose();
    } finally {
      this.isProcessing = false;
    }
  }
}

@Component
export struct FriendApplicationListView {
  // Callback function
  onBack?: () => void;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  // Reuse external store - must be observable
  @ObjectLink contactListStore: ContactListStore;
  @State private contactListState: ContactListState = this.contactListStore.state;
  @State private isLoading: boolean = true;
  private friendRequestInfoDialogController: CustomDialogController | null = null;
  @State private dialogAnimationOffset: number = 100;

  aboutToAppear() {
    console.info('NewContactsPage aboutToAppear');
    this.contactListState = this.contactListStore.state;
    this.loadFriendApplications();
    this.contactListStore.clearFriendApplicationUnreadCount().then(() => {

    })
  }

  aboutToDisappear() {
    console.info('NewContactsPage aboutToDisappear');
  }

  onBackPress(): boolean | void {
    console.info('NewContactsPage onBackPress');
    this.handleBack();
    return true;
  }

  build() {
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
        .onClick(() => {
          this.handleBack();
        })


        Text($r('app.string.new_applications_multiple'))
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


      if (this.isLoading) {
        // Loading state
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text($r('app.string.loading_applications'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorSecondary)// Figma: #999999
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.contactListState.friendApplicationDataSource.totalCount() === 0) {

        Column() {
          Text($r('app.string.no_friend_applications_title'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)// Figma: #999999
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 })

          Text($r('app.string.no_friend_applications_desc'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorTertiary)// Figma: #CCCCCC
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 32, right: 32 })
      } else {

        List() {
          LazyForEach(this.contactListState.friendApplicationDataSource, (application: FriendApplicationInfo) => {
            ListItem() {
              Row() {
                Avatar({
                  content: {
                    type: AvatarContentType.Image,
                    url: application.avatarURL,
                    name: application.title || application.applicationID || '',
                  },
                  shape: AvatarShape.Round,
                  avatarSize: AvatarSize.L
                }).onClick(() => this.navigateToFriendRequestInfo(application))

                Row() {

                  Column() {
                    Text(application.title || application.applicationID || '')
                      .fontSize(14)
                      .fontWeight(FontWeight.Normal)
                      .fontColor(this.themeState.colors.textColorPrimary)// Figma: rgba(0, 0, 0, 0.9)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .textAlign(TextAlign.Start)

                    if (application.addWording) {
                      Text(application.addWording)
                        .fontSize(12)
                        .fontColor(this.themeState.colors.textColorSecondary)// Figma: rgba(0, 0, 0, 0.6)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 4 })
                        .width('100%')
                        .textAlign(TextAlign.Start)
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .justifyContent(FlexAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: 13, right: 10 })
                  .onClick(() => this.navigateToFriendRequestInfo(application))


                  Row() {
                    Button($r('app.string.agree_button'))
                      .fontSize(14)
                      .fontColor(this.themeState.colors.textColorButton)// Figma: #FFFFFF
                      .backgroundColor(this.themeState.colors.textColorLink)// Figma: #147AFF
                      .borderRadius(10)
                      .padding({
                        left: 16,
                        right: 16,
                        top: 5,
                        bottom: 5
                      })
                      .margin({ left: 8 })
                      .onClick(() => this.handleFriendApplication(application, true))

                    Button($r('app.string.refuse_button'))
                      .fontSize(14)
                      .fontColor(this.themeState.colors.textColorError)// Figma: #FF584C
                      .backgroundColor(this.themeState.colors.bgColorDefault)// Figma: #FFFFFF
                      .borderRadius(5)
                      .border({ width: 1, color: this.themeState.colors.strokeColorSecondary })// Figma: #DDDDDD
                      .padding({
                        left: 16,
                        right: 16,
                        top: 5,
                        bottom: 5
                      })
                      .margin({
                        left: 10
                      })
                      .onClick(() => this.handleFriendApplication(application, false))
                  }
                }
                .alignItems(VerticalAlign.Center)
                .layoutWeight(1)
                .padding({
                  left: 0,
                  right: 16,
                  top: 8,
                  bottom: 8
                })
              }
              .width('100%')
              .padding({
                left: 16,
                right: 0,
                top: 0,
                bottom: 0
              })
              .alignItems(VerticalAlign.Center)
            }
          }, (application: FriendApplicationInfo) => application.applicationID || '')
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorOperate) // Figma: #FFFFFF
        .divider({
          strokeWidth: 1,
          color: this.themeState.colors.strokeColorSecondary, // Figma: #F0F0F0
          startMargin: 87,
          endMargin: 0
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  // no helper needed; directly observe first-level unread count on state

  @Builder
  FriendRequestInfoDialogBuilder(application: FriendApplicationInfo): void {
    Column() {
      FriendRequestInfoDialog({
        application: application,
        contactListStore: this.contactListStore,
        onClose: () => {
          console.info('Friend request info dialog closed');

          if (this.friendRequestInfoDialogController) {
            const controller = this.friendRequestInfoDialogController;
            this.friendRequestInfoDialogController = null;
            controller.close();
          }
        },
        onProcessed: () => {
          console.info('Friend request processed, reloading list');

          // this.loadFriendApplications();
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

  private handleBack() {
    if (this.onBack) {

      this.onBack();
    } else {

      this.getUIContext().getRouter().back();
    }
  }

  private async loadFriendApplications() {
    try {
      this.isLoading = true;
      await this.contactListStore.fetchFriendApplicationList();
    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to load friend applications:', error.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  private async handleFriendApplication(application: FriendApplicationInfo, accept: boolean) {
    try {
      if (accept) {
        await this.contactListStore.acceptFriendApplication(application);
      } else {
        await this.contactListStore.refuseFriendApplication(application);
      }

      // await this.loadFriendApplications();
    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to process friend application:', error.errorMessage);
    }
  }

  private navigateToFriendRequestInfo(application: FriendApplicationInfo) {
    console.info('Show friend request info dialog');


    if (this.friendRequestInfoDialogController) {
      this.friendRequestInfoDialogController.close();
      this.friendRequestInfoDialogController = null;
    }


    this.dialogAnimationOffset = 100;


    this.friendRequestInfoDialogController = new CustomDialogController({
      builder: () => this.FriendRequestInfoDialogBuilder(application),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      customStyle: true,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
      maskColor: 'rgba(0, 0, 0, 0)',
      cancel: () => {
        this.friendRequestInfoDialogController = null;
      },
      levelMode: LevelMode.EMBEDDED,
      immersiveMode: ImmersiveMode.EXTEND,
      openAnimation: {
        duration: 300,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal,
        onFinish: () => {

        }
      },
      closeAnimation: {
        duration: 250,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal,
        onFinish: () => {

        }
      }
    });


    this.friendRequestInfoDialogController.open();
  }
}