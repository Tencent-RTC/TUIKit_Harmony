import {
  RoomHomePage,
  RoomCreatePage,
  RoomJoinPage,
  RoomMainPage,
  EnterRoomParams,
  RoomBehavior,
  ConnectConfig,
} from '@tencentcloud/tuiroomkit';

@Component
export struct RoomHomeDestination {
  navStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      RoomHomePage({
        onBack: () => {
          this.navStack.pop();
        },
        onCreateRoomClicked: () => {
          this.navStack.pushPath({ name: 'CreateRoom' });
        },
        onJoinRoomClicked: () => {
          this.navStack.pushPath({ name: 'JoinRoom' });
        },
      })
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}

@Component
export struct CreateRoomDestination {
  navStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      RoomCreatePage({
        onBack: () => {
          this.navStack.pop();
        },
        onEnterRoom: (params: EnterRoomParams) => {
          this.navStack.pushPath({ name: 'RoomMain', param: params });
        },
      })
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}

@Component
export struct JoinRoomDestination {
  navStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      RoomJoinPage({
        onBack: () => {
          this.navStack.pop();
        },
        onEnterRoom: (params: EnterRoomParams) => {
          this.navStack.pushPath({ name: 'RoomMain', param: params });
        },
      })
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}

@Component
export struct RoomMainDestination {
  navStack: NavPathStack = new NavPathStack();
  params?: EnterRoomParams;

  build() {
    NavDestination() {
      RoomMainPage({
        roomID: this.params?.roomID ?? '',
        behavior: this.params?.behavior ?? RoomBehavior.join(),
        config: this.params?.config ?? new ConnectConfig(),
        onExit: () => {
          this.navStack.pop();
        },
      })
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .onBackPressed(() => {
      return true;
    })
  }
}
