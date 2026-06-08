export enum CallOrientation {
  portrait = 0,
  landscapeLeft = 1,
  landscapeRight = 2,
}

@Observed
export class GlobalStateClass {
  enableMuteMode: boolean = false;
  enableFloatWindow: boolean = true;
  enableIncomingBanner: boolean = false;
  /** v1 TODO: virtual background out of scope. */
  enableVirtualBackground: boolean = false;
  /** v1 TODO: atomicxcore for HarmonyOS does not yet expose enableMultiDeviceAbility. */
  enableMultiDeviceAbility: boolean = false;
  orientation: CallOrientation = CallOrientation.portrait;
}

let _instance: GlobalStateClass | null = null;

export function GlobalState(): GlobalStateClass {
  if (!_instance) {
    _instance = new GlobalStateClass();
  }
  return _instance;
}
