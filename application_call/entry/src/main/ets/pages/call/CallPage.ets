// CallPage.ets — aligned with iOS CallViewController.swift.
//
// Layout (top → bottom):
//   - NavBar back button
//   - line1 divider
//   - UserID row (UserID label + TextField for comma-separated user IDs)
//   - MediaType row (Audio / Video RadioButton)
//   - line2 divider
//   - OptionalParameters link (toggles GroupId row visibility)
//   - GroupId row (visible when expanded)
//   - CallSettings link
//   - JoinGroupCall link
//   - Call PrimaryButton at bottom

import { hilog } from '@kit.PerformanceAnalysisKit';
import { inputMethod } from '@kit.IMEKit';
import { TUICallKit } from '@tencentcloud/tuicallkit';
import { CallMediaType, CallParams } from '@tencentcloud/atomicxcore';
import { Toast } from '../../common/Toast';
import { CallTestRouter } from '../../common/CallTestRouter';
import { SettingsConfig } from '../../common/SettingsConfig';
import { RadioButton } from '../../components/RadioButton';
import { PrimaryButton } from '../../components/PrimaryButton';

const DOMAIN = 0xCA11;
const TAG = 'CallTest';

@Component
export struct CallDestination {
  navStack: NavPathStack = new NavPathStack();
  @State callType: CallMediaType = CallMediaType.audio;
  @State userIds: string = '';
  @State groupId: string = '';
  @State optionsExpanded: boolean = false;

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
          Text($r('app.string.Title_Call'))
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#000000')
            .layoutWeight(1)
            .textAlign(TextAlign.Center);
          Row().width(24).height(24);
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center);

        // line1
        Divider().color('#EEEEEE').strokeWidth(10);

        // UserID row
        Row() {
          Text($r('app.string.UserID'))
            .fontSize(16)
            .fontColor('#000000')
            .width(80);
          TextInput({ placeholder: $r('app.string.InputUserIds'), text: this.userIds })
            .layoutWeight(1)
            .fontSize(16)
            .fontColor('#333333')
            .placeholderColor('#BBBBBB')
            .placeholderFont({ size: 16 })
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.End)
            .onChange((v: string) => {
              this.userIds = v;
            });
        }
        .width('100%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center);

        // MediaType row
        Row() {
          Text($r('app.string.MediaType'))
            .fontSize(16)
            .fontColor('#000000');

          Row({ space: 40 }) {
            RadioButton({
              title: $r('app.string.Video_Call'),
              selected: this.callType === CallMediaType.video,
              onTap: () => {
                this.callType = CallMediaType.video;
              },
            });
            RadioButton({
              title: $r('app.string.Audio_Call'),
              selected: this.callType === CallMediaType.audio,
              onTap: () => {
                this.callType = CallMediaType.audio;
              },
            });
          }
          .margin({ left: 40 });

          Blank();
        }
        .width('100%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center);

        // line2
        Divider().color('#EEEEEE').strokeWidth(10);

        // Optional Parameters link
        Row() {
          Text(this.optionsExpanded
            ? `${getContext(this).resourceManager.getStringSync($r('app.string.OptionalParameters').id)}  v`
            : `${getContext(this).resourceManager.getStringSync($r('app.string.OptionalParameters').id)}  >`)
            .fontSize(16)
            .fontColor('#006EFF');
        }
        .width('100%')
        .height(40)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.optionsExpanded = !this.optionsExpanded;
        });

        // GroupId row (collapsible)
        if (this.optionsExpanded) {
          Row() {
            Text($r('app.string.GroupId'))
              .fontSize(16)
              .fontColor('#000000')
              .width(80);
            TextInput({ placeholder: $r('app.string.InputGroupId'), text: this.groupId })
              .layoutWeight(1)
              .fontSize(16)
              .fontColor('#333333')
              .placeholderColor('#BBBBBB')
              .placeholderFont({ size: 16 })
              .backgroundColor(Color.Transparent)
              .textAlign(TextAlign.End)
              .onChange((v: string) => {
                this.groupId = v;
              });
          }
          .width('100%')
          .height(50)
          .padding({ left: 20, right: 20 })
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Center);
        }

        // CallSettings link
        Row() {
          Text(`${getContext(this).resourceManager.getStringSync($r('app.string.CallSettings').id)}  >`)
            .fontSize(16)
            .fontColor('#006EFF');
        }
        .width('100%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 80 })
        .onClick(() => {
          this.navStack.pushPath({ name: CallTestRouter.SETTINGS });
        });

        // NOTE: iOS defines `joinInGroupLabel` but never adds it to its view
        // hierarchy, so JoinGroupCall is not visible on iOS UI either.
        // The route is still reachable programmatically via CallTestRouter.JOIN_GROUP.

        Blank();

        // Call button
        Column() {
          PrimaryButton({
            title: $r('app.string.App_Call'),
            onTap: () => {
              this.handleCall();
            },
          });
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 60 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        inputMethod.getController().stopInputSession();
      });
    }
    .hideTitleBar(true);
  }

  private async handleCall(): Promise<void> {
    const trimmed = this.userIds.trim();
    if (trimmed.length === 0) {
      return;
    }
    const userIdList = trimmed.split(',').map((s) => s.trim()).filter((s) => s.length > 0);
    if (userIdList.length === 0) {
      return;
    }

    const cfg = SettingsConfig.shared();
    const params = new CallParams();
    params.timeout = cfg.timeout;
    params.userData = cfg.userData;
    const gid = this.groupId.trim();
    if (gid.length > 0) {
      params.chatGroupId = gid;
    }

    try {
      await TUICallKit.createInstance(getContext(this))
        .calls(userIdList, this.callType, params);
      hilog.info(DOMAIN, TAG, '[Call] calls() ok, users=%{public}s', JSON.stringify(userIdList));
    } catch (err) {
      hilog.error(DOMAIN, TAG, '[Call] calls() failed: %{public}s', JSON.stringify(err));
      Toast.show(`${getContext(this).resourceManager.getStringSync($r('app.string.CallFailed').id)}: ${JSON.stringify(err)}`);
    }
  }
}
