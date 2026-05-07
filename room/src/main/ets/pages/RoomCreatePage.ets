import { inputMethod } from '@kit.IMEKit';
import { RadiusScheme, Toast } from '@tencentcloud/atomicx';
import { LoginStore, CreateRoomOptions } from '@tencentcloud/atomicxcore';
import { RoomColors } from '../base/resources/RoomColors';
import { RoomImages } from '../base/resources/RoomImages';
import { RoomBehavior, ConnectConfig } from './RoomMainPage';

export class EnterRoomParams {
  roomID: string = '';
  behavior: RoomBehavior = RoomBehavior.join();
  config: ConnectConfig = new ConnectConfig();

  constructor(roomID: string, behavior: RoomBehavior, config: ConnectConfig) {
    this.roomID = roomID;
    this.behavior = behavior;
    this.config = config;
  }
}

@Component
export struct RoomCreatePage {
  onBack?: () => void;
  onEnterRoom?: (params: EnterRoomParams) => void;
  @State private isAudioEnabled: boolean = true;
  @State private isSpeakerEnabled: boolean = true;
  @State private isVideoEnabled: boolean = true;
  private userName: string =
    LoginStore.shared().state.loginUserInfo?.nickname ?? LoginStore.shared().state.loginUserInfo?.userID ?? "";

  build() {
    Scroll() {
      Column() {
        this.HeaderBuilder()

        Blank()
          .height(5)

        this.UserNameCardBuilder()

        Blank()
          .height(20)

        this.FormCardBuilder()

        Blank()
          .height(48)

        this.CreateButtonBuilder()

        Blank()
          .height(32)
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .constraintSize({ minHeight: '100%' })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RoomColors.g8)
    .scrollable(ScrollDirection.Vertical)
    .align(Alignment.Top)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onClick(() => {
      inputMethod.getController().stopInputSession();
    })
  }

  @Builder
  HeaderBuilder() {
    Row() {
      Image(RoomImages.backArrow)
        .width(16)
        .height(16)

      Blank()
        .width(12)

      Text($r('app.string.roomkit_create_room'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(RoomColors.g2)
    }
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .onClick(() => {
      this.onBack?.();
    })
  }

  @Builder
  UserNameCardBuilder() {
    Row() {
      Text($r('app.string.roomkit_your_name'))
        .fontSize(16)
        .fontColor(RoomColors.g3)
        .width(88)

      Text(this.userName)
        .fontSize(16)
        .fontColor(RoomColors.g2)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 17,
      bottom: 17
    })
    .backgroundColor(RoomColors.cardBackground)
    .borderRadius(RadiusScheme.largeRadius)
  }

  @Builder
  FormCardBuilder() {
    Column() {
      this.SwitchItemBuilder({
        label: $r('app.string.roomkit_enable_audio'),
        isOn: this.isAudioEnabled,
        onChanged: (value: boolean) => {
          this.isAudioEnabled = value;
        },
      })

      Row()
        .width('100%')
        .height(1)
        .backgroundColor(RoomColors.g8)
        .margin({ left: 16, right: 16 })

      this.SwitchItemBuilder({
        label: $r('app.string.roomkit_enable_speaker'),
        isOn: this.isSpeakerEnabled,
        onChanged: (value: boolean) => {
          this.isSpeakerEnabled = value;
        },
      })

      Row()
        .width('100%')
        .height(1)
        .backgroundColor(RoomColors.g8)
        .margin({ left: 16, right: 16 })

      this.SwitchItemBuilder({
        label: $r('app.string.roomkit_enable_video'),
        isOn: this.isVideoEnabled,
        onChanged: (value: boolean) => {
          this.isVideoEnabled = value;
        },
      })
    }
    .width('100%')
    .backgroundColor(RoomColors.cardBackground)
    .borderRadius(RadiusScheme.largeRadius)
  }

  @Builder
  SwitchItemBuilder($$: SwitchItemParams) {
    Row() {
      Text($$.label)
        .fontSize(16)
        .fontColor(RoomColors.g3)

      Blank()
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: $$.isOn })
        .selectedColor(RoomColors.b1)
        .switchStyle({ unselectedColor: RoomColors.g7 })
        .height(24)
        .width(42)
        .onChange((isOn: boolean) => {
          $$.onChanged(isOn);
        })
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 15,
      bottom: 15
    })
  }

  @Builder
  CreateButtonBuilder() {
    Row() {
      Text($r('app.string.roomkit_create_room'))
        .fontSize(16)
        .fontWeight(600)
        .fontColor(Color.White)
    }
    .width(200)
    .height(52)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(RoomColors.brandBlue)
    .borderRadius(RadiusScheme.alertRadius)
    .margin({ left: 'auto', right: 'auto' })
    .alignSelf(ItemAlign.Center)
    .onClick(() => {
      this.handleCreateRoomButtonTapped();
    })
  }

  private handleCreateRoomButtonTapped(): void {
    const roomID = this.generateRoomID();
    const loginUser = LoginStore.shared().state.loginUserInfo;
    const userName = loginUser?.nickname ?? loginUser?.userID ?? roomID;
    const uiContext = this.getUIContext();
    let roomName = '';
    try {
      roomName = uiContext.getHostContext()?.resourceManager.getStringByNameSync('roomkit_user_room')
        ?.replace('xxx', userName) ?? `${userName}'s room`;
    } catch (_e) {
      roomName = `${userName}'s room`;
    }
    const options = new CreateRoomOptions();
    options.roomName = roomName;
    const behavior = RoomBehavior.create(options);
    const config = new ConnectConfig(this.isAudioEnabled, this.isVideoEnabled, this.isSpeakerEnabled);
    this.onEnterRoom?.(new EnterRoomParams(roomID, behavior, config));
  }

  private generateRoomID(): string {
    const min = 100000;
    const max = 999999;
    const randomNumber = Math.floor(Math.random() * (max - min + 1)) + min;
    return randomNumber.toString();
  }
}

interface SwitchItemParams {
  label: Resource;
  isOn: boolean;
  onChanged: (value: boolean) => void;
}
