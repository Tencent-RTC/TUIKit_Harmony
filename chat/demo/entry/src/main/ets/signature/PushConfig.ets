import { SDKAPPID } from './GenerateTestUserSig';

// Vendor configuration: https://cloud.tencent.com/document/product/269/108856
// Quick integration: https://cloud.tencent.com/document/product/269/108892
export class PushConfig {
  static readonly sdkAppId: number = SDKAPPID;
  static readonly appKey: string = "";
  static readonly businessID: number = 0;
}
