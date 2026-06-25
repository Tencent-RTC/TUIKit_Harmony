import { hilog } from '@kit.PerformanceAnalysisKit';
import { inputMethod } from '@kit.IMEKit';
import { TUICallKit } from '@tencentcloud/tuicallkit';
import { CallTestRouter, SettingDetailParam, SettingDetailType } from '../../common/CallTestRouter';
import { SettingsConfig } from '../../common/SettingsConfig';
import { SectionHeader } from '../../components/SectionHeader';
import { SettingsSwitchRow } from '../../components/SettingsSwitchRow';
import { DropMenuRow } from '../../components/DropMenuRow';
import { SegmentRow } from '../../components/SegmentRow';

const DOMAIN = 0xCA11;
const TAG = 'CallTest';

@Component
export struct CallSettingsDestination {
  navStack: NavPathStack = new NavPathStack();

  @State ringUrl: string = SettingsConfig.shared().ringUrl;
  @State mute: boolean = SettingsConfig.shared().mute;
  @State floatWindow: boolean = SettingsConfig.shared().floatWindow;
  @State enableVirtualBackground: boolean = SettingsConfig.shared().enableVirtualBackground;
  @State enableIncomingBanner: boolean = SettingsConfig.shared().enableIncomingBanner;
  @State enableAITranscriber: boolean = SettingsConfig.shared().enableAITranscriber;

  @State strRoomId: string = SettingsConfig.shared().strRoomId;
  @State intRoomId: string = String(SettingsConfig.shared().intRoomId);
  @State timeoutSec: string = String(SettingsConfig.shared().timeout);
  @State userData: string = SettingsConfig.shared().userData;

  @State resolutionIdx: number = SettingsConfig.shared().resolution;
  @State resolutionModeIdx: number = SettingsConfig.shared().resolutionMode;
  @State fillModeIdx: number = SettingsConfig.shared().fillMode;
  @State rotationIdx: number = SettingsConfig.shared().rotation;

  @State screenOrientationIdx: number = SettingsConfig.shared().screenOrientation;
  private callKit: TUICallKit | null = null;

  aboutToAppear(): void {
    this.callKit = TUICallKit.createInstance(getContext(this));
    this.ringUrl = SettingsConfig.shared().ringUrl;
    this.userData = SettingsConfig.shared().userData;
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
          Text($r('app.string.CallSettings'))
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

        Scroll() {
          Column() {
            // ---------------- Basic Setting ----------------
            SectionHeader({ title: $r('app.string.BasicSetting') });

            this.RingRow();

            SettingsSwitchRow({
              label: $r('app.string.MuteMode'),
              isOn: this.mute,
              onChange: (v: boolean) => {
                this.mute = v;
                SettingsConfig.shared().mute = v;
                try {
                  this.callKit?.enableMuteMode(v);
                } catch (e) {
                  hilog.warn(DOMAIN, TAG, 'enableMuteMode failed: %{public}s', JSON.stringify(e));
                }
              },
            });

            SettingsSwitchRow({
              label: $r('app.string.EnableFloating'),
              isOn: this.floatWindow,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onChange: (_v: boolean) => {
              },
            });

            SettingsSwitchRow({
              label: $r('app.string.EnableVirtualBackground'),
              isOn: this.enableVirtualBackground,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onChange: (_v: boolean) => {
              },
            });

            SettingsSwitchRow({
              label: $r('app.string.EnableIncomingBanner'),
              isOn: this.enableIncomingBanner,
              onChange: (v: boolean) => {
                this.enableIncomingBanner = v;
                SettingsConfig.shared().enableIncomingBanner = v;
                try {
                  this.callKit?.enableIncomingBanner(v);
                } catch (e) {
                  hilog.warn(DOMAIN, TAG, 'enableIncomingBanner failed: %{public}s', JSON.stringify(e));
                }
              },
            });

            SettingsSwitchRow({
              label: $r('app.string.EnableAITranscriber'),
              isOn: this.enableAITranscriber,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onChange: (_v: boolean) => {
              },
            });

            // ---------------- Call Params ----------------
            SectionHeader({ title: $r('app.string.CallParamsSetting') });

            this.TextInputRow('strRoomId', this.strRoomId, InputType.Normal, (v: string) => {
              this.strRoomId = v;
              SettingsConfig.shared().strRoomId = v;
            });

            this.TextInputRow('intRoomId', this.intRoomId, InputType.Number, (v: string) => {
              this.intRoomId = v;
              const n = parseInt(v);
              SettingsConfig.shared().intRoomId = isNaN(n) ? 0 : n;
            });

            this.TextInputRowRes($r('app.string.Timeout'), this.timeoutSec, InputType.Number, (v: string) => {
              this.timeoutSec = v;
              const n = parseInt(v);
              SettingsConfig.shared().timeout = isNaN(n) ? 60 : n;
            });

            this.ExtendedInfoRow();
            this.OfflinePushRow();

            // ---------------- Video Setting (all disabled in v1) ----------------
            SectionHeader({ title: $r('app.string.VideoSetting') });

            DropMenuRow({
              label: $r('app.string.Resolution'),
              options: ['640*360', '960*540', '1280*720', '1920*1080'],
              selectedIndex: this.resolutionIdx,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onSelect: (index: number, _value: string) => {
                this.resolutionIdx = index;
                SettingsConfig.shared().resolution = index;
              },
            });

            SegmentRow({
              label: $r('app.string.ResolutionMode'),
              options: [
                getContext(this).resourceManager.getStringSync($r('app.string.Horizontal').id),
                getContext(this).resourceManager.getStringSync($r('app.string.Vertical').id),
              ],
              selectedIndex: this.resolutionModeIdx,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onSelect: (index: number) => {
                this.resolutionModeIdx = index;
                SettingsConfig.shared().resolutionMode = index;
              },
            });

            SegmentRow({
              label: $r('app.string.FillMode'),
              options: [
                getContext(this).resourceManager.getStringSync($r('app.string.Fit').id),
                getContext(this).resourceManager.getStringSync($r('app.string.Fill').id),
              ],
              selectedIndex: this.fillModeIdx,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onSelect: (index: number) => {
                this.fillModeIdx = index;
                SettingsConfig.shared().fillMode = index;
              },
            });

            SegmentRow({
              label: $r('app.string.Rotation'),
              options: ['0', '90', '180', '270'],
              selectedIndex: this.rotationIdx,
              disabled: true,
              disabledHint: $r('app.string.V1NotSupported'),
              onSelect: (index: number) => {
                this.rotationIdx = index;
                SettingsConfig.shared().rotation = index;
              },
            });

            // ---------------- Other Setting (single row, matches iOS) ----------------
            SegmentRow({
              label: $r('app.string.OtherSetting'),
              options: [
                getContext(this).resourceManager.getStringSync($r('app.string.Screen_Vertical').id),
                getContext(this).resourceManager.getStringSync($r('app.string.Screen_Horizontal').id),
                getContext(this).resourceManager.getStringSync($r('app.string.Screen_Auto').id),
              ],
              selectedIndex: this.screenOrientationIdx,
              onSelect: (index: number) => {
                this.screenOrientationIdx = index;
                SettingsConfig.shared().screenOrientation = index;
                try {
                  this.callKit?.setScreenOrientation(index);
                } catch (e) {
                  hilog.warn(DOMAIN, TAG, 'setScreenOrientation failed: %{public}s', JSON.stringify(e));
                }
              },
            });
          }
          .width('100%');
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .align(Alignment.TopStart)
        .width('100%');
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

  @Builder
  RingRow() {
    Column() {
      Row() {
        Text($r('app.string.RingSetting'))
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        Text(this.ringUrl.length > 0
          ? this.ringUrl
          : getContext(this).resourceManager.getStringSync($r('app.string.NotSet').id))
          .fontSize(16)
          .fontColor('#AAAAAA')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .margin({ left: 20 });

        Text(' > ')
          .fontSize(16)
          .fontColor('#000000')
          .margin({ left: 6 });
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .onClick(() => {
        this.navStack.pushPath({
          name: CallTestRouter.SETTING_DETAIL,
          param: new SettingDetailParam(SettingDetailType.ringInfo),
        });
      });

      Divider().color('#EEEEEE').strokeWidth(1).width('100%');
    }
    .width('100%');
  }

  @Builder
  ExtendedInfoRow() {
    Column() {
      Row() {
        Text($r('app.string.ExpendedInfo'))
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        Text(this.userData.length > 0
          ? this.userData
          : getContext(this).resourceManager.getStringSync($r('app.string.NotSet').id))
          .fontSize(16)
          .fontColor('#AAAAAA')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .margin({ left: 20 });

        Text(' > ')
          .fontSize(16)
          .fontColor('#000000')
          .margin({ left: 6 });
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .onClick(() => {
        this.navStack.pushPath({
          name: CallTestRouter.SETTING_DETAIL,
          param: new SettingDetailParam(SettingDetailType.extendInfo),
        });
      });

      Divider().color('#EEEEEE').strokeWidth(1).width('100%');
    }
    .width('100%');
  }

  @Builder
  OfflinePushRow() {
    Column() {
      Row() {
        Text($r('app.string.OfflinePushInfo'))
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        Text($r('app.string.GoToSettings'))
          .fontSize(16)
          .fontColor('#AAAAAA');

        Text(' > ')
          .fontSize(16)
          .fontColor('#000000')
          .margin({ left: 6 });
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .onClick(() => {
        this.navStack.pushPath({
          name: CallTestRouter.SETTING_DETAIL,
          param: new SettingDetailParam(SettingDetailType.offlinePushInfo),
        });
      });

      Divider().color('#EEEEEE').strokeWidth(1).width('100%');
    }
    .width('100%');
  }

  @Builder
  TextInputRow(label: string, value: string, type: InputType, onChange: (v: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        TextInput({ placeholder: label, text: value })
          .layoutWeight(1)
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#BBBBBB')
          .placeholderFont({ size: 16 })
          .backgroundColor(Color.Transparent)
          .textAlign(TextAlign.End)
          .margin({ left: 20 })
          .type(type)
          .onChange(onChange);
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White);

      Divider().color('#EEEEEE').strokeWidth(1).width('100%');
    }
    .width('100%');
  }

  @Builder
  TextInputRowRes(label: ResourceStr, value: string, type: InputType, onChange: (v: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .fontColor('#000000');

        Blank();

        TextInput({ placeholder: label, text: value })
          .layoutWeight(1)
          .fontSize(16)
          .fontColor('#333333')
          .placeholderColor('#BBBBBB')
          .placeholderFont({ size: 16 })
          .backgroundColor(Color.Transparent)
          .textAlign(TextAlign.End)
          .margin({ left: 20 })
          .type(type)
          .onChange(onChange);
      }
      .width('100%')
      .height(50)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White);

      Divider().color('#EEEEEE').strokeWidth(1).width('100%');
    }
    .width('100%');
  }
}
