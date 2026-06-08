// JoinGroupCallPage.ets — aligned with iOS JoinGroupCallViewController.swift.
//
// is1VN = true  : only CallID input + Call button (uses TUICallKit.join(callId))
// is1VN = false : GroupId input + RoomId input + RoomId int/string DropMenu +
//                 MediaType radios + Call button (uses TUICallKit.join(roomId))

import { hilog } from '@kit.PerformanceAnalysisKit';
import { inputMethod } from '@kit.IMEKit';
import { TUICallKit } from '@tencentcloud/tuicallkit';
import { CallMediaType } from '@tencentcloud/atomicxcore';
import { Toast } from '../../common/Toast';
import { SettingsConfig } from '../../common/SettingsConfig';
import { RadioButton } from '../../components/RadioButton';
import { PrimaryButton } from '../../components/PrimaryButton';

const DOMAIN = 0xCA11;
const TAG = 'CallTest';

@Component
export struct JoinGroupCallDestination {
  navStack: NavPathStack = new NavPathStack();

  @State is1VN: boolean = SettingsConfig.shared().is1VN;
  @State groupId: string = '';
  @State roomId: string = '';
  /** 0 = Int RoomId, 1 = String RoomId */
  @State roomTypeIndex: number = 0;
  @State callType: CallMediaType = CallMediaType.audio;
  private callKit: TUICallKit | null = null;

  aboutToAppear(): void {
    this.callKit = TUICallKit.createInstance(getContext(this));
  }

  private getRoomTypeOptions(): string[] {
    return [
      getContext(this).resourceManager.getStringSync($r('app.string.RoomIdInt').id),
      getContext(this).resourceManager.getStringSync($r('app.string.RoomIdString').id),
    ];
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
          Text($r('app.string.JoinGroupCall'))
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

        // GroupId / CallId row
        Row() {
          Text(this.is1VN ? $r('app.string.CallIdLabel') : $r('app.string.GroupId'))
            .fontSize(16)
            .fontColor('#000000')
            .width(80);
          TextInput({
            placeholder: this.is1VN ? $r('app.string.InputCallId') : $r('app.string.InputGroupId'),
            text: this.groupId,
          })
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

        if (!this.is1VN) {
          // RoomId row: int/string drop menu on the left + RoomId TextField on the right.
          // Aligned with iOS where roomIdLabel acts as the left dropdown trigger
          // and roomIdTextField sits on the right of the same row.
          Row() {
            Select(this.getRoomTypeOptions().map((o) => {
              return { value: o } as SelectOption;
            }))
              .selected(this.roomTypeIndex)
              .value(this.getRoomTypeOptions()[this.roomTypeIndex])
              .font({ size: 16 })
              .fontColor('#000000')
              .selectedOptionFont({ size: 16 })
              .optionFont({ size: 16 })
              .backgroundColor(Color.Transparent)
              .onSelect((index: number, _value: string) => {
                this.roomTypeIndex = index;
              });

            TextInput({ placeholder: $r('app.string.InputRoomId'), text: this.roomId })
              .layoutWeight(1)
              .fontSize(16)
              .fontColor('#333333')
              .placeholderColor('#BBBBBB')
              .placeholderFont({ size: 16 })
              .backgroundColor(Color.Transparent)
              .textAlign(TextAlign.End)
              .type(this.roomTypeIndex === 0 ? InputType.Number : InputType.Normal)
              .onChange((v: string) => {
                this.roomId = v;
              });
          }
          .width('100%')
          .height(50)
          .padding({ left: 20, right: 20 })
          .backgroundColor(Color.White)
          .alignItems(VerticalAlign.Center);

          // line2
          Divider().color('#EEEEEE').strokeWidth(10);

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
        }

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
      .onClick(() => {
        inputMethod.getController().stopInputSession();
      });
    }
    .hideTitleBar(true);
  }

  private async handleCall(): Promise<void> {
    const gid = this.groupId.trim();
    const rid = this.roomId.trim();

    if (this.is1VN) {
      if (gid.length === 0) {
        return;
      }
      try {
        await this.callKit?.join(gid);
        hilog.info(DOMAIN, TAG, '[JoinGroup] join(callId=%{public}s) ok', gid);
      } catch (err) {
        hilog.error(DOMAIN, TAG, '[JoinGroup] join failed: %{public}s', JSON.stringify(err));
        Toast.show(`${getContext(this).resourceManager.getStringSync($r('app.string.CallFailed').id)}: ${JSON.stringify(err)}`);
      }
    } else {
      if (rid.length === 0 || gid.length === 0) {
        return;
      }
      try {
        await this.callKit?.join(rid);
        hilog.info(DOMAIN, TAG, '[JoinGroup] join(roomId=%{public}s) ok', rid);
      } catch (err) {
        hilog.error(DOMAIN, TAG, '[JoinGroup] join failed: %{public}s', JSON.stringify(err));
        Toast.show(`${getContext(this).resourceManager.getStringSync($r('app.string.CallFailed').id)}: ${JSON.stringify(err)}`);
      }
    }
  }
}
