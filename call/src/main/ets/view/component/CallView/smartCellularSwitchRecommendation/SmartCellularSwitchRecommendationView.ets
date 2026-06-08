// Bottom-sheet popup shown when atomicxcore emits
// `DeviceEvent.onSmartCellularSwitchRecommended`.
//
// The Wi-Fi / Cellular glyphs use solid-coloured circles as placeholders
// since the call surface ships no PNG resource for them; upgrading to a
// faithful canvas rendering is a follow-up.

import { CallConstants } from '../../../../common/CallConstants';
import { TUICallKitLocalize } from '../../../../common/Localized';

@Component
export struct SmartCellularSwitchRecommendationView {
  @Link visible: boolean;
  onImprove: () => void = (): void => { };
  onKeepWifi: () => void = (): void => { };

  build() {
    if (this.visible) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(CallConstants.Color_BgMask)
          .onClick((): void => {
            this.visible = false;
          });

        Column() {
          Text(TUICallKitLocalize('TUICallKit.SmartCellular.title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(CallConstants.Color_TextPrimary)
            .margin({ top: 20 });

          Row() {
            this.iconBox(
              TUICallKitLocalize('TUICallKit.SmartCellular.wifiPoor'),
              '#FFFF584C',
            );
            Text('→')
              .fontSize(20)
              .fontColor('#999999')
              .margin({ left: 8, right: 8 });
            this.iconBox(
              TUICallKitLocalize('TUICallKit.SmartCellular.cellularGood'),
              '#FF29CC85',
            );
          }
          .margin({ top: 20 })
          .justifyContent(FlexAlign.Center);

          Text(TUICallKitLocalize('TUICallKit.SmartCellular.description'))
            .fontSize(13)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ top: 20 });

          Button(TUICallKitLocalize('TUICallKit.SmartCellular.improve'))
            .width('100%')
            .height(44)
            .backgroundColor('#006EFF')
            .fontColor(CallConstants.Color_White)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(8)
            .margin({ top: 20 })
            .onClick((): void => {
              this.onImprove();
              this.visible = false;
            });

          Button(TUICallKitLocalize('TUICallKit.SmartCellular.keepWifi'))
            .width('100%')
            .height(44)
            .backgroundColor('#F5F5F5')
            .fontColor(CallConstants.Color_TextPrimary)
            .fontSize(16)
            .borderRadius(8)
            .margin({ top: 10, bottom: 20 })
            .onClick((): void => {
              this.onKeepWifi();
              this.visible = false;
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor(CallConstants.Color_White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .position({ x: 0, y: '60%' });
      }
      .width('100%')
      .height('100%')
      .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 200 } })
      .transition({ type: TransitionType.Delete, opacity: 0, translate: { y: 200 } });
    }
  }

  @Builder
  iconBox(title: string, accentColor: string) {
    Column() {
      Circle({ width: 50, height: 50 }).fill(accentColor);
      Text(title)
        .fontSize(14)
        .fontColor(CallConstants.Color_TextPrimary)
        .margin({ top: 6 });
    }
    .width(90)
    .alignItems(HorizontalAlign.Center);
  }
}
