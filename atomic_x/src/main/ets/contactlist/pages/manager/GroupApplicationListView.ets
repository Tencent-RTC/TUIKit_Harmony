import {
  ErrorInfo,
  ContactListState,
  ContactListStore,
  GroupApplicationHandledResult,
  GroupApplicationHandledStatus,
  GroupApplicationInfo
} from '@tencentcloud/atomicxcore';
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
struct GroupRequestInfoDialog {
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  controller: CustomDialogController;
  @ObjectLink application: GroupApplicationInfo;
  @ObjectLink contactListStore: ContactListStore;
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


        Text($r('app.string.group_request_info'))
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
            url: this.application.fromUserAvatarURL,
            name: TextUtils.getAvatarLetter(this.application.fromUserNickname || this.application.fromUser || ''),
          },
          avatarSize: AvatarSize.L
        })

        // User info
        Column() {
          Text(this.application.fromUserNickname || this.application.fromUser || '')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeState.colors.textColorPrimary)// Figma: rgba(0, 0, 0, 0.9)
            .textAlign(TextAlign.Start)
            .width('100%')

          Text($r('app.string.user_id_label', this.application.fromUser || ''))
            .fontSize(12)
            .fontColor(this.themeState.colors.textColorSecondary)// Figma: rgba(0, 0, 0, 0.55)
            .textAlign(TextAlign.Start)
            .width('100%')
            .margin({ top: 4 })

          Text($r('app.string.group_id_label', this.application.groupID || ''))
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


      if (this.application.requestMsg) {
        Column() {
          // Title
          Row() {
            Text($r('app.string.request_message'))
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorSecondary) // Figma: rgba(0, 0, 0, 0.55)
            Blank().width(35);

            Text(this.application.requestMsg)
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


      if (this.application.handledStatus == GroupApplicationHandledStatus.UNHANDLED) {
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
            .onClick(() => this.handleGroupApplication(true))

          // Refuse button
          Button($r('app.string.refuse_button'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorError)
            .backgroundColor(this.themeState.colors.bgColorInput)
            .borderRadius(10)
            .width(160)
            .height(44)
            .enabled(!this.isProcessing)
            .onClick(() => this.handleGroupApplication(false))
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
      } else {
        Column() {
          if (this.application.handledResult == GroupApplicationHandledResult.REFUSED) {
            Text($r('app.string.group_application_refused'))
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorError)
              .fontWeight(FontWeight.Medium)
          } else {
            Text($r('app.string.group_application_accepted'))
              .fontSize(16)
              .fontColor(this.themeState.colors.textColorSuccess)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({
          left: 16,
          right: 16,
          top: 40,
          bottom: 34
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeState.colors.bgColorOperate)
  }

  private handleClose() {
    if (this.onClose) {
      this.onClose();
    }

    // this.controller.close();
  }

  private async handleGroupApplication(accept: boolean) {
    if (this.isProcessing) {
      return;
    }

    try {
      this.isProcessing = true;

      if (accept) {
        await this.contactListStore.acceptGroupApplication(this.application);
        this.application.handledStatus = GroupApplicationHandledStatus.BY_MYSELF;
        this.application.handledResult = GroupApplicationHandledResult.AGREED;
      } else {
        await this.contactListStore.refuseGroupApplication(this.application);
        this.application.handledStatus = GroupApplicationHandledStatus.BY_MYSELF;
        this.application.handledResult = GroupApplicationHandledResult.REFUSED;
      }

      if (this.onProcessed) {
        this.onProcessed();
      }
      this.handleClose();
    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to process group application:', error.errorMessage);
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
export struct GroupApplicationListView {
  // Callback function
  onBack?: () => void;
  // Theme management
  @StorageLink('ThemeState') themeState: ThemeState = ThemeState.getInstance();
  @ObjectLink contactListStore: ContactListStore;
  @State private contactListState: ContactListState = this.contactListStore.state;
  @State private isLoading: boolean = true;
  private groupRequestInfoDialogController: CustomDialogController | null = null;
  @State private dialogAnimationOffset: number = 100;

  aboutToAppear() {
    console.info('NewGroupsPage aboutToAppear');
    this.contactListState = this.contactListStore.state;
    this.loadGroupApplications();
    this.contactListStore.clearGroupApplicationUnreadCount().then(() => {

    })
  }

  aboutToDisappear() {
    console.info('NewGroupsPage aboutToDisappear');
  }

  onBackPress(): boolean | void {
    console.info('NewGroupsPage onBackPress');
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


        Text($r('app.string.new_group_request_title'))
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
          Text($r('app.string.loading_group_applications'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorSecondary)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.contactListState.groupApplicationDataSource.totalCount() === 0) {

        Column() {
          Text($r('app.string.no_group_applications_title'))
            .fontSize(16)
            .fontColor(this.themeState.colors.textColorSecondary)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 })

          Text($r('app.string.no_group_applications_desc'))
            .fontSize(14)
            .fontColor(this.themeState.colors.textColorTertiary)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ left: 32, right: 32 })
      } else {

        List() {
          LazyForEach(this.contactListState.groupApplicationDataSource,
            (application: GroupApplicationInfo) => {
              ListItem() {
                Row() {
                  Avatar({
                    content: {
                      type: AvatarContentType.Image,
                      url: application.fromUserAvatarURL,
                      name: application.fromUserNickname || application.fromUser || '',
                    },
                    avatarSize: AvatarSize.M,
                    shape: AvatarShape.Round,
                  }).onClick(() => this.navigateToGroupRequestInfo(application))

                  Row() {

                    Column() {
                      Text(application.fromUserNickname || application.fromUser || '')
                        .fontSize(14)
                        .fontWeight(FontWeight.Normal)
                        .fontColor(this.themeState.colors.textColorPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                        .textAlign(TextAlign.Start)

                      if (application.requestMsg) {
                        Text(application.requestMsg)
                          .fontSize(12)
                          .fontColor(this.themeState.colors.textColorSecondary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ top: 4 })
                          .width('100%')
                          .textAlign(TextAlign.Start)
                      } else {
                        Text($r('app.string.want_to_join_group', application.groupID))
                          .fontSize(12)
                          .fontColor(this.themeState.colors.textColorSecondary)
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
                    .onClick(() =>{
                      this.navigateToGroupRequestInfo(application)
                    } )

                    if (application.handledStatus == GroupApplicationHandledStatus.UNHANDLED) {
                      Row() {
                        Button($r('app.string.agree_button'))
                          .fontSize(14)
                          .fontColor(this.themeState.colors.textColorButton)
                          .backgroundColor(this.themeState.colors.textColorLink)
                          .borderRadius(10)
                          .padding({
                            left: 16,
                            right: 16,
                            top: 5,
                            bottom: 5
                          })
                          .margin({ left: 8 })
                          .onClick(() => this.handleGroupApplication(application, true))

                        Button($r('app.string.refuse_button'))
                          .fontSize(14)
                          .fontColor(this.themeState.colors.textColorError)
                          .backgroundColor(this.themeState.colors.bgColorDefault)
                          .borderRadius(5)
                          .border({ width: 1, color: this.themeState.colors.strokeColorSecondary })
                          .padding({
                            left: 16,
                            right: 16,
                            top: 5,
                            bottom: 5
                          })
                          .margin({
                            left: 10
                          })
                          .onClick(() => this.handleGroupApplication(application, false))
                      }
                    } else {
                      if (application.handledResult == GroupApplicationHandledResult.REFUSED) {
                        Text($r('app.string.group_application_refused'))
                      } else {
                        Text($r('app.string.group_application_accepted'))
                      }
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
            }, (application: GroupApplicationInfo) => application.getKey() || '')
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.themeState.colors.bgColorOperate) 
        .divider({
          strokeWidth: 1,
          color: this.themeState.colors.strokeColorSecondary, 
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

  @Builder
  GroupRequestInfoDialogBuilder(application: GroupApplicationInfo): void {
    Column() {
      GroupRequestInfoDialog({
        application: application,
        contactListStore: this.contactListStore,
        onClose: () => {
          console.info('Group request info dialog closed');

          if (this.groupRequestInfoDialogController) {
            const controller = this.groupRequestInfoDialogController;
            this.groupRequestInfoDialogController = null;
            controller.close();
          }
        },
        onProcessed: () => {
          console.info('Group request processed, reloading list');

          // this.loadGroupApplications();
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

  // no helper needed; directly observe first-level unread count on state

  private handleBack() {
    if (this.onBack) {

      this.onBack();
    } else {

      this.getUIContext().getRouter().back();
    }
  }

  private async loadGroupApplications() {
    try {
      this.isLoading = true;
      await this.contactListStore.fetchGroupApplicationList();
    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to load group applications:', error.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  private async handleGroupApplication(application: GroupApplicationInfo, accept: boolean) {
    try {
      if (accept) {
        await this.contactListStore.acceptGroupApplication(application);
      } else {
        await this.contactListStore.refuseGroupApplication(application);
      }

      // await this.loadGroupApplications();
    } catch (error) {
      const errorResult = error as ErrorInfo;
      console.error('Failed to process group application:', error.errorMessage);
    }
  }

  private navigateToGroupRequestInfo(application: GroupApplicationInfo) {
    console.info('Show group request info dialog');


    if (this.groupRequestInfoDialogController) {
      this.groupRequestInfoDialogController.close();
      this.groupRequestInfoDialogController = null;
    }


    this.dialogAnimationOffset = 100;


    this.groupRequestInfoDialogController = new CustomDialogController({
      builder: () => this.GroupRequestInfoDialogBuilder(application),
      autoCancel: false,
      alignment: DialogAlignment.Center,
      customStyle: true,
      keyboardAvoidMode: KeyboardAvoidMode.NONE,
      maskColor: 'rgba(0, 0, 0, 0)',
      cancel: () => {
        this.groupRequestInfoDialogController = null;
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


    this.groupRequestInfoDialogController.open();
  }
} 