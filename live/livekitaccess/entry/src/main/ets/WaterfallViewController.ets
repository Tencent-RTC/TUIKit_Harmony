import { bundleManager } from '@kit.AbilityKit'
import { LiveInfo, LoginStore } from '@tencentcloud/atomicxcore'
import { LiveToast } from 'tuilivekit'
import { LiveSelectListView } from './livelist/LiveSelectListView'
import { LogShareViewController } from './logshare/LogShareViewController'

function localized(name: string, ...args: (string | number)[]): string {
  return getContext().resourceManager.getStringByNameSync(name, ...args)
}

@Component
export struct WaterfallViewController {
  @Prop reloadToken: number = 0
  onPlay?: (liveID: string) => void
  onPush?: (liveID: string) => void
  @StorageProp('tuilivekit.safeArea.top') safeTop: number = 0
  @StorageProp('tuilivekit.safeArea.bottom') safeBottom: number = 0
  @State private isLogSharePresented: boolean = false

  private showVersion(): void {
    const version = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName
    this.getUIContext().showAlertDialog({
      message: localized('livekit_access_version', version),
      confirm: { value: localized('livekit_access_ok'), action: () => {
      } },
    })
  }

  private select(liveInfo: LiveInfo): void {
    if (liveInfo.liveID.length === 0) {
      return
    }
    const loginUserID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (loginUserID.length > 0 && liveInfo.liveOwner.userID === loginUserID) {
      LiveToast.show(localized('livekit_access_click_own_live_hint'))
      return
    }
    this.onPlay?.(liveInfo.liveID)
  }

  private createLive(): void {
    const userID = LoginStore.shared().state.loginUserInfo?.userID ?? ''
    if (userID.length === 0) {
      this.getUIContext().showAlertDialog({
        message: localized('livekit_access_login_user_missing'),
        confirm: { value: localized('livekit_access_ok'), action: () => {
        } },
      })
      return
    }
    this.onPush?.(`live_${userID}`)
  }

  @Builder
  logShareSheet() {
    LogShareViewController({ onClose: () => this.isLogSharePresented = false })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Stack() {
          Text($r('app.string.livekit_access_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .height(22)
            .constraintSize({ minWidth: 120 })
            .gesture(LongPressGesture({ duration: 2000 }).onAction(() => this.isLogSharePresented = true))
          Image($r('app.media.app_ic_version'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .position({ right: 16, top: -1 })
            .onClick(() => this.showVersion())
        }
        .width('100%')
        .height(37)
        .align(Alignment.Top)
        LiveSelectListView({ reloadToken: this.reloadToken, onSelect: (liveInfo: LiveInfo) => this.select(liveInfo) })
          .layoutWeight(1)
          .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.safeTop })
      Button({ type: ButtonType.Capsule }) {
        Row({ space: 8 }) {
          Image($r('app.media.app_ic_add')).width(20).height(20).fillColor(Color.White)
          Text($r('app.string.livekit_access_start_live')).fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
        }
      }
      .height(56)
      .padding({ left: 28, right: 28 })
      .backgroundColor('rgba(51, 112, 255, 1)')
      .margin({ bottom: this.safeBottom + 24 })
      .onClick(() => this.createLive())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .bindSheet($$this.isLogSharePresented, this.logShareSheet(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      dragBar: true,
      showClose: false,
    })
  }
}
