import { RoomConstants } from '../../base/constants/RoomConstants';
import { StandardRoomView } from './room_view/StandardRoomView';
import { WebinarRoomView } from './room_view/WebinarRoomView';

@Component
export struct RoomView {
  roomId: string = '';

  build() {
    if (this.roomId.startsWith(RoomConstants.webinarPrefix)) {
      WebinarRoomView({ roomId: this.roomId })
    } else {
      StandardRoomView({ roomId: this.roomId })
    }
  }
}
