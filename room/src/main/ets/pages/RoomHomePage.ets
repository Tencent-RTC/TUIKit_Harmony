import { Avatar, AvatarContentType, AvatarSize, RadiusScheme } from '@tencentcloud/atomicx';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { RoomColors } from '../base/resources/RoomColors';
import { RoomImages } from '../base/resources/RoomImages';

interface ActionButtonParams {
  title: Resource;
  icon: Resource;
  onTap: () => void;
}

@Component
export struct RoomHomePage {
  onBack?: () => void;
  onCreateRoomClicked?: () => void;
  onJoinRoomClicked?: () => void;
  private userName: string = LoginStore.shared().state.loginUserInfo?.nickname ?? '';
  private userAvatar: string = LoginStore.shared().state.loginUserInfo?.avatarURL ?? '';

  build() {
    Column() {
      this.HeaderBuilder()
      Blank()
        .layoutWeight(1)
      this.ActionButtonsBuilder()
      Blank()
        .height(154)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RoomColors.background)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  HeaderBuilder() {
    Row() {
      Image(RoomImages.backArrow)
        .width(22)
        .height(22)
        .onClick(() => {
          this.onBack?.();
        })

      Blank()
        .width(22)

      this.UserInfoBuilder()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  UserInfoBuilder() {
    Row() {
      Avatar({
        content: {
          type: AvatarContentType.Image,
          url: this.userAvatar,
        },
        avatarSize: AvatarSize.M,
      })

      Blank()
        .width(12)

      Text(this.userName)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF676C80')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 200 })
    }
  }

  @Builder
  ActionButtonsBuilder() {
    Column({ space: 24 }) {
      this.ActionButtonBuilder({
        title: $r('app.string.roomkit_join_room'),
        icon: RoomImages.joinRoom,
        onTap: () => {
          this.onJoinRoomClicked?.();
        },
      })

      this.ActionButtonBuilder({
        title: $r('app.string.roomkit_create_room'),
        icon: RoomImages.createRoom,
        onTap: () => {
          this.onCreateRoomClicked?.();
        },
      })
    }
    .padding({ left: 56, right: 56 })
  }

  @Builder
  ActionButtonBuilder($$: ActionButtonParams) {
    Row() {
      Image($$.icon)
        .width(20)
        .height(20)
        .fillColor(Color.White)

      Blank()
        .width(8)

      Text($$.title)
        .fontSize(16)
        .fontWeight(600)
        .fontColor(Color.White)
    }
    .width('100%')
    .height(54)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(RoomColors.brandBlue)
    .borderRadius(RadiusScheme.smallRadius)
    .onClick(() => {
      $$.onTap();
    })
  }
}
