import { Constants } from '../common/Constants';
import { UserStore } from '../common/UserStore';
import { NicknameEditDialog } from '../components/NicknameEditDialog';

@Component
export struct SettingsDestination {
  navStack: NavPathStack = new NavPathStack();
  @StorageProp(Constants.KEY_AVATAR_URL) avatarUrl: string = Constants.DEFAULT_AVATAR_URL;
  @StorageProp(Constants.KEY_NICKNAME) nickname: string = '';
  dialogController: CustomDialogController | null = null;

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.mine_goback'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.navStack.pop();
            })

          Text($r('app.string.settings_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262B32')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Row().width(24).height(24)
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Column() {
          Row() {
            Text($r('app.string.settings_avatar'))
              .fontSize(16)
              .fontColor('#262B32')
              .margin({ left: 16 })

            Blank()

            Image(this.avatarUrl)
              .width(36)
              .height(36)
              .borderRadius(18)
              .objectFit(ImageFit.Cover)
              .margin({ right: 8 })

            Image($r('app.media.mine_detail'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .margin({ right: 16 })
          }
          .width('100%')
          .height(56)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.navStack.pushPath({ name: 'AvatarSelector' });
          })

          Divider().color('#EEEEEE').height(0.5).margin({ left: 16 })

          Row() {
            Text($r('app.string.settings_nickname'))
              .fontSize(16)
              .fontColor('#262B32')
              .margin({ left: 16 })

            Blank()

            Text(this.nickname)
              .fontSize(14)
              .fontColor('#626E84')
              .margin({ right: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 150 })

            Image($r('app.media.mine_detail'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .margin({ right: 16 })
          }
          .width('100%')
          .height(56)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.dialogController = new CustomDialogController({
              builder: NicknameEditDialog({
                currentNickname: this.nickname,
                onConfirm: async (newName: string) => {
                  await UserStore.instance.setSelfInfo(newName);
                }
              }),
              alignment: DialogAlignment.Bottom,
              customStyle: true,
            });
            this.dialogController.open();
          })

          Divider().color('#EEEEEE').height(0.5).margin({ left: 16 })

          Row() {
            Text($r('app.string.settings_language'))
              .fontSize(16)
              .fontColor('#262B32')
              .margin({ left: 16 })

            Blank()

            Image($r('app.media.mine_detail'))
              .width(16)
              .height(16)
              .objectFit(ImageFit.Contain)
              .margin({ right: 16 })
          }
          .width('100%')
          .height(56)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.navStack.pushPath({ name: 'LanguageSelect' });
          })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(10)
        .margin({ top: 12, left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EBEDF5')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}
