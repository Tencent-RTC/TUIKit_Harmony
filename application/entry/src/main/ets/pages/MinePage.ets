import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { Constants } from '../common/Constants';
import { UserStore } from '../common/UserStore';

@Component
export struct MineDestination {
  navStack: NavPathStack = new NavPathStack();
  @StorageProp(Constants.KEY_USER_ID) userId: string = '';
  @StorageProp(Constants.KEY_NICKNAME) nickname: string = '';
  @StorageProp(Constants.KEY_AVATAR_URL) avatarUrl: string = Constants.DEFAULT_AVATAR_URL;
  @State isLogSheetVisible: boolean = false;
  @State logFileNames: string[] = [];
  @State selectedLogIndex: number = 0;
  private logFiles: LogFileInfo[] = [];

  build() {
    NavDestination() {
      Column() {
        Stack({ alignContent: Alignment.Top }) {
          Image($r('app.media.mine_bg'))
            .width('100%')
            .objectFit(ImageFit.Cover)
            .position({ x: 0, y: 0 })

          Column() {
            Row() {
              Image($r('app.media.mine_goback'))
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain)
                .onClick(() => {
                  this.navStack.pop();
                })

              Text($r('app.string.mine_title'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

              Row().width(24).height(24)
            }
            .width('100%')
            .height(44)
            .padding({ left: 20, right: 20 })
            .alignItems(VerticalAlign.Center)

            Image(this.avatarUrl)
              .width(72)
              .height(72)
              .borderRadius(36)
              .objectFit(ImageFit.Cover)
              .margin({ top: 16 })

            Text(this.nickname || this.userId)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#262B32')
              .margin({ top: 8 })
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: '80%' })

            Text(`ID:${this.userId}`)
              .fontSize(12)
              .fontColor('#626E84')
              .margin({ top: 2 })
          }
          .width('100%')
        }
        .width('100%')

        Column() {
          Column() {
            Row() {
              Image($r('app.media.mine_setting'))
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain)

              Text($r('app.string.mine_settings'))
                .fontSize(14)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium)
                .margin({ left: 20 })

              Blank()

              Image($r('app.media.mine_detail'))
                .width(18)
                .height(18)
                .objectFit(ImageFit.Contain)
            }
            .width('100%')
            .height(58)
            .padding({ left: 20, right: 20 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.navStack.pushPath({ name: 'Settings' });
            })

            Row() {
              Image($r('app.media.mine_log'))
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain)

              Text($r('app.string.mine_log'))
                .fontSize(14)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium)
                .margin({ left: 20 })

              Blank()

              Image($r('app.media.mine_detail'))
                .width(18)
                .height(18)
                .objectFit(ImageFit.Contain)
            }
            .width('100%')
            .height(58)
            .padding({ left: 20, right: 20 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.scanLogFiles();
              this.isLogSheetVisible = true;
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(10)
          .padding({ top: 8, bottom: 8 })
          .margin({ top: 20 })

          Button($r('app.string.mine_logout'))
            .width('100%')
            .height(52)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F33A50')
            .backgroundColor(Color.White)
            .borderRadius(10)
            .margin({ top: 12 })
            .onClick(() => {
              AlertDialog.show({
                message: $r('app.string.mine_logout_confirm'),
                primaryButton: {
                  value: $r('app.string.cancel'),
                  action: () => {
                  }
                },
                secondaryButton: {
                  value: $r('app.string.confirm'),
                  fontColor: '#F33A50',
                  action: async () => {
                    await UserStore.instance.logout();
                    router.clear();
                    router.replaceUrl({ url: 'pages/Index' });
                  }
                }
              });
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EBEDF5')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .bindSheet($$this.isLogSheetVisible, this.logSheetBuilder(), {
        height: SheetSize.MEDIUM,
        dragBar: false,
        showClose: false
      })
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }

  @Builder
  logSheetBuilder() {
    Column() {
      Row() {
        Text($r('app.string.cancel'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0A59F7')
          .onClick(() => {
            this.isLogSheetVisible = false;
          })

        Text($r('app.string.log_share_title'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text($r('app.string.log_share_button'))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0A59F7')
          .onClick(() => {
            this.shareLogFile();
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.logFileNames.length > 0) {
        TextPicker({ range: this.logFileNames, selected: this.selectedLogIndex })
          .canLoop(false)
          .onChange((value: string | string[], index: number | number[]) => {
            if (typeof index === 'number') {
              this.selectedLogIndex = index;
            }
          })
          .width('100%')
          .layoutWeight(1)
      } else {
        Column() {
          Text($r('app.string.log_empty'))
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding({ bottom: 16 })
  }

  private scanLogFiles(): void {
    const filesDir = getContext(this).getApplicationContext().filesDir;
    const liteAVLogDir = `${filesDir}/liteav/log`;
    const logFileList: LogFileInfo[] = [];

    this.scanDir(logFileList, liteAVLogDir, ['.xlog', '.clog']);

    const cacheDir = getContext(this).cacheDir;
    this.scanDir(logFileList, cacheDir, ['.xlog']);

    logFileList.sort((a: LogFileInfo, b: LogFileInfo) => b.modifiedTime - a.modifiedTime);

    this.logFiles = logFileList;
    this.logFileNames = logFileList.map((f: LogFileInfo) => f.fileName);
    this.selectedLogIndex = 0;
  }

  private scanDir(logFileList: LogFileInfo[], dirPath: string, extensions: string[]): void {
    try {
      if (!fileIo.accessSync(dirPath)) {
        return;
      }
      const fileNames: string[] = fileIo.listFileSync(dirPath);
      for (const name of fileNames) {
        for (const ext of extensions) {
          if (name.endsWith(ext)) {
            const fullPath = `${dirPath}/${name}`;
            try {
              const stat = fileIo.statSync(fullPath);
              logFileList.push({ fileName: name, filePath: fullPath, modifiedTime: stat.mtime });
            } catch (e) {
              logFileList.push({ fileName: name, filePath: fullPath, modifiedTime: 0 });
            }
            break;
          }
        }
      }
    } catch (e) {
    }
  }

  private shareLogFile(): void {
    if (this.logFiles.length === 0 || this.selectedLogIndex >= this.logFiles.length) {
      promptAction.showToast({ message: 'No log file found', duration: 2000 });
      return;
    }
    const logFile: LogFileInfo = this.logFiles[this.selectedLogIndex];
    const uri: string = fileUri.getUriFromPath(logFile.filePath);
    const shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.FILE,
      uri: uri
    });
    const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    const uiContext: UIContext = this.getUIContext();
    const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    });
    this.isLogSheetVisible = false;
  }
}

interface LogFileInfo {
  fileName: string;
  filePath: string;
  modifiedTime: number;
}
