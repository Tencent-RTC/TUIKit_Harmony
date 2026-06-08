import { Constants } from '../common/Constants';
import { UserStore } from '../common/UserStore';

@Component
export struct AvatarSelectorDestination {
  navStack: NavPathStack = new NavPathStack();
  @StorageProp(Constants.KEY_AVATAR_URL) currentAvatarUrl: string = Constants.DEFAULT_AVATAR_URL;
  @State selectedIndex: number = 0;
  @State isSaving: boolean = false;
  private avatarUrls: string[] = [];

  aboutToAppear(): void {
    for (let i = 1; i <= 20; i++) {
      this.avatarUrls.push(`https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_${i}.png`);
    }
    const idx = this.avatarUrls.indexOf(this.currentAvatarUrl);
    if (idx >= 0) {
      this.selectedIndex = idx;
    }
  }

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

          Text($r('app.string.avatar_selector_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#262B32')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text($r('app.string.avatar_selector_save'))
            .fontSize(16)
            .fontColor('#006EFF')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.handleSave();
            })
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Grid() {
          ForEach(this.avatarUrls, (url: string, index: number) => {
            GridItem() {
              Stack({ alignContent: Alignment.TopEnd }) {
                Image(url)
                  .width('100%')
                  .aspectRatio(1)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                  .border({
                    width: this.selectedIndex === index ? 2 : 0,
                    color: '#006EFF'
                  })

                if (this.selectedIndex === index) {
                  Image($r('app.media.icon_selected'))
                    .width(20)
                    .height(20)
                    .margin({ top: 4, right: 4 })
                }
              }
              .width('100%')
            }
            .onClick(() => {
              this.selectedIndex = index;
            })
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .padding({ left: 16, right: 16, top: 16 })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }

  async handleSave(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await UserStore.instance.setSelfInfo(undefined, this.avatarUrls[this.selectedIndex]);
      this.navStack.pop();
    } catch (err) {
      console.error(`[AvatarSelector] Save error: ${JSON.stringify(err)}`);
    } finally {
      this.isSaving = false;
    }
  }
}
