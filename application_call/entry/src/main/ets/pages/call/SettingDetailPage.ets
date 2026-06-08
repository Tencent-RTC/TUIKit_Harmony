// SettingDetailPage.ets — aligned with iOS SettingDetailViewController.swift.
//
// Three modes (param.type):
//   - ringInfo:        edit ringtone file path; on save → TUICallKit.setCallingBell(path)
//   - extendInfo:      edit free-form user data; on save → SettingsConfig.userData
//   - offlinePushInfo: edit JSON for offline push info; on save → SettingsConfig.offlineData (local only)

import { hilog } from '@kit.PerformanceAnalysisKit';
import { inputMethod } from '@kit.IMEKit';
import { TUICallKit } from '@tencentcloud/tuicallkit';
import { SettingDetailParam, SettingDetailType } from '../../common/CallTestRouter';
import { SettingsConfig } from '../../common/SettingsConfig';
import { Toast } from '../../common/Toast';

const DOMAIN = 0xCA11;
const TAG = 'CallTest';

@Component
export struct SettingDetailDestination {
  navStack: NavPathStack = new NavPathStack();
  param: SettingDetailParam = new SettingDetailParam(SettingDetailType.ringInfo);

  @State text: string = '';

  aboutToAppear(): void {
    // iOS does NOT pre-fill the ringInfo textView (it shows the SetRingTip placeholder
    // until the user types). For extendInfo / offlinePushInfo, iOS uses an empty
    // textView too, but those values may have been previously edited via the
    // settings page; we only carry over previously-edited values for the
    // non-ring cases to keep the user's input.
    if (this.param.type === SettingDetailType.ringInfo) {
      this.text = '';
    } else if (this.param.type === SettingDetailType.extendInfo) {
      this.text = SettingsConfig.shared().userData;
    } else {
      this.text = SettingsConfig.shared().offlineData;
    }
  }

  private getTitle(): ResourceStr {
    if (this.param.type === SettingDetailType.ringInfo) {
      return $r('app.string.SetRing');
    }
    if (this.param.type === SettingDetailType.extendInfo) {
      return $r('app.string.SetExtend');
    }
    return $r('app.string.SetOffLineInfo');
  }

  private getHint(): ResourceStr {
    if (this.param.type === SettingDetailType.ringInfo) {
      return $r('app.string.SetRingTip');
    }
    if (this.param.type === SettingDetailType.extendInfo) {
      return $r('app.string.SetExtendTip');
    }
    return $r('app.string.SetOffLineInfoTip');
  }

  build() {
    NavDestination() {
      Column() {
        // NavBar
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor('#000000')
            .onClick(() => {
              this.navStack.pop();
            });
          Text(this.getTitle())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#000000')
            .layoutWeight(1)
            .textAlign(TextAlign.Center);
          Text($r('app.string.Yes'))
            .fontSize(16)
            .fontColor('#006EFF')
            .onClick(() => {
              this.handleSave();
            });
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center);

        Divider().color('#EEEEEE').strokeWidth(1);

        TextArea({ placeholder: this.getHint(), text: this.text })
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#BBBBBB')
          .placeholderFont({ size: 16 })
          .backgroundColor(Color.Transparent)
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .width('100%')
          .layoutWeight(1)
          .onChange((v: string) => {
            this.text = v;
          });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .onClick(() => {
        inputMethod.getController().stopInputSession();
      });
    }
    .hideTitleBar(true);
  }

  private handleSave(): void {
    const t = this.text;
    if (t.length === 0) {
      return;
    }
    if (this.param.type === SettingDetailType.ringInfo) {
      try {
        TUICallKit.createInstance(getContext(this)).setCallingBell(t);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'setCallingBell failed: %{public}s', JSON.stringify(e));
      }
      SettingsConfig.shared().ringUrl = t;
      Toast.show(`Set Successful: ${t}`);
    } else if (this.param.type === SettingDetailType.extendInfo) {
      SettingsConfig.shared().userData = t;
      Toast.show(`Set Successful: ${t}`);
    } else {
      SettingsConfig.shared().offlineData = t;
      Toast.show(`Set Successful: ${t}`);
    }
    this.navStack.pop();
  }
}
