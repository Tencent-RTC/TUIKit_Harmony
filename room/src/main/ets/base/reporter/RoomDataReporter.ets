import { TUIRoomEngine } from '@tencentcloud/rtcroomengine';
import { RoomConstants } from '../constants/RoomConstants';

export class RoomDataReporter {
  static reportComponent(): void {
    const params: Record<string, number> = {
      'framework': RoomConstants.dataReportFramework,
      'component': RoomConstants.dataReportRoomComponent,
      'language': RoomConstants.dataReportLanguage,
    };

    const jsonObject: Record<string, Object> = {
      'api': 'setFramework',
      'params': params,
    };

    const jsonString: string = JSON.stringify(jsonObject);
    TUIRoomEngine.sharedInstance().callExperimentalAPI(jsonString);
  }
}
